# realme GT Neo 2 (bitra) only: patch the ROM's own WLAN ini at install time
DEV="$(getprop ro.product.device) $(getprop ro.lineage.device) $(getprop ro.product.vendor.device)"
case "$DEV" in
  *bitra*|*RE5473*|*RE879AL1*) ui_print "- Device: realme GT Neo 2 (bitra)" ;;
  *) abort "! This module is only for the realme GT Neo 2 (bitra). Found: $DEV" ;;
esac
SRC=/odm/vendor/etc/wifi/WCNSS_qcom_cfg.ini
[ -f "$SRC" ] || abort "! $SRC not found - this ROM is not supported"
mkdir -p "$MODPATH/files"
DST="$MODPATH/files/WCNSS_qcom_cfg.ini"
sed -e 's/^roam_bg_scan_client_bitmap=.*/roam_bg_scan_client_bitmap=0x424/' \
    -e 's/^roam_bad_rssi_thresh_offset_2g=.*/roam_bad_rssi_thresh_offset_2g=40/' "$SRC" > "$DST"
grep -q '^roam_bg_scan_client_bitmap=0x424$' "$DST" && grep -q '^roam_bad_rssi_thresh_offset_2g=40$' "$DST" \
  || abort "! The two roaming settings were not found in $SRC - nothing to change"
# Everything except the two settings must be byte-identical to the ROM's file
KEYS='^roam_(bg_scan_client_bitmap|bad_rssi_thresh_offset_2g)='
grep -vE "$KEYS" "$SRC" > "$MODPATH/a.tmp"; grep -vE "$KEYS" "$DST" > "$MODPATH/b.tmp"
cmp -s "$MODPATH/a.tmp" "$MODPATH/b.tmp" || abort "! Unexpected changes - aborting"
rm -f "$MODPATH/a.tmp" "$MODPATH/b.tmp"
ui_print "- roam_bg_scan_client_bitmap:     $(grep '^roam_bg_scan_client_bitmap=' "$SRC" | cut -d= -f2) -> 0x424"
ui_print "- roam_bad_rssi_thresh_offset_2g: $(grep '^roam_bad_rssi_thresh_offset_2g=' "$SRC" | cut -d= -f2) -> 40"
# Remember which ROM file this copy was made from; post-fs-data skips the mount if the ROM's file changes
sha256sum "$SRC" | cut -d' ' -f1 > "$MODPATH/files/source.sha256"
set_perm_recursive "$MODPATH/files" 0 0 0755 0644
ui_print "- Reboot to apply (the Wi-Fi driver reads this file once per boot)"
