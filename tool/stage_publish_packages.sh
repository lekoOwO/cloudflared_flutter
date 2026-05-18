#!/usr/bin/env bash
set -euo pipefail

stage_root="${1:-${RUNNER_TEMP:-build}/pub-packages}"
shift || true

packages=("$@")
if [[ ${#packages[@]} -eq 0 ]]; then
  packages=(
    "packages/cloudflared_tunnel_android_arm"
    "packages/cloudflared_tunnel_android_x86"
    "packages/cloudflared_tunnel_full"
  )
fi

case "$stage_root" in
  ""|"/"|".")
    echo "Refusing unsafe stage root: '$stage_root'" >&2
    exit 64
    ;;
esac

rm -rf "$stage_root"
mkdir -p "$stage_root"

find_bin="${FIND_BIN:-find}"
if [[ -x /usr/bin/find ]]; then
  find_bin="/usr/bin/find"
fi

for package_dir in "${packages[@]}"; do
  if [[ ! -f "$package_dir/pubspec.yaml" ]]; then
    echo "Not a Dart package: $package_dir" >&2
    exit 66
  fi

  package_name="$(basename "$package_dir")"
  destination="$stage_root/$package_name"
  mkdir -p "$(dirname "$destination")"
  cp -a "$package_dir" "$destination"

  "$find_bin" "$destination" \
    \( \
      -name ".dart_tool" -o \
      -name "build" -o \
      -name ".gradle" -o \
      -name ".kotlin" -o \
      -name ".pub" -o \
      -name ".pub-cache" \
    \) -prune -exec rm -rf {} +

  "$find_bin" "$destination" \
    \( \
      -name "pubspec.lock" -o \
      -name "local.properties" -o \
      -name ".flutter-plugins" -o \
      -name ".flutter-plugins-dependencies" \
    \) -type f -delete

  echo "Staged $package_name at $destination"
done

