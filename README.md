# DerpFest 16.2 for the realme GT Neo 2 (bitra)

An unofficial DerpFest 16.2 (Android 16 QPR2) build for the **realme GT Neo 2 (bitra, RMX3370)**, Snapdragon 870. This repo has everything needed to rebuild it from source: the manifest, build script, patches and Magisk modules. No binaries are stored here.

## Download

**[SourceForge: realme-gt-neo-2-bitra / DerpFest-16.2](https://sourceforge.net/projects/realme-gt-neo-2-bitra/files/DerpFest-16.2/)**

| | |
|---|---|
| File | `DerpFest-v16.2-20261005-bitra-Community-Stable.zip` (3.25 GiB) |
| SHA-256 | `929ccbbd4816976171884909fed6691d8cdc1a10ed9241cbf1cd5a0d2517aa87` |
| Security patch | 2026-08-01 |
| Google apps | Included |
| Signing | AOSP test keys |

The zip is larger than GitHub's 2 GB release limit, so it's hosted on SourceForge.

## What's different from other bitra builds

- **Full RAM configuration.** Some community builds set the low-RAM ("Android Go") flag. The Play Store then treats the phone as low-end, so the full Google app shows as "not compatible". This build doesn't set it.
- **Portrait mode works on both cameras.** The build uses the OnePlus 8T ArcSoft libraries; see [bitra-portrait-fix](https://github.com/trinineba-oss/bitra-portrait-fix). This fix is now upstream in the SM8250-Common Android 17 trees.
- **ViPER4Android built in**, with no root needed.
- **RealmeAddons built in:** smart and bypass charging, game bar, HBM, anti-flicker.
- **Contacts fix.** A LineageOS framework change the newer Contacts provider needs is backported.

## Install

You need an unlocked bootloader and a TWRP that supports dynamic partitions.

1. In TWRP, back up at least **Data** and **Boot**, and copy the backup off the phone.
2. Install the zip.
3. Wipe:
   - Coming from a DerpFest bitra build signed with the AOSP test keys: **Cache and Dalvik only**. Your data stays.
   - Coming from any other ROM: **Format Data**.
4. Reboot. The first boot takes a few minutes.

## Known issues

- **NFC battery drain.** On some boots the NXP NFC service gets stuck in a loop and uses about 3 CPU cores. The phone runs hot, and because the battery gets warmer, VOOC charges slower.
  - Cause: an upstream LineageOS commit, reverted on 2026-10-04.
  - Fixed in the next build.
  - Until then: reboot, or use the Charge & Thermal Guard module below, which restarts the stuck NFC service automatically.
- **RealmeAddons ZRAM page doesn't work.** ZRAM itself is on (4 GB); only the settings switch is broken. Fix planned.
- **Phone stays on 2.4 GHz Wi-Fi.** The stock Oplus Wi-Fi config turns off roaming back to 5 GHz, so once the phone drops to 2.4 GHz it stays there. Fix planned. Until then, turn Wi-Fi off and on, or use the Wi-Fi Roam Fix module below.
- **5 GHz hotspot** probably runs without Wi-Fi 5 (802.11ac) or automatic channel selection. Not yet confirmed on the phone.

## Magisk modules (`magisk/`)

These are test modules for this build. Build each with its own `build.sh`.

| Module | What it does |
|---|---|
| `wifi-roam` | Turns the Wi-Fi chip's 2.4→5 GHz roaming back on: restores Qualcomm's defaults `roam_bg_scan_client_bitmap=0x424` and `roam_bad_rssi_thresh_offset_2g=40` in the ROM's own `WCNSS_qcom_cfg.ini`. Verified on the phone that the driver loads the patched file; the roaming itself is not yet confirmed on device. |
| `charge-guard` | Charging and thermal guard. Full charging speed while cool. Lowers charging current through Oplus `cool_down` when the skin reaches 45/47/49 °C, with hysteresis. Optional "cooler charging" caps the CPU while charging with the screen on. Watchdog for the NFC loop. Status from the Magisk Action button, or `su -c bitra-guard`. |

## Building

```sh
repo init -u https://github.com/DerpFest-AOSP/android_manifest -b 16.2 --depth=1 --git-lfs
mkdir -p .repo/local_manifests && cp manifest/bitra.xml .repo/local_manifests/
repo sync -c -j8 --no-tags
TOP=$PWD /path/to/this/repo/apply-patches.sh      # after every sync
TOP=$PWD /path/to/this/repo/build.sh
```

`apply-patches.sh` reports each patch as applied, already present, or failed. It also tells you where to get the OnePlus 8T camera libraries; they aren't stored here.

**Requirements:**
- About 300 GB of disk space.
- About 39 GB of RAM plus swap for Soong's analysis step. 16 GB in WSL thrashes and never finishes.

**Traps:**
- A shell `grep` wrapper (ugrep) breaks `lunch`; `build.sh` unsets it.
- Use the three-argument `lunch lineage_bitra bp4a user`.

## Patches

| Patch | Why |
|---|---|
| `vendor_realme_bitra-import-hardware-oplus` | The vendor namespace must import `hardware/oplus`, or the osense and cammidasservice modules are undefined |
| `frameworks_base-sqlitetokenizer-check-brackets` | Backport of LineageOS c08579f54, needed by ContactsProvider (`OPTION_CHECK_BRACKETS`) |
| `device_sm8250-common-viper4android-audio-effects` | Registers the ViPER4Android effect library |
| `device_bitra-viper4android-realmeaddons` | Adds ViPER4Android and RealmeAddons to the build |
| `camera/*` | OnePlus 8T dualcam file pins, and declares `libcdsprpc` for `refocus_preview` |

## Credits

SM8250-Common and bijoyv9 (device trees, the Entropy kernel, vendor), DerpFest, LineageOS, and the ViPER4Android RE fork.

Proprietary files are not redistributed here.
