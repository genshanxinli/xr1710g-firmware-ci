# 阶段 2 提案：内核 build_dir 缓存（增量构建）

> 状态：**提案，待批准实施** | 日期：2026-08-08
> 前置：阶段 1（缓存治理 + ccache 内容哈希）已合并（PR #18, 5a89ea7），全量构建 58.5min → 39m16s，ccache 命中率 49.3% → 86.7%。
> 本文档是阶段 2 的设计决策记录：收益、风险、设计规则、残余风险补救、监测、playbook、实施门。

---

## 1. 收益（有实测支撑）

### 1.1 现状病根（阶段 1 暴露）
warm 构建 ccache 命中率 86.7%，但固件编译仅 39m→34m（-12%）——大头是**非编译开销**：
~300 个包的 configure/stage/install/打包步骤不经过 ccache。build_dir 缓存可同时跳过编译与非编译步骤。

### 1.2 预期收益
| 场景 | 现在 | 有缓存后 | 依据 |
|---|---|---|---|
| main 全量构建（内容不变） | 39m16s | ~12-15min | 34m 中编译仅 ~5m（87% 命中），其余为非编译步骤 |
| PR 校验（改 1 个包） | 5m28s | ~2-3min | 只重建变化包 |
| PR 校验（改 kernel 补丁） | 5m28s | ~5-8min | kernel 冷 + 依赖链，仍远好于旧冷态 |
| kernel 补丁迭代（日常主场景） | 每轮 39m | 只重编 kernel 相关 | kernel 子通道 |

### 1.3 确定性实证（2026-08-08 实验）
同提交（5a89ea7）、ccache 命中率 13% vs 87% 的两次构建，FIT 子镜像逐字节对比：
- **kernel-1：5,722,233 字节 IDENTICAL**
- **fdt-1：23,347 字节 IDENTICAL**
- **rootfs-1：DIFFERENT**（首差异 +34，squashfs superblock root_inode 字段 → **inode 布局/文件顺序差异**，非文件内容差异；并行 make 的包安装顺序竞争）

结论：**编译链完全确定**（同输入 → 同二进制），支撑"内容哈希 = 输入指纹"的核心假设；
rootfs 打包顺序非确定 → 不能直接字节对比，需解包逐文件对比（见层 B 指纹 + 发布门）。

---

## 2. 风险（按级别）

| ID | 级别 | 机制 |
|---|---|---|
| R1 | 高 | **陈旧对象**：stamp 说已构建但源变了 → 跳过重编 → 旧 .o 进固件。触发：同版本号重发布 tarball；stamp 与产物错位；kmod vs kernel Module.symvers 耦合 |
| R2 | 高 | **restore-keys 回退链对 build_dir 不安全**：ccache 内容寻址回退无害；build_dir 回退 = 直接用陈旧树。**必须 exact-key only** |
| R3 | 中 | 缓存恢复截断/损坏（tar 流网络抖动）→ 树不完整 → make 行为不可预测 |
| R4 | 中 | 10GB 预算硬约束：build_dir/target 未压缩 ~10GB+，压缩率未实测（估 2-4GB/条目）；与 toolchain/dl/ccache 争预算 |
| R5 | 低 | 磁盘：恢复后解压 10GB+ 树（实测空闲 68G，无虞；前提 ccache 4G 上限不动） |
| R6 | 低 | `make -k` + 增量语义：失败包下次仍被跳过 → 修复补丁后不重编（需要失败标记防护） |

---

## 3. 设计规则（防 R1-R6）

### 规则 1：exact-key only，禁止回退（杀 R1+R2 主路径）
```
key: tb-<base>-<kernel_hash>   # kernel objtree（build_dir/target-*/linux-*）
key: tp-<base>-<full_hash>     # 包目录 + staging_dir/target + stamps
restore-keys: 无               # hash 变 = 全冷（34m 地板，零回归）
```
安全原理：hash 覆盖全部补丁/配置/锁 → hash 变 = 内容变 = 冷构建（正确）；
hash 不变 = 内容绝对没变 = 增量安全。中间态不存在。

### 规则 2：kernel 子通道 + 保守分类（防 R1 的 kmod 耦合）
kernel-affecting（patches/upstream-backports/kernel、target/linux、config-6.18、DTS）单独哈希。
决策矩阵：
| 变更类型 | kernel 条目 | 包条目 | 效果 |
|---|---|---|---|
| 无变更 | ✓ 恢复 | ✓ 恢复 | ~12-15min |
| 包-only | ✓ 恢复 | ✗ 冷 | 只重编包（ccache 顶着，~20min） |
| kernel 变更 | ✗ 冷 | ✗ 冷（kmod 依赖 Module.symvers，连带） | 34m 地板 |

**kernel 变 → 包也冷是强制规则**（kmod 编译依赖 kernel 符号表）。
kernel_hash 分类原则：**宁可过度失效**（把包文件误归 kernel → 浪费但安全），
禁止欠失效（kernel 文件漏归 → 补丁的 kernel 效果从固件静默消失）。

### 规则 3：标记文件自检（防 R3）
- save 前：写入 `build_dir/target-*/.ci-kernel-hash`、`.ci-full-hash`
- restore 后：校验 == 当前 hash；不匹配/缺失 → wipe 整个 build_dir/target + staging_dir/target + 醒目警告
- 存在性校验：`linux-*/.config`、`Module.symvers`、stamp 目录

### 规则 4：预算治理（防 R4）
- **先实测压缩率**（第 7 节步骤 1），再定条目组合
- prune：kernel/包条目各留 1（hash 变后旧树本就无用，**与 ccache 不同，不需要两代**）
- 目标账：toolchain 1×1.2 + dl 1.4 + ccache 2×0.6 + feeds 0.05 + kernel ~2.5 + pkg ~2.5 ≈ 8.8GB

### 规则 5：回滚开关（心理安全）
workflow env `USE_BUILD_DIR_CACHE: "false"` → 一键回到阶段 1 状态（34m 地板），缓存条目闲置。
**阶段 2 任何时刻可无痛撤销。**

### 规则 6：stamp 语义防护（防 R6）
save 前清理失败痕迹（`.build_failed` 类标记）；构建失败 → 不保存（`success()` 门控已有）。

---

## 4. 残余风险与补救

### 4.0 框架修正（重要）
严格 exact-key 设计下，"同 hash 内 stamp 必然有效"成立：**hash 没变 ⟹ 输入没变 ⟹
缓存树是相同输入的成功构建快照 ⟹ stamp 与产物一致**。所谓"包级陈旧对象静默区"
（早期分析中的残余 1）不是独立风险——它是 **hash 盲区（输入变了 hash 没变）** 和
**分类错误** 的症状。完整论证链：

> **A（输入全覆盖哈希化）** 保证"输入确实没变"
> + **B（恢复后产物指纹校验）** 保证"恢复的树 == 保存的树"
> + 保存时是一次成功构建
> ⟹ **产物是这些输入的正确产物**

### 4.1 层 A：输入哈希化（治本，堵盲区）
| 洞 | 补救 | 成本 |
|---|---|---|
| dl/ 上游 tarball 重发布（版本号未变内容变） | **dl 内容哈希进 build_dir key**：`find dl -type f \| sort \| xargs sha256sum \| sha256sum` | ~30s/run |
| luci-theme-glass tag force-push | clone 后记录 HEAD 进 ci-content-hash 输入 | ~0 |
| apt 依赖清单变化（toolchain key 只含 base SHA） | apt 包列表哈希进 toolchain key | ~0 |

feeds 天然安全：包版本 = git commit hash，变了目录名就变 → 必重编。

### 4.2 层 B：恢复后产物指纹校验（治标，防 R3 + 发布门工具）
- save 前（缓存路径内）：`find build_dir/target-* -type f \( -name '*.o' -o -name '*.ko' -o -name '*.so*' -o -name '*.a' \) -print0 | sort -z | xargs -0 sha256sum > .ci-artifacts.sha256`
- restore 后：重算比对 → 任何差异 → wipe build_dir/target + staging_dir/target → 冷构建
- 只哈希编译产物（~2 万文件 vs 全树 ~20 万）→ ~1-2min/run，相对 34m 可忽略
- 指纹文件随缓存条目走，零额外传输
- **同一指纹是发布门 A/B 对比的现成工具**

### 4.3 层 C：观测兜底（把漏洞变成可见信号）
| 信号 | 规则 | 成本 |
|---|---|---|
| C1 canary | **kernel 字节与上次构建相同 + full_hash 变了 = 报警**（kernel 应该变却没变 = 分类欠失效） | ~0 |
| C2 时长启发式 | full_hash 变（预期冷）但编译 < 预期 1/3 = 报警"疑似过度跳过" | ~0 |
| C3 ccache 命中率 | hash 不变时 <70% = 报警（意外重编先兆） | 已有 |
| C7 发布门 | 打 tag 前自动冷构建 + 指纹对比 + 上机冒烟 | 每次发布 +39m |

C7 是**唯一不依赖 hash 正确性的独立验证**——发布时关闭全部残余。

### 4.4 层 D：结构性保守化（消除分类风险）
- D-a：**放弃子通道，统一 full_hash key**——分类错误整类消失；代价：包-only 变更也重编 kernel
- D-b：**只做 kernel 条目、不做包条目**——包每次全量重编（ccache 顶着），包侧盲区不存在；
  收益约减半，但 kernel 有字节 canary 兜底
- D-c：子通道保留 + kernel_hash 保守定义（白名单文件清单 + review 检查）

### 4.5 成本汇总
| 项 | 成本 | 关闭 |
|---|---|---|
| A1 dl 哈希进 key | ~30s/run | 重发布盲区 |
| A2 glass HEAD | ~0 | force-push 盲区 |
| A3 apt 清单 | ~0 | 环境盲区 |
| B5 指纹校验 | ~2-4min/run | 传输完整性 + 发布门工具 |
| C1/C2 canary | ~0 | 分类欠失效 + 统计哨兵 |
| C7 发布门 | 发布时 +39m | 全部残余的独立兜底 |
| D 保守化 | 收益打折 | 分类风险整类 |

**推荐组合**：A1+A2+A3 + B5 + C1/C2 + 发布门；子通道先做 **D-b（kernel-only）**，
上机验证后视命中率再决定是否加包条目。

### 4.6 唯一前提（缓存技术无法消除）
保存时的那次构建本身必须正确——由 CI 编译验证 + 上机冒烟保证。
**缓存验证证明的是"确定性"（缓存产物 == 冷构建产物），不是"正确性"（源码是对的）。**

---

## 5. 监测体系汇总

| 信号 | 阈值 | 含义 |
|---|---|---|
| kernel/fdt 字节对比 | 与上次构建不同 → 必须有 hash 变化解释 | 增量构建 kernel 产物漂移 = R1 先兆 |
| C1 canary | kernel 字节不变 + full_hash 变 → 报警 | 分类欠失效 |
| ccache 命中率 | hash 不变时 >85%；<70% 报警 | 意外重编先兆 |
| 时长 | hash 不变 >25min 或 <8min 报警 | 意外重编 / 过度跳过 |
| 标记文件自检 | 失败 → workflow 红 + 明确信息 | R3 截断/意外 |
| 指纹校验 | 不匹配 → wipe + 报警 | 恢复完整性 |
| A/B 对比构建 | 发布前自动：冷 vs 缓存，指纹 + 解包对比 | 全量正确性（发布门） |
| 上机冒烟 | 固件内嵌构建来源标记（`.ci-build-cache: yes`），pi-agent 18 角度全绿 | 行为一致性（终极） |
| ci-metrics artifact | 每次自动采集上述所有 | 审计链 |

## 6. 解决路径（playbook）

1. **怀疑缓存污染** → 删条目（`gh api -X DELETE .../actions/caches/<id>`）→ 重跑
   → 复现 = 真 bug（正常流程）；消失 = 缓存问题 → **记录 hash 到 incident log**（docs/ci-performance.md 新章节）
2. **上机 kernel 符号问题**（dmesg "Unknown symbol"）→ 删 kernel 条目重编 → 复测 → 记录
3. **回滚**：`USE_BUILD_DIR_CACHE=false` → 阶段 1 状态（34m 地板）
4. **最坏失败模型**：回到阶段 1，不是比阶段 1 更差（ccache 层永远在，exact-key 保证任何 hash 变化走冷路径）

## 7. 实施步骤（每步有验证门）

1. **压缩率实测**：1 次手动构建，save 后查条目大小 → 定预算组合；不行就砍（只做 kernel 条目）
2. **kernel 条目先行**（build.yml only）：跑 2-3 轮内容不变场景，验证：时长 39m→?、
   kernel 字节对比一致、ccache 命中率稳定、指纹校验通过
3. **上机验证**：缓存产物过 pi-agent 冒烟（对照基线固件）
4. **包条目**（若第 2 步数据支持 + 用户批准）：同上流程
5. **validate-patches 接入**（kernel+包都稳后）
6. **可选 2.5**：`SOURCE_DATE_EPOCH` 固定 → rootfs 字节级可验证 → A/B 升级为全镜像对比
7. **fire drill**：故意破坏一条缓存验证报警链路（canary/指纹）确实会响

## 8. 决策点（待拍板）

| ID | 决策 | 选项 |
|---|---|---|
| D1 | 子通道 vs 统一 key | 子通道（收益大，需分类纪律）/ 统一 key（零分类风险，收益打折） |
| D2 | 包条目 | kernel-only 先行（推荐）/ kernel+包一起 |
| D3 | 发布门自动化 | 打 tag 自动触发（推荐）/ 手动 |
| D4 | 阶段 2.5（SOURCE_DATE_EPOCH） | 纳入 / 后续再说 |

## 9. 附录：验证实验记录

2026-08-08：main 种子构建（31215345340）vs warm 构建（31221627661），同提交 5a89ea7。
FIT 子镜像字节对比（最小 FDT 解析器）：kernel-1 IDENTICAL（5,722,233B）、
fdt-1 IDENTICAL（23,347B）、rootfs-1 DIFFERENT（16,252,928B，首差异 +34 =
squashfs superblock root_inode 字段，inode 布局/文件顺序差异）。
sha256：sysupgrade.itb 两构建均 22,008,709B 但哈希不同（rootfs 顺序所致）。
