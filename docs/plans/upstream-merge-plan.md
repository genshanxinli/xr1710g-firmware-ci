
## 2026-08-07 合并执行记录（PR #15 ci/merge-upstream-fixes）

- 6eb750c 剔除实验 PPE 系列（930/990-04/05/999-90..93/mt76 0013-14，remove_conflicting_patch ×9）
- 77dbb93 追踪切换（fanboy → ubi2-oc-auto 只报告；monitor + #24593 + auto SHA）
- 70efd9a mt76 0015 backport（root fix，21 补丁序列预演全绿）
- 612121d / 6db74db 报告刷新 + ENFILE 断言
- 1e857da2 9999-25/9999-38 重基（剔除后 9 hunk 依赖修复；7 上下文重写 + 1 删除 + 1 行号重算）
- 验证链：本地 0 失败（ft3/ft5 树）→ validate-patches prepare 绿 → 完整构建进行中
- 遗留风险：9999-25 hunk 24 删除后 XFRM 流重挂恢复上游 -EEXIST 语义（若现问题按新功能重做）；注释 990-04 引用待清理
