# axpos-grandprimevelte

**AXP.OS port for the Samsung Galaxy Grand Prime VE LTE (`grandprimevelte` / SM-G531F).**

Target: **AXP.OS Slim** (Android 10, `axp-a10` = LineageOS 17.1 base) with the project's
hardening and CVE-fixing pipeline.

Device highlights: Marvell PXA1908 SoC, 1 GB RAM, Vivante GC7000UL GPU,
Marvell SDIO8777 Wi-Fi/BT, no system-as-root, kernel 3.14.27 (Marvell "helanx" platform).

## What this repository contains

| path | content |
|---|---|
| `porting/device-tree-base/` | the device-tree working copy (lineage-13.0 `grandprimevelte` tree as the true base — the publicly known `lineage-14.x` tree drifted into the sibling device, coreprimevelte — plus borrowed common-tree machinery) |
| `porting/kernel/` | `lineage_grandprimevelte_defconfig` — authored for this port (none was ever published upstream); append-only delta format |
| `workspace-manifests/` | manifest overlay set used with the AXP.OS workspace: pristine + corrected AXP `axp.xml`, device manifest with the five pinned community repos, and a shrink overlay isolating this device's needs |
| `tools/` | small self-contained project utilities |

The Android workspace itself, the stock firmware dump this port sources its vendor blobs
from, and the project's working notes/research live locally and are not part of this repo.

## Ecosystem links

- AXP.OS: https://axpos.org · github.com/AXP-OS
- Base platform manifest: github.com/LineageOS/android (`lineage-17.1`)
- Device tree base: github.com/notnoelchannel2/android_device_samsung_grandprimevelte (l13)
- Kernel: github.com/notnoelchannel2/android_kernel_samsung_grandprimevelte
- SoC/Marvell common: github.com/Nemirtingas/android_device_samsung_pxa1908-common,
  …android_device_samsung_mrvl-common, …android_hardware_marvell_pxa1908

## Status

Kernel configuration authored; source workspace fully materialized; vendor blob set
assembled from the verified stock image; device-tree era-upgrade in progress.

Private while in development. Published when bring-up lands.

---

Attribution: maintained by takyon303 with AI assistance (GLM / OpenCode).
