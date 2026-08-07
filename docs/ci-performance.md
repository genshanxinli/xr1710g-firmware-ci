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

1. **缓存压线淘汰**：9.1GB/10GB → `scripts/prune-caches.sh` 按前缀保留策略
   （ccache/toolchain 各 3 条、dl/feeds 各 2 条），在 build.yml /
   validate-patches.yml 每次运行末尾执行。48h 内被访问过的条目受保护不删
   （防跨分支误删，见下）。
2. **ccache 从不重存/越用越旧**：key 改为
   `ccache-fanboy-<base-SHA>-<ci-content-hash>`（`scripts/ci-content-hash.sh`），
   内容变化即新 key 并重存，前缀回退复用旧内容族。
3. **feeds 无条件网络更新**：feeds 缓存精确命中时跳过 `feeds update -a`
   （`feeds install -a` 恒执行，软链不在缓存内）。
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
- prune 的 48h 访问保护即为此设计：跨分支误删活跃条目会打爆别的分支的暖态。

## 实测记录（优化后，按时间倒序）

| 日期 | Run ID | 类型 | 总时长 | toolchain 构建 | preflight | ccache | 备注 |
|---|---|---|---|---|---|---|---|
| 2026-08-07 | 31206015949 | validate-patches 暖态（PR ref） | **5m28s** | SKIPPED（exact hit） | 1m51s | exact hit | 缓存闭环验证 ✓ |
| 2026-08-07 | 31197841648 | validate-patches 冷态（PR ref） | 49m13s | 40m14s 重建 | 2m05s | 旧条目回退 | LRU 淘汰旧伤的残余一次性成本 |
| 2026-08-07 | 31154480540 | 全量构建（基线） | 58m31s | cache hit | — | 49.3% | 基线（优化前） |

回填方法：run 成功后下载 `ci-metrics` artifact，取其 `post-build` 段落：
ccache 命中率 = `Hits / Cacheable calls`，缓存占用 = GitHub repo Settings →
Actions → Caches 页总计。注：PR ref 与分支 ref 的缓存互相不可见（见上节），
暖态时长仅在同一 ref 内可比；全量构建在 main 上 dispatch 后回填首行。
