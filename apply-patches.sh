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
apply frameworks/base                   patches/frameworks_base-sqlitetokenizer-check-brackets.patch
apply device/realme/sm8250-common       patches/device_sm8250-common-viper4android-audio-effects.patch
apply device/realme/bitra               patches/device_bitra-viper4android-realmeaddons.patch
apply vendor/realme/sm8250-common       patches/vendor_sm8250-common-wifi-roam-5ghz.patch
apply device/realme/sm8250-common       patches/device_sm8250-common-softap-ac-acs.patch
apply packages/apps/RealmeAddons        patches/RealmeAddons-hide-zram.patch
echo
echo "Camera: the OnePlus 8T ArcSoft libs and the vendor namespace import are upstream since 2026-10-07;"
echo "patches/camera/ and the bitra namespace patch are kept only for older trees."
