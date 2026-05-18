#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 package-dir [package-dir ...]" >&2
  exit 64
fi

gzip_limit=$((100 * 1024 * 1024))
unpacked_limit=$((256 * 1024 * 1024))
find_bin="${FIND_BIN:-find}"
if [[ -x /usr/bin/find ]]; then
  find_bin="/usr/bin/find"
fi

for package_dir in "$@"; do
  if [[ ! -f "$package_dir/pubspec.yaml" ]]; then
    echo "Not a Dart package: $package_dir" >&2
    exit 66
  fi

  tmp_file="$(mktemp --suffix=.tar.gz)"
  cleanup() {
    rm -f "$tmp_file"
  }
  trap cleanup RETURN

  tar \
    --exclude='.dart_tool' \
    --exclude='build' \
    --exclude='.git' \
    -czf "$tmp_file" \
    -C "$(dirname "$package_dir")" "$(basename "$package_dir")"

  gzip_size=$(wc -c < "$tmp_file")
  unpacked_size=$("$find_bin" "$package_dir" \
    -path '*/.dart_tool' -prune -o \
    -path '*/build' -prune -o \
    -type f -printf '%s\n' | awk '{ total += $1 } END { print total + 0 }')

  echo "$package_dir gzip=$gzip_size unpacked=$unpacked_size"

  if (( gzip_size > gzip_limit )); then
    echo "$package_dir exceeds gzip size limit guard: $gzip_size > $gzip_limit" >&2
    exit 65
  fi

  if (( unpacked_size > unpacked_limit )); then
    echo "$package_dir exceeds unpacked size limit guard: $unpacked_size > $unpacked_limit" >&2
    exit 65
  fi

  rm -f "$tmp_file"
  trap - RETURN
done