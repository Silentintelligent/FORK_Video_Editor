#!/usr/bin/env bash
# Builds FORK as a signed Android App Bundle (.aab) for Google Play.
#
# Needs (Linux or macOS):
#   - Rust (version in src/rust-toolchain.toml) + `rustup target add aarch64-linux-android`
#   - cargo install cargo-ndk
#   - Android SDK with platform 36, build-tools 36, and NDK r28 or newer
#       (r28+ links for 16 KB memory pages by default, which Play requires)
#   - JDK 17+, Gradle 8.13+ (or run `gradle wrapper --gradle-version 8.13` in android/)
#   - cmake, libclang-dev
#   - env: ANDROID_HOME, and for signing FORK_KEYSTORE, FORK_KEYSTORE_PASSWORD, FORK_KEY_ALIAS
#
# Usage:  ./build-aab.sh [versionCode] [versionName]
# Output: android/app/build/outputs/bundle/release/app-release.aab
set -euo pipefail
root=$(cd "$(dirname "$0")" && pwd)
code=${1:-1}
name=${2:-0.1.0}

: "${ANDROID_HOME:?set ANDROID_HOME to the Android SDK}"

# 1. Native libraries FFmpeg and sherpa-onnx (arm64)
"$root/src/scripts/ffmpeg-mobile.sh" aarch64-linux-android
"$root/src/scripts/sherpa-mobile.sh" aarch64-linux-android

# 2. The Rust app, built as libconcat_android.so into the Gradle project
cd "$root/src"
eval "$(scripts/mobile-env.sh aarch64-linux-android)"
export RUSTFLAGS="${RUSTFLAGS:-} -C link-arg=-Wl,-z,max-page-size=16384 -C link-arg=-Wl,-z,common-page-size=16384"
jni="$root/android/app/src/main/jniLibs"
rm -rf "$jni"
cargo ndk -t arm64-v8a --platform 26 -o "$jni" build --release -p concat-android
# runtime libraries the app loads beside it (ONNX Runtime, sherpa-onnx, libc++_shared)
cp -f "$root"/src/vendor/sherpa-onnx/jniLibs/arm64-v8a/*.so "$jni/arm64-v8a/"

# 3. 16 KB page-size check: every LOAD segment must be aligned to 0x4000 or more.
fail=0
for so in "$jni"/arm64-v8a/*.so; do
  bad=$(readelf -lW "$so" | awk '$1=="LOAD" {print $NF}' | while read -r a; do
          [ $((a)) -lt 16384 ] && echo bad; done | head -1)
  if [ -n "$bad" ]; then echo "NOT 16 KB aligned: $so" >&2; fail=1; fi
done
[ $fail -eq 0 ] || { echo "Rebuild the listed libraries with -Wl,-z,max-page-size=16384 (or use a newer release of them) and run again." >&2; exit 1; }

# 4. Package + sign the bundle
cd "$root/android"
gradle --no-daemon bundleRelease -PFORK_VERSION_CODE="$code" -PFORK_VERSION_NAME="$name"
echo "Done: $root/android/app/build/outputs/bundle/release/app-release.aab"
