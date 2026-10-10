#!/system/bin/sh
# Prints the current charging / thermal picture
STATE=/data/adb/bitra_charge_guard
BAT=/sys/class/power_supply/battery
OC=/sys/class/oplus_chg/battery
rd() { cat "$1" 2>/dev/null; }
. $STATE/state 2>/dev/null
cur=$(rd $BAT/current_now); v=$(rd $BAT/voltage_now); bt=$(rd $BAT/temp)
ma=${cur#-}
echo "Bitra Charge & Thermal Guard"
echo "--------------------------------"
echo "Charging : $(rd $BAT/status)   VOOC active: $( [ "$(rd $OC/voocchg_ing)" = 1 ] && echo yes || echo no )"
if [ "${cur:-0}" -lt 0 ] 2>/dev/null; then
  # dual-cell series pack: ~2 x cell voltage
  echo "Into battery: ${ma} mA  (~$(( ma * 2 * (v / 1000) / 1000000 )) W)"
else
  echo "Battery current: ${cur} mA (discharging)"
fi
if [ -n "$bt" ]; then
  t=$((bt / 10)); d=$((bt % 10))
  if [ $bt -lt 350 ]; then tier="full VOOC speed (3.6 A)"
  elif [ $bt -lt 370 ]; then tier="VOOC reduced to 3.2 A (35-37C)"
  elif [ $bt -lt 440 ]; then tier="VOOC reduced to 2.2 A (37-44C)"
  else tier="too hot for fast charging (44C+)"; fi
  echo "Battery  : $t.$d C -> $tier"
fi
echo "Skin     : ${skin:-?} C   cool_down: $(rd $OC/cool_down) $( case "$(rd $OC/cool_down)" in 0) echo '(no limit)';; 4) echo '(VOOC <= 2.5 A)';; 3) echo '(VOOC <= 2.0 A)';; 2) echo '(VOOC <= 1.5 A)';; esac )"
echo "Cooler charging: $( [ "$boost_cfg" = 1 ] && echo enabled || echo disabled ) $( [ "$boost_active" = 1 ] && echo '(CPU capped now)' )"
echo "NFC guard: ${nfc_restarts:-0} restart(s) this boot"
echo "thermal-engine: $(getprop init.svc.thermal-engine)"
echo "Battery health: $(rd $OC/battery_soh)%  cycles: $(rd $OC/battery_cc)"
if [ -n "$updated" ]; then
  age=$(( $(date +%s) - updated ))
  echo "Guard daemon: running (updated ${age}s ago)"
else
  echo "Guard daemon: NOT running"
fi
