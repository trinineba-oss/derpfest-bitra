#!/system/bin/sh
MODDIR=${0%/*}
until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 5; done
sleep 20
nohup sh "$MODDIR/guard.sh" > /dev/null 2>&1 &
