**Title:** OplusCamera portrait mode crashes on bitra (SD870): OnePlus 12 ArcSoft dualcam libs need a missing HTP DSP driver — OnePlus 8 libs fix front and rear

---

### Summary

On bitra (realme GT Neo 2, RMX3370), OplusCamera crashes about 20 seconds after entering Portrait mode. The cause is the OnePlus 12 ArcSoft dualcam blobs added in "sm8250-common: Pull libarcsoft_dualcam blobs from OnePlus 12": their QNN-HTP path asks the cDSP for `libarc_htp_driver_skel.so`, which doesn't exist (SD870 has HTA, not HTP). Bokeh init then hangs and the Oplus ALGO_INTERFACE watchdog aborts the app.

Replacing the dualcam set with the OnePlus 8 (same SoC family) versions fixes **both front and rear portrait** in my testing.

### Environment

- Device: realme GT Neo 2 (bitra / RMX3370), unrooted
- ROM: DerpFest 16.2 (BP4A.251205.006), built from your `lineage-23.2` trees:
  - `android_device_realme_sm8250-common` @ `27deeed`
  - `android_device_realme_bitra` @ `e1ccaf2`
  - vendor `proprietary_vendor_realme_sm8250-common` (gitlab bijoyv9) @ `d243594` "Update from RUI 14.0.0.2100(EX01)"
  - `vendor/oplus/camera` @ `7e48c91`
- OplusCamera: `com.oplus.camera` v40028 (4.020.39)

### Steps to reproduce

1. Open OplusCamera and switch to Portrait (front or rear).
2. Wait about 20 seconds (taking a photo is not required).
3. The app closes.

### Logs

Watchdog abort (tombstone, every crash):

```
E APS_CORE: [ERROR][ ALGO_INTERFACE ] AlgoInterface.cpp: 1152  thirdPartyAlgoTimerFunc()  timerType: 0 timeout, sigval: 0, raise SIGABRT, third party algo (aps_algo_bokeh) error!!!
F libc    : Fatal signal 6 (SIGABRT), code -1 (SI_QUEUE) in tid ... (POSIX timer 2), pid ... (om.oplus.camera)
      #01 pc 0000000000168564  /odm/lib64/libAlgoProcess.so (android::AlgoInterface::thirdPartyAlgoTimerFunc(sigval)+500)
```

Stack of the stuck thread, as dumped by the watchdog:

```
#00 /odm/lib64/libarcsoft_dualcam_refocus_uw.so (ARC_DCIR_Uninit+368)
#02 /odm/lib64/libarcsoft_dualcam_refocus_uw.so (ARC_DCIR_Init+92)
#03 /odm/lib64/libarcsoft_dualcam_bokeh_api.so (CDualCamImageBokeh::bokehInitialize(int, selectMaster_t)+136)
#05 /odm/lib64/libAlgoInterface.so (android::bokehInit(android::Obokeh*, android::AlgoProcessData*)+840)
#08 /odm/lib64/libAlgoProcess.so (android::AlgoInterface::init(void*)+1028)
```

Why init fails (from the same session):

```
W com.oplus.camera: apps_std_imp.c:881: Warning: apps_std_fopen_with_env failed with 0x2 for libarc_htp_driver_skel.so (No such file or directory)
E com.oplus.camera: fastrpc_apps_user.c:1325: Error 0x80000406: remote_handle_open_domain: dynamic loading failed for file:///libarc_htp_driver_skel.so?arc_qnn_driverv2_skel_handle_invoke&_modver=1.0&_dom=cdsp
```

### Root cause

- The OnePlus 12 `libarcsoft_qnnhtp.so` loads `libarc_htp_driver_skel.so` on the cDSP. The OnePlus 12 `refocus_left` and `refocus_uw` use it (QNN-HTP strings in both).
- No branch of the vendor repo (`lineage-23.0` through `lineage-24.0`) ships that skel. It would be built for the SM8650's HTP, which the SD870 doesn't have. The tree only has `libarc_hta_driver_skel.so`, which is for HTA.
- `ARC_DCIR_Init` fails, calls `ARC_DCIR_Uninit`, which never returns, and after 20 s the watchdog in `libAlgoProcess.so` raises SIGABRT.

### What I tested (one library set per build)

| Dualcam libs | Front portrait | Rear portrait | Failure |
|---|---|---|---|
| OnePlus 12 set (current) | crash | crash | watchdog abort, hang in `refocus_uw` `ARC_DCIR_Init` |
| Stock realme (vendor `lineage-23.0` blobs) | works | crash | SIGSEGV inside stock `refocus_left` (the original rear crash) |
| Stock + OnePlus 12 `refocus_left` only | crash | crash | same hang, now in `refocus_left` `ARC_DCIR_Init` |
| **OnePlus 8 set** | **works** | **works** | — |

ArcSoft versions: stock realme `Image_Dualcam_Refocus_1.10.0.1118`, OnePlus 8 `1.10.0.1035`, OnePlus 12 `1.12.0.1634`. The OnePlus 8 libs have no QNN/HTP references.

### Proposed change

Source of the OnePlus 8 files: `AxionAOSP-devices/android_vendor_oneplus_sm8250-common`, branch `lineage-23.0` @ `59a046d`, from `proprietary/vendor/lib64/` and `proprietary/vendor/lib/rfsa/adsp/`. That repo doesn't record which OxygenOS build the camera blobs came from.

In `proprietary-files.txt`, replace the "Camera - from OnePlus 12" block with:

```
# Camera - ArcSoft dualcam refocus from OnePlus 8 (same SoC family; uses HTA/HVX, no QNN-HTP)
odm/lib64/libarcsoft_dualcam_bokeh_api.so|1ab59342de1b31e8ed70335783a4f5f40653fb7d
odm/lib64/libarcsoft_dualcam_refocus_left.so|6b5d9bfe5251830fb54ac1f34b6e77339e32347e
odm/lib64/libarcsoft_dualcam_refocus_preview.so|e76f27e392463562ab447595dc5cdd587a61c000
odm/lib64/libarcsoft_dualcam_refocus_uw.so|6c290a3a3875f14e776f8df6d37670dec61e4086
odm/lib/rfsa/adsp/libarcsoft_dualcam_refocus_skel.so|2d7abab9c8d72d5410df2b6ab7a4d151c8151926
```

Notes:
- The OnePlus 8 `refocus_skel` should ship together with the OnePlus 8 host libs (they're a CPU/DSP pair). I left the realme HTA pair (`libarcsoft_hta.so` + `libarc_hta_driver_skel.so`) unchanged.
- `libarcsoft_qnnhtp.so` and `libarc.ion.so` are no longer referenced by anything in the build and can be dropped.
- The OnePlus 8 `refocus_preview` has `DT_NEEDED libcdsprpc.so`. If the generated `Android.bp` doesn't list `libcdsprpc` in its `shared_libs`, Soong's `check_elf_file` fails at build time (no runtime effect). Regenerating with `setup-makefiles` or adding it by hand should fix that.

### Not the cause (in case others hit it)

`avc: denied { read } for name="fastrpc_shell_3" ... scontext=u:r:platform_app ... tcontext=u:object_r:adsprpcd_file` shows up when the camera starts. It's harmless: `cdsprpcd` loads the shell straight after ("Created user PD on domain 3"). An `allow platform_app adsprpcd_file:file` rule would violate the Treble neverallow in `system/sepolicy/private/domain.te` anyway.

### Caveats

Tested on one bitra unit with DerpFest 16.2. Not tested on spartan, and I didn't compare image quality against stock realme UI.
