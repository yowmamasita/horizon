#!/bin/sh
# A signed debug APK (horizon.apk) of libmain.so, built from the workspace root with
#   cargo ndk -t arm64-v8a -P 30 -o crates/horizon-android/lib build --release -p horizon-android
# Needs ANDROID_HOME with build-tools 35.0.0 and platforms;android-35, and a JDK for keytool.
set -e
export KEYSTORE KEYSTORE_PASS
cd "$(dirname "$0")"
BT=$ANDROID_HOME/build-tools/35.0.0
# KEYSTORE and KEYSTORE_PASS sign with a kept key (so installs update in place); else a local debug key.
if [ -z "$KEYSTORE" ]; then
  KEYSTORE=debug.keystore KEYSTORE_PASS=android
  [ -f debug.keystore ] || keytool -genkeypair -keystore debug.keystore -storepass android -keypass android \
    -alias debug -keyalg RSA -validity 10000 -dname CN=debug >/dev/null 2>&1
fi
rm -f unsigned.apk aligned.apk horizon.apk
$BT/aapt2 link -o unsigned.apk --manifest AndroidManifest.xml --version-code "${VERSION_CODE:-1}" --version-name "${VERSION_NAME:-0.1.0}" -I $ANDROID_HOME/platforms/android-35/android.jar
zip -q -0 -r unsigned.apk lib   # stored, so the .so loads in place (extractNativeLibs=false)
$BT/zipalign -P 16 -f 4 unsigned.apk aligned.apk
$BT/apksigner sign --ks "$KEYSTORE" --ks-pass env:KEYSTORE_PASS --out horizon.apk aligned.apk
rm unsigned.apk aligned.apk
ls -la horizon.apk
