#!/system/bin/sh
MODDIR=${0%/*}
src="$MODDIR/files/WCNSS_qcom_cfg.ini"
dst=/odm/vendor/etc/wifi/WCNSS_qcom_cfg.ini
[ -f "$src" ] && [ -f "$dst" ] || exit 0
# Skip if the ROM's ini changed since install (e.g. after a ROM update) - reinstall the module instead
[ "$(sha256sum "$dst" | cut -d' ' -f1)" = "$(cat "$MODDIR/files/source.sha256" 2>/dev/null)" ] || exit 0
ctx=$(ls -Z "$dst" | awk '{print $1}')
[ -n "$ctx" ] && chcon "$ctx" "$src"
mount -o bind "$src" "$dst"
