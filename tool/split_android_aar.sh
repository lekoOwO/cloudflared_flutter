#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 path/to/cloudflared.aar" >&2
  exit 64
fi

aar_file="$1"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
arm_pkg="$repo_root/packages/cloudflared_tunnel_android_arm/android"
x86_pkg="$repo_root/packages/cloudflared_tunnel_android_x86/android"

if [[ ! -f "$aar_file" ]]; then
  echo "AAR not found: $aar_file" >&2
  exit 66
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

unzip -q "$aar_file" -d "$tmp_dir"

required_files=(
  "classes.jar"
  "jni/arm64-v8a/libgojni.so"
  "jni/armeabi-v7a/libgojni.so"
  "jni/x86_64/libgojni.so"
  "jni/x86/libgojni.so"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "$tmp_dir/$file" ]]; then
    echo "Missing expected AAR entry: $file" >&2
    exit 65
  fi
done

rm -rf "$arm_pkg/libs" "$arm_pkg/src/main/jniLibs"
mkdir -p "$arm_pkg/libs" "$arm_pkg/src/main/jniLibs"
cp "$tmp_dir/classes.jar" "$arm_pkg/libs/cloudflared-classes.jar"
mkdir -p "$arm_pkg/src/main/jniLibs/arm64-v8a" "$arm_pkg/src/main/jniLibs/armeabi-v7a"
cp "$tmp_dir/jni/arm64-v8a/libgojni.so" "$arm_pkg/src/main/jniLibs/arm64-v8a/libgojni.so"
cp "$tmp_dir/jni/armeabi-v7a/libgojni.so" "$arm_pkg/src/main/jniLibs/armeabi-v7a/libgojni.so"

rm -rf "$x86_pkg/src/main/jniLibs"
mkdir -p "$x86_pkg/src/main/jniLibs/x86_64" "$x86_pkg/src/main/jniLibs/x86"
cp "$tmp_dir/jni/x86_64/libgojni.so" "$x86_pkg/src/main/jniLibs/x86_64/libgojni.so"
cp "$tmp_dir/jni/x86/libgojni.so" "$x86_pkg/src/main/jniLibs/x86/libgojni.so"

echo "Split Android AAR into:"
echo "  $arm_pkg"
echo "  $x86_pkg"