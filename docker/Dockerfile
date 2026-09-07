FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Kolkata

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    unzip \
    openjdk-21-jre-headless

ENV ANDROID_SDK_ROOT=/opt/android-sdk \
    PATH=/opt/android-sdk/emulator:/opt/android-sdk/platform-tools:$PATH \
    CMD_LINE_VERSION=15859902_latest \
    API_LEVEL=34 \
    IMG_TYPE=google_apis_playstore \
    ARCHITECTURE=x86_64 \
    DEVICE_ID=pixel_9

ENV ANDROID_HOME=${ANDROID_SDK_ROOT} \
    PACKAGE_PATH="system-images;android-${API_LEVEL};${IMG_TYPE};${ARCHITECTURE}" \
    ABI="${IMG_TYPE}/${ARCHITECTURE}" \
    QTWEBENGINE_DISABLE_SANDBOX=1 \
    ANDROID_EMULATOR_WAIT_TIME_BEFORE_KILL=10 \
    QEMU_AUDIO_DRV=none

ENV PATH="${PATH}:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator:${ANDROID_HOME}/cmdline-tools/latest/bin"
ENV LD_LIBRARY_PATH="${ANDROID_HOME}/emulator/lib64:${ANDROID_HOME}/emulator/lib64/qt/lib"

RUN echo "Installing the cmdline-tools, images and emulator ..." && \
    wget "https://dl.google.com/android/repository/commandlinetools-linux-${CMD_LINE_VERSION}.zip" -P /tmp && \
    unzip -d /tmp "/tmp/commandlinetools-linux-${CMD_LINE_VERSION}.zip" && \
    mkdir -p "${ANDROID_HOME}/cmdline-tools/latest/" && \
    mv /tmp/cmdline-tools/* "${ANDROID_HOME}/cmdline-tools/latest/" && \
    yes | sdkmanager --licenses && \
    sdkmanager --install "${PACKAGE_PATH}" platform-tools emulator && \
    echo -e \
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<d:devices xmlns:d=\"http://schemas.android.com/sdk/devices/7\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">\n</d:devices>\n" \
    > "${ANDROID_HOME}/system-images/android-${API_LEVEL}/${ABI}/devices.xml" && \
    rm -rf /tmp/* /root/.android/cache

RUN apt-get update && apt-get install -y --no-install-recommends \
    dbus \
    libexpat1 \
    libgcc-s1 \
    libc6 \
    libbsd0 \
    libice6 \
    libpng16-16 \
    libpulse0 \
    libsm6 \
    libtiff6 \
    libx11-6 \
    libxcb1 \
    libxext6 \
    libxi6 \
    libxkbfile1 \
    libnspr4 \
    libnss3 \
    libuuid1 \
    libblkid1 \
    zlib1g \
    # --- generic GL/Vulkan dispatch libs; the actual NVIDIA ICD/driver .so files ---
    # --- are injected at container start by the nvidia-container-toolkit, not apt ---
    libglvnd0 \
    libgl1 \
    libegl1 \
    libgles2 \
    libvulkan1 \
    libnuma1 \
    e2fsprogs \
    # --- adb + relay so scrcpy on the host can attach ---
    socat \
    # --- fetch/unpack tooling ---
    && rm -rf /var/lib/apt/lists/*

# kvm group membership is granted at container-start via docker-compose's
# `group_add` (host GID), since that group's GID differs per host.
# RUN useradd -m -u 1000 android \
#     && chown -R android:android ${ANDROID_SDK_ROOT}

RUN echo 6

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# USER android
WORKDIR ${ANDROID_SDK_ROOT}

EXPOSE 5554 5555

ENV AVD_NAME=my_avd \
    GPU_MODE=host \
    ACCEL_MODE=auto \
    AVD_MEM=8192

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]