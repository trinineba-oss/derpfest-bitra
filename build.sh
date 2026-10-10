#!/bin/bash
# Real grep (the interactive shell wraps it with ugrep, which breaks envsetup)
unset -f grep egrep fgrep 2>/dev/null
TOP=${TOP:-/opt/derp17}
cd "$TOP" || exit 1
export USE_CCACHE=1 CCACHE_EXEC=/usr/bin/ccache CCACHE_DIR=$TOP/.ccache
ccache -M 60G >/dev/null
source build/envsetup.sh >/dev/null 2>&1
lunch lineage_bitra bp4a user || exit 1
export NINJA_ARGS="-k 0"
m derp -j"${JOBS:-8}"
