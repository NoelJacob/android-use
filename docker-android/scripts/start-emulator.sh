#!/bin/bash

set -e

source ./emulator-monitoring.sh

# The emulator console port.
EMULATOR_CONSOLE_PORT=5554
# The ADB port used to connect to ADB.
ADB_PORT=5555
OPT_MEMORY=${OPT_MEMORY:-8192}
OPT_CORES=${OPT_CORES:-4}
SKIP_AUTH=${SKIP_AUTH:-1}
AUTH_FLAG=
GPU_ACCELERATED=${GPU_ACCELERATED:-1}

# Start ADB server by listening on all interfaces.
echo "Starting the ADB server ..."
adb -P 5037 server nodaemon &

# Detect ip and forward ADB ports from the container's network
# interface to localhost.
LOCAL_IP=$(ip addr list eth0 | grep "inet " | cut -d' ' -f6 | cut -d/ -f1)
socat tcp-listen:"$EMULATOR_CONSOLE_PORT",bind="$LOCAL_IP",fork tcp:127.0.0.1:"$EMULATOR_CONSOLE_PORT" &
socat tcp-listen:"$ADB_PORT",bind="$LOCAL_IP",fork tcp:127.0.0.1:"$ADB_PORT" &

export USER=root

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

if [ "$SKIP_AUTH" == 1 ]; then
  AUTH_FLAG="-skip-adb-auth"
fi

# GPU mode: `host` uses the container GPU via gfxstream's headless
# EGL/Vulkan backend. No Xvfb — a software X server forces Mesa's
# llvmpipe software GL and blocks NVIDIA hardware rendering.
if [ "$GPU_ACCELERATED" == 1 ]; then
  export GPU_MODE="host"
  export EGL_PLATFORM="surfaceless"
else
  export GPU_MODE="swiftshader_indirect"
fi

# libglvnd can't resolve the toolkit's bind-mounted vendor JSONs (bare SONAMEs;
# Arch host libs land in /usr/lib, not the Ubuntu multiarch dir). Generate
# full-path JSONs so EGL vendor discovery finds NVIDIA and Mesa.
mkdir -p /tmp/egl_vendors
printf '{"file_format_version":"1.0.0","ICD":{"library_path":"/usr/lib/libEGL_nvidia.so.0"}}\n' > /tmp/egl_vendors/10_nvidia.json
printf '{"file_format_version":"1.0.0","ICD":{"library_path":"/usr/lib/x86_64-linux-gnu/libEGL_mesa.so.0"}}\n' > /tmp/egl_vendors/50_mesa.json
export __EGL_VENDOR_LIBRARY_DIRS=/tmp/egl_vendors

# The emulator launcher prepends its bundled gles_swiftshader/ to
# LD_LIBRARY_PATH, so the gfxstream backend's dlopen("libEGL.so") loads the
# bundled SwiftShader software EGL instead of the system glvnd. Symlink the
# system glvnd into the first search dir (vulkan/) so host EGL wins.
ln -sf /usr/lib/x86_64-linux-gnu/libEGL.so.1 /opt/android/emulator/lib64/vulkan/libEGL.so
ln -sf /usr/lib/x86_64-linux-gnu/libEGL.so.1 /opt/android/emulator/lib64/vulkan/libEGL.so.1
ln -sf /usr/lib/x86_64-linux-gnu/libGL.so.1 /opt/android/emulator/lib64/vulkan/libGL.so.1

# Asynchronously write updates on the standard output
# about the state of the boot sequence.
wait_for_boot &

# Start the emulator with no audio, no GUI, and no snapshots.
echo "Starting the emulator ..."
echo "OPTIONS:"
echo "SKIP ADB AUTH - $SKIP_AUTH"
echo "GPU           - $GPU_MODE"
echo "MEMORY        - $OPT_MEMORY"
echo "CORES         - $OPT_CORES"
echo "AUTH_FLAG     - $AUTH_FLAG"
echo "EXTRA_FLAGS   - $EXTRA_FLAGS"
emulator \
  -avd android \
  -gpu "$GPU_MODE" \
  -memory "$OPT_MEMORY" \
  -no-boot-anim \
  -cores "$OPT_CORES" \
  -ranchu \
  "$AUTH_FLAG" \
  -no-window \
  -no-audio \
  -no-snapshot \
  -no-metrics || update_state "ANDROID_STOPPED"


  # -qemu \
  # -smp 8,sockets=1,cores=4,threads=2,maxcpus=8
