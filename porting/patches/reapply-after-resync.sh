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
# 5) vendor/lineage/config/BoardConfigKernel.mk: drop the hardcoded space in
#    non-clang KERNEL_CROSS_COMPILE when CCACHE_BIN is empty (upstream 17.1
#    bug: leading whitespace lands in the kernel compiler prefix → bash
#    "No such file or directory"); pinned tree → workspace patch.
#    NOTE: steps 5 and 6 both touch the same file, so the guard is a content
#    marker, not "tree is clean" (a clean-tree check would skip the second
#    patch after the first dirties the tree).
if ! grep -q 'strip $(CCACHE_BIN)' "$W/vendor/lineage/config/BoardConfigKernel.mk" 2>/dev/null; then
  git -C "$W/vendor/lineage" apply "$P/lineage-kernel-ccache-space.diff"
  echo "applied: lineage kernel ccache space fix"
fi
# 6) vendor/lineage/config/BoardConfigKernel.mk: drop HOST CPATH from kernel
#    make flags (GCC honors CPATH → host x86_64 headers leak into arm64 cross
#    compile; lib/raid6 neon1.c failed on gnu/stubs-32.h); pinned tree
if ! grep -q 'era-fix (grandprimevelte port): CPATH pointed at HOST' "$W/vendor/lineage/config/BoardConfigKernel.mk" 2>/dev/null; then
  git -C "$W/vendor/lineage" apply "$P/lineage-kernel-cpath-stub.diff"
  echo "applied: lineage kernel cpath strip"
fi
# 7) device/lineage/sepolicy: Q-era trim of legacy-camera-hal1 mediaserver.te
#    (HAL1 add-grants collide with Q cameraserver's own add_service/add_hwservice
#    neverallow reservations → 8 neverallow failures, wall #35); pinned tree
if ! grep -q "era (2026-10-23, grandprimevelte port)" "$W/device/lineage/sepolicy/legacy-common/public/legacy-camera-hal1/mediaserver.te" 2>/dev/null; then
  git -C "$W/device/lineage/sepolicy" apply "$P/lineage-sepolicy-camera-hal1-q.diff"
  echo "applied: lineage legacy-camera-hal1 Q trim"
fi
# 8) system/sepolicy/private/domain.te: at_distributor + rtcc into the
#    dac_override_allowed exemption list (stock-lifted capability users; m4
#    macro cannot be opted into from device policy; neverallow otherwise
#    rejects the fix.te grants, wall #35); pinned tree marker-guarded (the
#    comment header we add is the marker)
if ! grep -q "grandprimevelte port): at_distributor and rtcc added" "$W/system/sepolicy/private/domain.te" 2>/dev/null; then
  git -C "$W/system/sepolicy" apply "$P/lineage-system-sepolicy-dac.diff"
  echo "applied: system sepolicy dac_override_allowed opt-in"
fi
echo done
