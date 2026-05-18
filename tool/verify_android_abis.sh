#!/usr/bin/env bash
set -euo pipefail

root="${1:-packages}"
find_bin="${FIND_BIN:-find}"
if [[ -x /usr/bin/find ]]; then
  find_bin="/usr/bin/find"
fi

required=(
  "arm64-v8a/libgojni.so"
  "armeabi-v7a/libgojni.so"
  "x86_64/libgojni.so"
  "x86/libgojni.so"
)

for abi_file in "${required[@]}"; do
  if ! "$find_bin" "$root" -path "*/$abi_file" -type f | grep -q .; then
    echo "Missing Android ABI library: $abi_file under $root" >&2
    exit 65
  fi
done

echo "Verified Android ABI libraries under $root"