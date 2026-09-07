#!/bin/bash

set -e

# If the installation flag of the Android SDK is set
# we download the Android command-line tools,
# install the SDK, platform tools and the emulator.
if [ "$INSTALL_ANDROID_SDK" == "1" ]; then
  echo "Installing the cmdline-tools, images and emulator ..."
  CMD_LINE_VERSION=${CMD_LINE_VERSION:-15859902_latest}
  wget "https://dl.google.com/android/repository/commandlinetools-linux-${CMD_LINE_VERSION}.zip" -P /tmp
  unzip -d /tmp "/tmp/commandlinetools-linux-${CMD_LINE_VERSION}.zip"
  mkdir -p "${ANDROID_HOME}/cmdline-tools/latest/"
  mv /tmp/cmdline-tools/* "${ANDROID_HOME}/cmdline-tools/latest/"
  yes | sdkmanager --licenses
  sdkmanager --install "${PACKAGE_PATH}" platform-tools emulator
  echo -e \
   "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<d:devices xmlns:d=\"http://schemas.android.com/sdk/devices/7\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">\n</d:devices>\n" \
   > "${ANDROID_HOME}/system-images/android-${API_LEVEL}/${ABI}/devices.xml"
  rm -rf /tmp/* /root/.android/cache
fi
