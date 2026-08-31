#!/usr/bin/env bash
# scripts/emulator_small_phone.sh
#
# Boots the SmallPhone_API35 emulator and opens scrcpy against it, in one shot.
# See docs/EMULATOR.md for why -gpu host + NVIDIA PRIME offload and
# --render-driver=software are required on this machine's hybrid AMD/NVIDIA
# GPU laptop — without them the emulator segfaults under load (RenderThread
# crash confirmed via dmesg) within 1-2 minutes of boot.
#
# Usage:
#   scripts/emulator_small_phone.sh
#
# Then in a separate terminal:
#   flutter run -d emulator-5554

set -euo pipefail

AVD_NAME="SmallPhone_API35"
SCRCPY_BIN="$HOME/tools/scrcpy-linux-x86_64-v4.1/scrcpy"

echo "Starting $AVD_NAME (NVIDIA PRIME offload, headless)..."
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia \
  emulator -avd "$AVD_NAME" -no-window -gpu host &

echo "Waiting for emulator-5554 to come online..."
until adb devices | grep -q "emulator-5554.*device"; do
  sleep 2
done

echo "Waiting for Android boot to finish (input subsystem must be up before scrcpy connects)..."
until [ "$(adb -s emulator-5554 shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
  sleep 2
done
echo "Emulator online and fully booted."

echo "Launching scrcpy..."
"$SCRCPY_BIN" -s emulator-5554 --render-driver=software
