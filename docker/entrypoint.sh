#!/bin/bash
set -euo pipefail

TEST_AVD=$(avdmanager list avd | grep -c "android.avd" || true)
if [ "$TEST_AVD" == 1 ]; then
  echo "Use the exists Android Virtual Emulator ..."
else
  echo "Creating the Android Virtual Emulator ..."
  echo "Using package ${PACKAGE_PATH}, ABI ${ABI} and device ${DEVICE_ID} for creating the emulator"
  echo no | avdmanager --verbose create avd \
    --force \
    --name "${AVD_NAME}" \
    --abi "${ABI}" \
    --package "${PACKAGE_PATH}"
fi

echo "Starting emulator: avd=${AVD_NAME} gpu=${GPU_MODE} accel=${ACCEL_MODE}"
emulator -verbose -avd "${AVD_NAME}" \
  -no-window \
  -no-boot-anim \
  -gpu "${GPU_MODE}" \
  -accel "${ACCEL_MODE}" \
  -no-metrics \
  -no-snapshot \
  -no-audio \
  -skip-adb-auth \
  -engine qemu2 \
  -ranchu \
  -qcow2-for-userdata &
EMU_PID=$!

adb start-server
adb wait-for-device

# Relay adb (5555) and emulator console (5554) from container loopback to eth0
# so `adb connect <container-ip>:5555` / scrcpy from the host actually reaches it.
socat TCP-LISTEN:5555,fork,reuseaddr TCP:127.0.0.1:5555 &
socat TCP-LISTEN:5554,fork,reuseaddr TCP:127.0.0.1:5554 &

wait "${EMU_PID}"