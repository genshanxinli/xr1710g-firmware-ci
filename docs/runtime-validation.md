# XR1710G 固件真机验收清单（Runtime Validation）

状态：待执行（刷机后逐项验收）| 门禁原则：**P0 全过才发版**；P1 记录结果；P2 尽力
固件基线：main @ 6.18.42 + hurryman SOE 系列 + mt76 backports（0001/0002/0003）

---

## P0 必测（不过不发版）

### P0-1 刷机与启动
- [ ] 刷机/启动正常（UBI/chainload 流程）
- [ ] LuCI 可访问（https://192.168.1.1）
- [ ] **LuCI 默认中文**（19-xr1710g-luci-language 生效：`uci get luci.main.lang` = zh_cn）

### P0-2 四网口 carrier（#24079 路径，最高优先）
- [ ] **10G 口 wan/lan1 冷启动有 carrier**（`cat /sys/class/net/*/carrier`）
- [ ] 10G 口协商正常（1G/2.5G/5G/10G：`ethtool wan` 各速率测试）
- [ ] **拔插恢复**（10G 口多次拔插 carrier 恢复，无"nobody cared" IRQ 错误）
- [ ] 1G 口 lan2/lan3 冷启动 carrier + 1G 协商 + 拔插恢复
- [ ] `xr1710g-net-debug` 确认 **PHY ID ≠ 0x001cc890**（RTL8261BE 应为受支持 ID）
- [ ] dmesg 确认 rtl8261n.bin 固件加载成功、无 PHY 错误

### P0-3 三频 WiFi
- [ ] 2.4G/5G/6G 三频 SSID 扫描与连接正常（MT7996）
- [ ] 6G 可用（社区曾报 6G 不可用——专项验证）

### P0-4 硬件加速/NPU
- [ ] 开加速测速（flow offload on）：WAN-LAN 下载 ≥3000Mbps（社区基线参考）
- [ ] 关加速对比（功能正常，速率下降可接受）
- [ ] **NPU dmesg 无 `-ETIMEDOUT`/`-EPROBE_DEFER` 循环**（921 + 0015 生效）
- [ ] NPU probe 成功：`dmesg | grep -i npu` 显示 fw 版本加载

### P0-5 已知问题专项
- [ ] **LAN2 Rx 永远为 0 检查**（社区报告）：LAN2 插线跑流量，`ip -s link show lan2` RX bytes 增长
- [ ] 10G 口与 1G 口交叉场景（#24079 回归路径）

## P1 功能验证（记录结果）

### P1-1 IPSec/SOE（保留核心功能）
- [ ] IPSec 隧道建立（strongswan）+ 流量经隧道
- [ ] **SOE offload 生效**（`cat /sys/kernel/debug/airoha/ppe/...` 或 flowsense 面板：隧道流量走 HW）
- [ ] **XFRM 流重挂测试**（9999-25 重基后 `-EEXIST` 语义专项）：SA 更新/重挂场景反复测试无失败
- [ ] LAG XFRM offload（bonding 场景，若配置）

### P1-2 WiFi7/MLO
- [ ] MLO 多链路连接（支持 MLO 的客户端）
- [ ] 320MHz EHT 带宽（9990/9991 补丁路径）
- [ ] 160MHz BF fallback

### P1-3 系统细节
- [ ] LED 灯控正常（XR1710G 专用固件：boot 绿/failsafe 红/running 白）
- [ ] 风扇温控（NCT7511Y，luci-app-w1700k-fancontrol）
- [ ] **+200MHz OC 稳定性**（长时间负载：`stress`/持续测速 1h+ 无异常/无 panic）
- [ ] LRO/HW GRO 生效（`ethtool -k` 看 LRO 状态，002 补丁路径）

## P2 尽力（社区已知问题复现排查）

- [ ] **1Mbps 加速 bug 复现测试**（恩山报告：开加速随机掉 1Mbps 需重启）——长时间运行 + 特定流量模式观察
- [ ] 二层 AP 模式测速（社区基线 ~2000Mbps；桥接 offload 990-01/02/03 路径）
- [ ] 长时间运行稳定性（24h+ 内存/连接数观察）
- [ ] 6GHz mesh（#24080 airtime 告警观察，若配置 mesh）

## 验收记录模板

| 项 | 结果 | 数据/日志 | 备注 |
|---|---|---|---|
| P0-2 10G carrier | ✅/❌ | carrier 输出 | |
| ... | | | |

## 参考命令

```sh
# carrier 检查（#24079 方法）
for i in wan lan1 lan2 lan3; do echo "=== $i ==="; cat /sys/class/net/$i/operstate; cat /sys/class/net/$i/carrier; done
# PHY ID
xr1710g-net-debug | grep -i phy
# NPU
dmesg | grep -i npu
# 加速开关
uci set firewall.@defaults[0].flow_offloading='1'; uci commit firewall; /etc/init.d/firewall restart
# 测速
iperf3 -c <server> -t 60
```
