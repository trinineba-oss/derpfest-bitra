#!/bin/sh
set -e
cd "$(dirname "$0")"
VER=$(grep '^version=' module.prop | cut -d= -f2)
OUT="$PWD/Bitra-Charge-Guard-$VER.zip"
rm -f "$OUT"
zip -r -X -q "$OUT" module.prop customize.sh defaults.conf service.sh guard.sh status.sh action.sh uninstall.sh system META-INF
echo "$OUT"
