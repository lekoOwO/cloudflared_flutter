#!/usr/bin/env bash
set -euo pipefail

root="${1:-packages}"

required=(
  "arm64-v8a/libgojni.so"
  "armeabi-v7a/libgojni.so"
  "x86_64/libgojni.so"
  "x86/libgojni.so"
)

for abi_file in "${required[@]}"; do
  if ! find "$root" -path "*/$abi_file" -type f | grep -q .; then
    echo "Missing Android ABI library: $abi_file under $root" >&2
    exit 65
  fi
done

echo "Verified Android ABI libraries under $root"