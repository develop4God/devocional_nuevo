# Android Emulator Setup (Linux, hybrid AMD/NVIDIA GPU)

## The problem

On this machine (Pop!_OS, hybrid AMD iGPU + NVIDIA RTX 3050 laptop GPU), the
Android emulator crashes reliably ~1-2 minutes after boot, under real app
load (image decode + TTS init), with **no crash signature anywhere**:

- No error in the emulator's own stdout log — it just stops writing.
- No entry in the emulator's Crashpad crash database
  (`/tmp/android-<user>/emu-crash-*.db` stays empty).
- No core dump (disabled by default: `ulimit -c` = 0).
- `adb devices` and the qemu process both vanish simultaneously.

The actual cause, found via `sudo dmesg -T | grep -iE "kill|oom|qemu|segfault"`
run in a separate terminal while reproducing the crash:

```
RenderThread[29625]: segfault at 5e8dcf69bfe0 ip 00005e8daf483ffd sp ... error 4
RenderThread[29622]: segfault at 5e8dcf69bfe0 ip 00005e8daf483ffd sp ... error 4
RenderThread[29624]: segfault at 5e8dcf69bfe0 ip 00005e8daf483ffd sp ... error 4
```

Multiple `RenderThread` workers segfaulting at the identical instruction
pointer simultaneously — a driver/library bug in the emulator's graphics
backend, not an app or memory issue. It happened with every renderer mode we
tried when the emulator picked the **AMD Radeon iGPU**:

- `-gpu host` (bare, no offload) — crashed almost immediately during GPU init.
- `-gpu swiftshader_indirect` — booted fine, then RenderThread segfault under load.
- `-gpu angle_indirect` — same, died even sooner.
- Lighter AVD (API 34, no Play Store, small screen) — same crash, so AVD
  weight/API level was never the variable.

Ruled out along the way (do not re-investigate these):
- Memory pressure — freed 3.5GB+ by stopping Gradle daemons, crash unchanged.
- Corrupted snapshot — wiped `~/.android/avd/<avd>.avd/snapshots/default_boot`, crash unchanged.
- TTS engine disabled — was actually true (`pm enable com.google.android.tts` was needed
  separately, see below) but not the cause of the emulator dying.
- `NotificationService.initialize()` / the notification permission dialog — temporarily
  disabled that exact code path in `main.dart`, emulator still crashed at the same point.
  Physical-device comparison also showed this code path is fine on real hardware.

## The fix

Force the emulator onto the **discrete NVIDIA GPU** via PRIME render offload,
bypassing the AMD iGPU + Mesa/RADV path entirely:

```bash
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia \
  emulator -avd <AVD_NAME> -no-window -gpu host
```

Verify it actually took effect — the log should show:

```
INFO | Selecting Vulkan device: NVIDIA GeForce RTX 3050 Laptop GPU, ...
INFO | GPU Vendor=[Google (NVIDIA Corporation)]
INFO | GPU Renderer=[Android Emulator OpenGL ES Translator (NVIDIA GeForce RTX 3050 Laptop GPU/PCIe/SSE2)]
```

If it still says `GPU Vendor=[Google (AMD)]`, the offload env vars didn't
take — check that the NVIDIA proprietary driver is loaded (`nvidia-smi -L`
should list the GPU).

This is the standard hybrid-GPU-laptop fix documented on the Arch/Gentoo
wikis for PRIME render offload, and matches community reports of the same
class of issue (e.g. pop-os/pop#3754 — Android emulator failing on an NVIDIA
laptop GPU under Pop!_OS).

## Other flags used

- `-no-window` — headless; the emulator's own Qt UI window was separately
  observed to break the X11 connection (`X connection to :1 broken`) on this
  machine. Not needed once you're viewing via scrcpy instead.
- `--render-driver=software` on scrcpy — avoids a separate, unrelated scrcpy
  client-side rendering issue seen when it used the default driver.

## One-time device setup

A stock AVD image ships with the Google TTS engine present but **disabled**,
and no default TTS synth set. If `flutter_tts` silently does nothing, check:

```bash
adb -s emulator-5554 shell dumpsys package com.google.android.tts | grep "enabled="
adb -s emulator-5554 shell settings get secure tts_default_synth
```

Fix once per fresh AVD:

```bash
adb -s emulator-5554 shell pm enable com.google.android.tts
adb -s emulator-5554 shell settings put secure tts_default_synth com.google.android.tts
```

This resets on wipe-data/cold-boot-from-scratch, so re-run it if you delete
and recreate the AVD.

## Usage

Three named AVDs exist, one script per device, in `scripts/`:

| Script | AVD | Profile |
|---|---|---|
| `scripts/emulator_pixel7.sh` | `Pixel7_API35` | Pixel 7, API 35 |
| `scripts/emulator_small_phone.sh` | `SmallPhone_API35` | small_phone, API 35 |
| `scripts/emulator_tablet.sh` | `PixelTablet_API35` | Pixel Tablet, API 35 |

Each script boots its emulator headless with the NVIDIA fix applied, waits
for it to come online, then launches scrcpy automatically. Run one from a
terminal:

```bash
scripts/emulator_pixel7.sh
```

Then in a second terminal, once the scrcpy window shows the home screen:

```bash
flutter run -d emulator-5554
```

Only one emulator can be booted at a time under the default AVD networking
(`emulator-5554`); stop one before starting another with:

```bash
scripts/emulator_stop.sh
```

It kills any running emulator/scrcpy processes immediately (no prompt) and
reports each PID it stopped.

## Recreating an AVD from scratch

If an AVD gets corrupted (bad snapshot, etc.), delete and recreate it:

```bash
avdmanager delete avd -n Pixel7_API35
avdmanager create avd -n Pixel7_API35 \
  -k "system-images;android-35;google_apis_playstore;x86_64" \
  -d "pixel_7"
```

Device profile ids used here: `pixel_7`, `small_phone`, `pixel_tablet`
(`avdmanager list device` shows all available ids).
