DEV="$(getprop ro.product.device) $(getprop ro.lineage.device) $(getprop ro.product.vendor.device)"
case "$DEV" in
  *bitra*|*RE5473*|*RE879AL1*) ui_print "- Device: realme GT Neo 2 (bitra)" ;;
  *) abort "! This module is only for the realme GT Neo 2 (bitra). Found: $DEV" ;;
esac
[ -w /sys/class/oplus_chg/battery/cool_down ] || [ -e /sys/class/oplus_chg/battery/cool_down ] \
  || abort "! Oplus charger control (cool_down) not found - unsupported kernel"
# Modules that fight with this one: disable (not delete) them; re-enable in Magisk if wanted
for m in ZyC_ThermalKiller xcharge; do
  if [ -d "/data/adb/modules/$m" ] && [ ! -f "/data/adb/modules/$m/disable" ]; then
    touch "/data/adb/modules/$m/disable"
    ui_print "- Disabled module '$m' (conflicts with this one; re-enable in Magisk to undo)"
  fi
done
CONF=/data/adb/bitra_charge_guard.conf
if [ ! -f "$CONF" ]; then
  cp "$MODPATH/defaults.conf" "$CONF"
  ui_print "- Settings: $CONF"
else
  ui_print "- Keeping existing settings: $CONF"
fi
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/system/bin/bitra-guard" 0 0 0755
ui_print "- Reboot to start. Status: Action button in Magisk, or 'su -c bitra-guard'"
