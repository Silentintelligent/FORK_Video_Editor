#!/usr/bin/env bash
# Builds FORK as a signed Android App Bundle (.aab) for Google Play.
# Usage: ./build-aab.sh [versionCode] [versionName]
set -euo pipefail

root=$(cd "$(dirname "$0")" && pwd)
code=${1:-1}
name=${2:-0.1.0}

: "${ANDROID_HOME:?ANDROID_HOME is not set}"

echo "== 1. FFmpeg for arm64"
"$root/src/scripts/ffmpeg-mobile.sh" aarch64-linux-android

echo "== 2. sherpa-onnx for arm64"
"$root/src/scripts/sherpa-mobile.sh" aarch64-linux-android

echo "== 3. Rust build of libconcat_android.so"
cd "$root/src"
env_exports=$(scripts/mobile-env.sh aarch64-linux-android)
eval "$env_exports"
export RUSTFLAGS="${RUSTFLAGS:-} -C link-arg=-Wl,-z,max-page-size=16384 -C link-arg=-Wl,-z,common-page-size=16384"
cargo ndk -t arm64-v8a --platform 26 build --release -p concat-android

echo "== 4. Copying native libraries into the Gradle project"
so=$(find "$root/src" -path "*aarch64-linux-android/release/libconcat_android.so" | head -n 1)
if [ -z "$so" ]; then
  echo "ERROR: libconcat_android.so was not found after the build" >&2
  exit 1
fi
echo "found: $so"
jni="$root/android/app/src/main/jniLibs/arm64-v8a"
rm -rf "$root/android/app/src/main/jniLibs"
mkdir -p "$jni"
cp -f "$so" "$jni/"
cp -f "$root"/src/vendor/sherpa-onnx/jniLibs/arm64-v8a/*.so "$jni/"
ls -l "$jni"

echo "== 5. 16 KB page-size check"
fail=0
for lib in "$jni"/*.so; do
  while read -r align; do
    if [ $((align)) -lt 16384 ]; then
      echo "NOT 16 KB aligned: $lib (align $align)" >&2
      fail=1
      break
    fi
  done < <(readelf -lW "$lib" | awk '$1=="LOAD" {print $NF}')
done
if [ "$fail" -ne 0 ]; then
  echo "WARNING: the libraries listed above are not 16 KB aligned. The bundle is still built so you can test it, but Google Play may reject it until they are rebuilt." >&2
fi

echo "== 6. Gradle bundle and signing"
cd "$root/android"
gradle --no-daemon bundleRelease -PFORK_VERSION_CODE="$code" -PFORK_VERSION_NAME="$name"
echo "Done: $root/android/app/build/outputs/bundle/release/app-release.aab"
