#!/system/bin/sh
# Bitra Charge & Thermal Guard daemon (started by service.sh)
CONF=/data/adb/bitra_charge_guard.conf
STATE=/data/adb/bitra_charge_guard
LOG=$STATE/guard.log
CD=/sys/class/oplus_chg/battery/cool_down
BAT=/sys/class/power_supply/battery
PRIME=/sys/devices/system/cpu/cpufreq/policy7
GOLD=/sys/devices/system/cpu/cpufreq/policy4
NFC_PROC=android.hardware.nfc-service.nxp
mkdir -p $STATE
echo $$ > $STATE/pid

log() {
  echo "$(date '+%m-%d %H:%M:%S') $*" >> $LOG
  [ "$(wc -c < $LOG)" -gt 200000 ] && mv -f $LOG $LOG.old
}

zone() {
  for z in /sys/class/thermal/thermal_zone*; do
    [ "$(cat $z/type 2>/dev/null)" = "$1" ] && { echo $z/temp; return; }
  done
}
SKIN=$(zone skin-therm-usr)
BL=$(ls /sys/class/backlight/*/brightness 2>/dev/null | head -1)

# Highest available frequency <= $2 kHz for policy $1
cap_freq() {
  best=0
  for f in $(cat $1/scaling_available_frequencies); do
    [ $f -le $2 ] && [ $f -gt $best ] && best=$f
  done
  echo $best
}

# Severity order of cool_down levels used here: 0 (none) < 4 < 3 < 2
sev() { case $1 in 4) echo 1;; 3) echo 2;; 2) echo 3;; *) echo 0;; esac; }
thr() { case $1 in 4) echo $SKIN_L4;; 3) echo $SKIN_L3;; 2) echo $SKIN_L2;; *) echo 0;; esac; }

pick_level() { # $1 skin C, $2 current level
  if [ $1 -ge $SKIN_L2 ]; then t=2
  elif [ $1 -ge $SKIN_L3 ]; then t=3
  elif [ $1 -ge $SKIN_L4 ]; then t=4
  else t=0; fi
  # Relaxing: stay until skin is HYST below the current level's threshold
  if [ $(sev $t) -lt $(sev $2) ] && [ $1 -ge $(( $(thr $2) - HYST )) ]; then t=$2; fi
  echo $t
}

set_level() {
  [ "$1" = "$LEVEL" ] && return
  echo $1 > $CD 2>/dev/null && log "cool_down $LEVEL -> $1 (skin ${SKIN_C}C, batt ${BATT_C}C)"
  LEVEL=$1
}

boost() { # on|off
  if [ "$1" = on ] && [ "$BOOSTED" != 1 ]; then
    cap_freq $PRIME $BOOST_PRIME_KHZ > $PRIME/scaling_max_freq
    cap_freq $GOLD $BOOST_GOLD_KHZ > $GOLD/scaling_max_freq
    BOOSTED=1; log "cooler charging ON (batt ${BATT_C}C)"
  elif [ "$1" = off ] && [ "$BOOSTED" = 1 ]; then
    cat $PRIME/cpuinfo_max_freq > $PRIME/scaling_max_freq
    cat $GOLD/cpuinfo_max_freq > $GOLD/scaling_max_freq
    BOOSTED=0; log "cooler charging OFF"
  fi
}

nfc_check() {
  [ "$NFC_GUARD" = 1 ] || return
  pid=$(pidof $NFC_PROC)
  [ -z "$pid" ] && { NFC_PID=; return; }
  t=$(awk '{print $14 + $15}' /proc/$pid/stat 2>/dev/null)
  now=$(date +%s)
  if [ "$pid" = "$NFC_PID" ] && [ -n "$NFC_T" ]; then
    span=$(( now - NFC_AT ))
    # CPU ticks (100/s) used since last check; > half a core = spinning
    if [ $span -gt 0 ] && [ $(( (t - NFC_T) * 2 )) -gt $(( span * 100 )) ] && [ $NFC_RESTARTS -lt 5 ]; then
      kill $pid
      NFC_RESTARTS=$((NFC_RESTARTS + 1))
      log "NFC HAL spinning ($(( (t - NFC_T) / span ))% CPU) - restarted it ($NFC_RESTARTS this boot)"
      NFC_PID=; return
    fi
  fi
  NFC_PID=$pid; NFC_T=$t; NFC_AT=$now
}

LEVEL=; BOOSTED=0; NFC_RESTARTS=0; NFC_PID=; LAST_NFC=0
log "guard started (skin sensor: ${SKIN:-none})"
echo 0 > $CD 2>/dev/null; LEVEL=0

while true; do
  # defaults, then user settings
  SKIN_L4=45; SKIN_L3=47; SKIN_L2=49; HYST=2
  BOOST=0; BOOST_BATT=33; BOOST_PRIME_KHZ=2400000; BOOST_GOLD_KHZ=1900000; NFC_GUARD=1
  [ -f $CONF ] && . $CONF

  STATUS=$(cat $BAT/status 2>/dev/null)
  BATT_C=$(( $(cat $BAT/temp 2>/dev/null || echo 0) / 10 ))
  SKIN_C=$(( $(cat $SKIN 2>/dev/null || echo 0) / 1000 ))

  if [ "$STATUS" = Charging ] && [ -n "$SKIN" ]; then
    set_level $(pick_level $SKIN_C ${LEVEL:-0})
    SCREEN=$(cat $BL 2>/dev/null || echo 0)
    if [ "$BOOST" = 1 ] && [ "$SCREEN" -gt 0 ] && [ $BATT_C -ge $BOOST_BATT ]; then
      boost on
    elif [ "$BOOST" != 1 ] || [ "$SCREEN" -eq 0 ] || [ $BATT_C -lt $((BOOST_BATT - 1)) ]; then
      boost off
    fi
    SLEEP=10
  else
    set_level 0
    boost off
    SLEEP=30
  fi

  NOW=$(date +%s)
  [ $(( NOW - LAST_NFC )) -ge 60 ] && { nfc_check; LAST_NFC=$NOW; }

  echo "updated=$NOW status=$STATUS level=$LEVEL skin=$SKIN_C batt=$BATT_C boost_cfg=$BOOST boost_active=$BOOSTED nfc_restarts=$NFC_RESTARTS" > $STATE/state
  sleep $SLEEP
done
