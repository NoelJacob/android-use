FROM debian:trixie-slim

ARG EMULATOR_URL=https://dl.google.com/android/repository/emulator-linux_x64-15917651.zip
ARG EMULATOR_SHA1=1b1f78891abf8ec268264356e1365c25519e8379

ENV ANDROID_SDK_ROOT=/opt/android-sdk \
    PATH=/opt/android-sdk/emulator:/opt/android-sdk/platform-tools:$PATH \
    DEBIAN_FRONTEND=noninteractive

# --- Runtime libs mapped 1:1 from the AUR PKGBUILD depends() array ---
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
    # --- adb + relay so scrcpy on the host can attach ---
    android-tools-adb \
    socat \
    # --- fetch/unpack tooling ---
    curl \
    ca-certificates \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# --- Official Google emulator binary (same source the AUR PKGBUILD downloads) ---
RUN mkdir -p ${ANDROID_SDK_ROOT} \
    && curl -fsSL "${EMULATOR_URL}" -o /tmp/emulator.zip \
    && echo "${EMULATOR_SHA1}  /tmp/emulator.zip" | sha1sum -c - \
    && unzip -q /tmp/emulator.zip -d ${ANDROID_SDK_ROOT} \
    && rm /tmp/emulator.zip

# kvm group membership is granted at container-start via docker-compose's
# `group_add` (host GID), since that group's GID differs per host.
RUN useradd -m -u 1000 android \
    && chown -R android:android ${ANDROID_SDK_ROOT}

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER android
WORKDIR ${ANDROID_SDK_ROOT}

EXPOSE 5554 5555

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]