# CI Performance Baseline & Metrics

度量档案：记录 CI 构建性能的基线、优化目标和每次构建后的实测指标。
每次全量构建后，从 `ci-metrics` artifact（或 run 的步骤摘要）读取数据回填下表。

## 基线（优化前，2026-08-07 实测）

| 指标 | 基线 | 目标（阶段 1） | 达成 |
|---|---|---|---|
| 全量构建总时长（run 31154480540） | 58m31s | ≤35min | |
| 其中固件编译（91%） | 53m18s | — | |
| ccache 命中率（build.log 实测） | 49.3%（20802/42162） | ≥80% | |
| toolchain 冷构建（缓存 miss） | 18m30s | 仅 base bump 时一次性 | |
| validate-patches 暖态 | 4m54s | 稳定 ≤6min | |
| validate-patches 冷态/异常 | 24-38min（缓存淘汰导致） | 不再出现 | |
| sync-upstream overlay 刷新构建 | 18min 无缓存 | ≤3min（缓存命中） | |
| GitHub 缓存占用 | 9.1GB / 10GB（89%，LRU 互相淘汰） | ~5GB 稳定 | |
| 当前分支 ccache 条目 | 不存在（被 LRU 淘汰） | 恒存在 | |

## 根因与对策（对应提交）

1. **缓存压线淘汰**：9.1GB/10GB → `scripts/prune-caches.sh` 只处理「当前 ref + 默认分支」作用域的条目
   （ccache/toolchain 各 3 条、dl/feeds 各 2 条），其他分支条目留给 GitHub 7 天不活跃 GC；
   48h 内访问过的条目受保护不删。在 build.yml / validate-patches.yml 每次运行末尾执行。
2. **ccache 从不重存/越用越旧**：key 改为
   `ccache-fanboy-<base-SHA>-<ci-content-hash>`（`scripts/ci-content-hash.sh`），
   内容变化即新 key 并重存，前缀回退复用旧内容族。
3. **feeds 无条件网络更新**：feeds key 带日期后缀（`feeds-fanboy-<base>-<YYYYMMDD>`），
   同日精确命中跳过 `feeds update -a`，次日必刷新重存（快照新鲜度 ≤24h）；
   `feeds install -a` 恒执行（软链不在缓存内）。
4. **sync-upstream 无缓存重建 toolchain**：sync-upstream.yml 恢复 dl/toolchain
   缓存到固定树路径，`validate-overlay.sh --toolchain-cached` 精确命中时跳过构建。
5. **ccache 6G 爆盘风险**（standard runner 磁盘 ~14G）：降为 4G，ci-metrics 采集 df。
6. **度量体系**：`scripts/ci-metrics.sh` 构建前后采集 ccache 统计/磁盘/目录大小，
   输出 `ci-metrics` artifact。

## 已知机制（GitHub Actions 缓存分支作用域）

**缓存按创建它的 ref 隔离**：run 只能 restore「自己分支创建的 + 默认分支（main）创建的」缓存；
分支之间不互通。实测验证：PR run（ref=`refs/pull/18/merge`）保存的 dl/toolchain
条目，分支上的 workflow_dispatch run 读不到（触发两次独立 toolchain 重建）。
推论与实践：
- **全量构建请在 main 上 dispatch**（或至少固定在一个稳定分支）——main scope 创建的缓存
  全分支共享，是缓存效率的关键。
- PR 校验 run 的保存只服务同一 PR 的后续 push，属合理开销。
- prune 只处理当前 ref + main 作用域条目（API 的 `ref` 字段过滤），不跨分支误删。

**缓存版本 = 解析后绝对路径的哈希**：actions/cache 的 entry version 由路径列表决定，
restore 时 key 与 version 必须同时匹配。因此 sync-upstream 的树必须在
`$GITHUB_WORKSPACE/openwrt`（与 build.yml 的 BUILD_DIR 相对路径一致），
放 `$RUNNER_TEMP` 下会永远 miss（实测修复前 sync 缓存恢复全部 0 秒未命中）。

## 实测记录（优化后，按时间倒序）

| 日期 | Run ID | 类型 | 总时长 | toolchain 构建 | 固件编译 | ccache 命中 | 备注 |
|---|---|---|---|---|---|---|---|
| 2026-08-08 | 31260842118 | 阶段2 warm（ci/phase2-builddir-cache） | 21m18s | SKIPPED | 14m55s | 83%（本轮） | tb/tp 恢复+validate 绿，但 STAMP_PREPARED 名含 mtime（find_md5 %T@）→ 258 包 prepare 全重跑；触发 freeze-source-mtimes 修复（35709cd） |
| 2026-08-08 | 31258008443 | 阶段2 warm v2（诊断失败） | — | SKIPPED | 34m15s | 86% | 根因①preflight prepare 破坏恢复树（rm -rf PKG_BUILD_DIR）；根因②host 树 mtime 陈旧 tools 重编 |
| 2026-08-08 | 31254657180 | 阶段2 种子 v4 | 43m36s | SKIPPED | 36m58s | 种子冷 | tb 1.7GB / tp 2.3GB 带 .ci-meta 标记条目落位；kernel sha 基线 a40b3e5c |
| 2026-08-07 | 31221627661 | 全量构建（main，warm） | **39m16s** | SKIPPED（exact hit） | 34m25s | **86.7%**（本轮新增调用；累计 47.1% 被种子冷跑稀释） | ✅ 阶段 1 目标达成（≤35min 差 4min，非编译开销占大头） |
| 2026-08-07 | 31215345340 | 全量构建（main，种子冷启动） | 1h30m35s | 40m47s 冷 | 39m04s | 11.2%（累计） | main scope 缓存已就位；磁盘 54% 无压力 |
| 2026-08-07 | 31206015949 | validate-patches 暖态（PR ref） | **5m28s** | SKIPPED（exact hit） | — | exact hit | 缓存闭环验证 ✓ |
| 2026-08-07 | 31197841648 | validate-patches 冷态（PR ref） | 49m13s | 40m14s 重建 | — | 旧条目回退 | LRU 淘汰旧伤的残余一次性成本 |
| 2026-08-07 | 31154480540 | 全量构建（基线） | 58m31s | cache hit | 53m18s | 49.3% | 基线（优化前） |

**关键发现（阶段 2 依据）**：warm run 命中率 13%→87% 只让编译从 39m→34m（-12%）——
非编译开销（~300 包 configure/stage/install/打包，不经 ccache）占大头；
缓存 `build_dir/target-*` 可同时跳过两者，34m 预计可压至 ~15m（阶段 2，待批准）。

回填方法：run 成功后下载 `ci-metrics` artifact，取其 `post-build` 段落：
ccache 命中率 = `Hits / Cacheable calls`，缓存占用 = GitHub repo Settings →
Actions → Caches 页总计。注：PR ref 与分支 ref 的缓存互相不可见（见上节），
暖态时长仅在同一 ref 内可比；全量构建在 main 上 dispatch 后回填首行。
