#!/bin/sh
set -e

AVD_NAME="${AVD_NAME:-my_avd}"
GPU_MODE="${GPU_MODE:-host}"       # host = real GPU passthrough, swiftshader_indirect = software fallback
ACCEL_MODE="${ACCEL_MODE:-auto}"   # auto picks KVM if /dev/kvm is present

echo "Starting emulator: avd=${AVD_NAME} gpu=${GPU_MODE} accel=${ACCEL_MODE}"

# Creating the Android Virtual Emulator.
TEST_AVD=$(avdmanager list avd | grep -c "android.avd" || true)
if [ "$TEST_AVD" == 1 ]; then
  echo "Use the exists Android Virtual Emulator ..."
else
  echo "Creating the Android Virtual Emulator ..."
  echo "Using package '$PACKAGE_PATH', ABI '$ABI' and device '$DEVICE_ID' for creating the emulator"
  echo no | avdmanager create avd \
    --force \
    --name android \
    --abi "$ABI" \
    --package "$PACKAGE_PATH" \
    --device "$DEVICE_ID"
fi

emulator -avd "${AVD_NAME}" \
  -no-window \
  -no-boot-anim \
  -gpu "${GPU_MODE}" \
  -accel "${ACCEL_MODE}" \
  -qemu -enable-kvm &
EMU_PID=$!

adb start-server
adb wait-for-device

# Relay adb (5555) and emulator console (5554) from container loopback to eth0
# so `adb connect <container-ip>:5555` / scrcpy from the host actually reaches it.
socat TCP-LISTEN:5555,fork,reuseaddr TCP:127.0.0.1:5555 &
socat TCP-LISTEN:5554,fork,reuseaddr TCP:127.0.0.1:5554 &

wait "${EMU_PID}"