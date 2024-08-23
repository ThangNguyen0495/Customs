#!/bin/bash

set -e

# Install Java
echo "Installing Java JDK 22..."
sudo apt-get update
sudo apt-get install -y wget

# Download and install JDK 22
wget https://github.com/adoptium/temurin22-binaries/releases/download/jdk-22%2B6/OpenJDK22U-jdk_x64_linux_hotspot_22_6.tar.gz
sudo mkdir -p /usr/lib/jvm
sudo tar -xzf OpenJDK22U-jdk_x64_linux_hotspot_22_6.tar.gz -C /usr/lib/jvm

# Set JAVA_HOME and update PATH
export JAVA_HOME=/usr/lib/jvm/jdk-22
export PATH=$JAVA_HOME/bin:$PATH

# Update environment variables
echo "JAVA_HOME=$JAVA_HOME" >> "$GITHUB_ENV"
echo "PATH=$JAVA_HOME/bin:$PATH" >> "$GITHUB_ENV"
echo "$JAVA_HOME/bin" >> "$GITHUB_PATH"

# Enable KVM group permissions
echo "Enabling KVM group permissions..."
echo 'KERNEL=="kvm", GROUP="kvm", MODE="0666", OPTIONS+="static_node=kvm"' | sudo tee /etc/udev/rules.d/99-kvm4all.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --name-match=kvm

# Cache Android SDK
echo "Caching Android SDK..."
# This step is handled in the GitHub Actions workflow using actions/cache@v3
# This script assumes caching is already set up

# Install Android SDK if not cached
echo "Installing Android SDK..."
if [ ! -d "$HOME/android-sdk/cmdline-tools/tools" ]; then
  sudo apt-get update
  sudo apt-get install -y wget unzip
  wget https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip
  mkdir -p "$HOME"/android-sdk/cmdline-tools
  unzip commandlinetools-linux-8512546_latest.zip -d "$HOME"/android-sdk/cmdline-tools
  mv "$HOME"/android-sdk/cmdline-tools/cmdline-tools "$HOME"/android-sdk/cmdline-tools/tools
fi

# Set up environment variables for Android SDK
echo "Setting up environment variables..."
# shellcheck disable=SC2129
echo "ANDROID_HOME=$HOME/android-sdk" >> "$GITHUB_ENV"
echo "ANDROID_SDK_ROOT=$HOME/android-sdk" >> "$GITHUB_ENV"
echo "PATH=$ANDROID_HOME/cmdline-tools/tools/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH" >> "$GITHUB_ENV"
echo "$ANDROID_HOME/cmdline-tools/tools/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator" >> "$GITHUB_PATH"
echo "$ANDROID_HOME/platform-tools" >> "$GITHUB_PATH"

# Check Ubuntu environment variables
echo "Checking environment variables..."
echo "ANDROID_HOME: $ANDROID_HOME"
echo "JAVA_HOME: $JAVA_HOME"
echo "PATH: $PATH"

# Accept Android SDK licenses
echo "Accepting Android SDK licenses..."
yes | "$HOME"/android-sdk/cmdline-tools/tools/bin/sdkmanager --licenses

# Install SDK packages
echo "Installing SDK packages..."
"$HOME"/android-sdk/cmdline-tools/tools/bin/sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0" "system-images;android-33;google_apis;x86_64" "emulator"

# Check aapt
echo "Checking aapt..."
cd "$HOME"/android-sdk/build-tools
ls -l
cd "$HOME"/android-sdk/build-tools/33.0.0
ls -l

# Create Android emulator
echo "Creating Android emulator..."
echo "no" | "$HOME"/android-sdk/cmdline-tools/tools/bin/avdmanager create avd -n emu -k "system-images;android-33;google_apis;x86_64" --device "pixel"

# Start Android emulator
echo "Starting Android emulator..."
nohup "$HOME"/android-sdk/emulator/emulator -avd emu -no-snapshot-save -no-boot-anim -wipe-data -no-window -gpu off &
"$ANDROID_HOME"/platform-tools/adb wait-for-device

# Check list devices
echo "Checking list of devices..."
"$ANDROID_HOME"/platform-tools/adb devices
