#!/bin/bash
# One-shot re-applier for workspace-only surgery on trees we do NOT own.
# Run after any `repo sync` that re-fetched these projects (or --force-sync'd them).
# Order does not matter; each step is idempotent-guarded.
set -e
W=/home/anvil/Projects/axos-work        # workspace root
P="$(dirname "$0")"                     # this script lives in .../porting/patches

# 1) hardened_malloc: drop soong-era fields + 32 GB -> 2 GB address-space sed
#    (mirror of AXP axp-a10 17.1 vendor/axp Patch.sh surgery)
if git -C "$W/external/hardened_malloc" diff --quiet 2>/dev/null; then
  git -C "$W/external/hardened_malloc" apply "$P/hardened_malloc-a10-soong.diff"
  echo "applied: hardened_malloc"
fi

# 2) lineage-sdk: drop orphaned telephony-ext static_lib
#    (module discontinued after LOS 16.0; 17.1 manifest still references it)
if git -C "$W/lineage-sdk" diff --quiet 2>/dev/null; then
  git -C "$W/lineage-sdk" apply "$P/lineage-sdk-drop-telephony-ext.diff"
  echo "applied: lineage-sdk"
fi

# 3) hardware/lineage/interfaces: delete cryptfshw subdirectory
#    (Qualcomm-only lineage HAL piece; its dependency died with the qcom sweep)
if [ -d "$W/hardware/lineage/interfaces/cryptfshw" ]; then
  rm -rf "$W/hardware/lineage/interfaces/cryptfshw"
  echo "removed: hardware/lineage/interfaces/cryptfshw"
fi
# 4) device/samsung/mrvl-common: era-fix in BoardConfigCommon.mk
#    (BOARD_CUSTOM_MKBOOTIMG bare "mkbootimg" name → Q kati phony hard-fail;
#    pinned tree, not a promoted repo, so workspace patch)
if git -C "$W/device/samsung/mrvl-common" diff --quiet 2>/dev/null; then
  git -C "$W/device/samsung/mrvl-common" apply "$P/mrvl-common-boardconfig-q-mkbootimg.diff"
  echo "applied: mrvl-common boardconfig"
fi
# 6) vendor/lineage/config/BoardConfigKernel.mk: drop HOST CPATH from kernel
#    make flags (GCC honors CPATH → host x86_64 headers leak into arm64 cross
#    compile; lib/raid6 neon1.c failed on gnu/stubs-32.h); pinned tree
if git -C "$W/vendor/lineage" diff --quiet 2>/dev/null; then
  git -C "$W/vendor/lineage" apply "$P/lineage-kernel-cpath-stub.diff"
  echo "applied: lineage kernel cpath strip"
fi

# 5) vendor/lineage/config/BoardConfigKernel.mk: drop the hardcoded space in
#    non-clang KERNEL_CROSS_COMPILE when CCACHE_BIN is empty (upstream 17.1
#    bug: leading whitespace lands in the kernel compiler prefix → bash
#    "No such file or directory"); pinned tree → workspace patch
if git -C "$W/vendor/lineage" diff --quiet 2>/dev/null; then
  git -C "$W/vendor/lineage" apply "$P/lineage-kernel-ccache-space.diff"
  echo "applied: lineage kernel ccache space fix"
fi
echo done
