# Upstream Tracking Report

Generated: 2026-08-07 09:30 UTC

## Lock state (ci/merge-all-2026-08-07)

| Source | Old SHA | New SHA | Note |
|---|---|---|---|
| fanboy | 1fcc93055cabcdf2553977245e03dcb9599e67cd | 3624ae940d734715358863b5e180f4e73152b6fd | offload ref deleted upstream (08-06); re-locked to ubi2-oc (openwrt master tip + 23 commits, incl. +200MHz OC) |
| hurryman | 73c3ab3081432f02d90b0084f63ea8ca4ea8589b | 73c3ab3081432f02d90b0084f63ea8ca4ea8589b | unchanged (branch head, no new commits) |
| yyh | 99598e539d47aa9f137baff43f0c2f77becc2e50 | 99598e539d47aa9f137baff43f0c2f77becc2e50 | unchanged (branch head, no new commits) |

## Additional absorbed content (2026-08-07)

- mt76: pin 7f4a3b71 (07-29) -> b2704cf5a4 (08-01) via patches/upstream-backports/0002
  - dropped overlay 0001/0002 (OOB fixes now upstream)
  - added 0022 (fanboy NPU wcid fix c4049715f1) + 0023-0038 (16 pending-branch hardening backports; reg-addr-remap skipped, same source as overlay/yyh 0022)
- hurryman overlay: mt76 0013/0014 (airoha PPE flush on STA teardown), EIP93 series
  (hack-6.18 925/926/9990/9991, pending-6.18 9915-9919; enhanced 926 replaces the plain upstream 926)
- yyh overlay: mt76 0083 (wcid assignment) + 9994 (PS sync TLV validation, renumbered from 9992)

## Corrections (verified against kernel.org changelogs)

- EIP93 fixes (devm_request_threaded_irq check 85a61bf9145d, reset ring register definition
  09e6b79b8ce3) landed in 6.18.40, not 6.18.41 as stated in YYH commit b88d674628.
- Local patches/yyh/kernel/921-* is content-identical to openwrt PR #24593 2/2
  (request_firmware_direct); supersede.list drops the local copy once upstream lands.

## Watched openwrt PRs (see monitor-upstream.sh state)

#22397 (XR1710G official support), #22697/#24571 (NPU firmware), #23644 (rtl8261ce),
#24593 (NPU memory + firmware loading), #23141 (npu_binary 10->1MiB), #24079 (W1700K carrier)
