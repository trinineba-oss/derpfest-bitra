#!/bin/bash
# Re-apply this repo's patches to a synced DerpFest 16.2 tree. Run after every `repo sync`
# (a sync with --force-sync resets the patched projects). Usage: TOP=/path/to/tree ./apply-patches.sh
set -u
TOP=${TOP:-/opt/derp17}
HERE=$(cd "$(dirname "$0")" && pwd)
apply() { # <project dir> <patch>
  if git -C "$TOP/$1" apply --check "$HERE/$2" 2>/dev/null; then
    git -C "$TOP/$1" apply "$HERE/$2" && echo "applied  $2"
  elif git -C "$TOP/$1" apply --check -R "$HERE/$2" 2>/dev/null; then
    echo "present  $2"
  else
    echo "FAILED   $2  (upstream changed: check by hand)"
  fi
}
apply vendor/realme/bitra               patches/vendor_realme_bitra-import-hardware-oplus.patch
apply frameworks/base                   patches/frameworks_base-sqlitetokenizer-check-brackets.patch
apply device/realme/sm8250-common       patches/device_sm8250-common-viper4android-audio-effects.patch
apply device/realme/bitra               patches/device_bitra-viper4android-realmeaddons.patch
apply device/realme/sm8250-common       patches/camera/device_sm8250-common-E3-pins.patch
apply vendor/realme/sm8250-common       patches/camera/vendor_sm8250-common-Androidbp-refocus_preview-libcdsprpc.patch
echo
echo "Camera: the 5 OnePlus 8T ArcSoft libs are NOT in this repo. Get them from"
echo "https://github.com/trinineba-oss/bitra-portrait-fix (blobs/) and copy them to"
echo "  $TOP/vendor/realme/sm8250-common/proprietary/odm/lib64/ (4 .so) and .../odm/lib/rfsa/adsp/ (skel)."
