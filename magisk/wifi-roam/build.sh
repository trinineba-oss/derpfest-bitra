#!/bin/sh
# Build the Magisk module zip. Usage: ./build.sh  -> Bitra-WiFi-Roam-Fix-<version>.zip
set -e
cd "$(dirname "$0")"
VER=$(grep '^version=' module.prop | cut -d= -f2)
OUT="$PWD/Bitra-WiFi-Roam-Fix-$VER.zip"
rm -f "$OUT"
zip -r -X -q "$OUT" module.prop customize.sh post-fs-data.sh META-INF
echo "$OUT"
