# Start with a clean Ubuntu base
FROM ubuntu:22.04

# Prevent interactive installer prompts
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install system dependencies (Ensuring Java 17 is explicitly installed)
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    wget \
    unzip \
    cpu-checker \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    xvfb \
    x11vnc \
    novnc \
    websockify \
    supervisor \
    fluxbox \
    && rm -rf /var/lib/apt/lists/*

# 2. Set up environmental variables for Android & Java
ENV ANDROID_HOME=/opt/android-sdk
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
# Ensure PATH points to the nested "latest" binary directory
ENV PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator:${JAVA_HOME}/bin

# 3. Download and unpack Android Command Line Tools (Structuring into "latest" directory)
WORKDIR /opt
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline.zip && \
    unzip -q cmdline.zip -d ${ANDROID_HOME}/cmdline-tools && \
    # Google unzips into cmdline-tools/cmdline-tools. We must rename that inner folder to "latest"
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    rm cmdline.zip

# 4. Accept Android SDK Licenses & install system components
# The --sdk_root argument matches the structure and stops the build from crashing
RUN mkdir -p /root/.android && touch /root/.android/repositories.cfg && \
    yes | sdkmanager --sdk_root=${ANDROID_HOME} --licenses && \
    sdkmanager --sdk_root=${ANDROID_HOME} "platform-tools" "emulator" "platforms;android-33" "system-images;android-33;google_apis;x86_64"

# 5. Create the Virtual Device (AVD) using explicit SDK paths
RUN echo "no" | avdmanager --sdk_root=${ANDROID_HOME} create avd \
    --name MyCloudPhone \
    --package "system-images;android-33;google_apis;x86_64" \
    --device "pixel_6"

# 6. Copy supervisor configuration to manage internal processes
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose noVNC port (browser interface) and ADB (for debugging)
EXPOSE 6080 5555

# Boot process manager
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
