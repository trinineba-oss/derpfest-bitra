#!/system/bin/sh
[ -f /data/adb/bitra_charge_guard/pid ] && kill "$(cat /data/adb/bitra_charge_guard/pid)" 2>/dev/null
echo 0 > /sys/class/oplus_chg/battery/cool_down 2>/dev/null
for p in /sys/devices/system/cpu/cpufreq/policy4 /sys/devices/system/cpu/cpufreq/policy7; do
  cat $p/cpuinfo_max_freq > $p/scaling_max_freq 2>/dev/null
done
rm -rf /data/adb/bitra_charge_guard /data/adb/bitra_charge_guard.conf
