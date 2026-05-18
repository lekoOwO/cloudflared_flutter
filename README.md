# Cloudflared Flutter

Flutter packages for [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) with split Android ABI packages.

This project uses the official [cloudflared](https://github.com/cloudflare/cloudflared) source code as a git submodule and builds mobile bindings through gomobile.

## Packages

| Package | Purpose |
| --- | --- |
| `cloudflared_tunnel_full` | App-facing Flutter package. Add this to applications. |
| `cloudflared_tunnel_android_arm` | Android implementation package with `arm64-v8a` and `armeabi-v7a` native libraries. |
| `cloudflared_tunnel_android_x86` | Android sidecar package with `x86_64` and `x86` native libraries. |

Applications should depend only on:

```yaml
dependencies:
  cloudflared_tunnel_full: ^1.0.0
```

Use:

```dart
import 'package:cloudflared_tunnel_full/cloudflared_tunnel_full.dart';
```

The compatibility entrypoint is also available:

```dart
import 'package:cloudflared_tunnel_full/cloudflared_tunnel.dart';
```

## Android ABI support

The split packages provide these Android ABIs:

- `arm64-v8a`
- `armeabi-v7a`
- `x86_64`
- `x86`

## Project structure

```text
cloudflared_flutter/
├── cloudflared/                         # Git submodule from cloudflare/cloudflared
├── mobile/                              # Go wrapper for gomobile bindings
├── packages/
│   ├── cloudflared_tunnel_full/         # App-facing Dart API package
│   ├── cloudflared_tunnel_android_arm/  # Android implementation + ARM JNI libs
│   └── cloudflared_tunnel_android_x86/  # Android x86 sidecar JNI libs
└── tool/                                # Build and publishing helper scripts
```

## Build Android libraries

```bash
git submodule update --init --recursive
cd mobile
./build.sh android
```

The build creates a gomobile AAR and splits it into the Android ARM and x86 package directories.

## Run checks locally

```powershell
powershell -ExecutionPolicy Bypass -File tool/use_local_packages.ps1
flutter pub get --directory packages/cloudflared_tunnel_android_arm
flutter pub get --directory packages/cloudflared_tunnel_android_x86
flutter pub get --directory packages/cloudflared_tunnel_full
flutter test packages/cloudflared_tunnel_full
powershell -ExecutionPolicy Bypass -File tool/restore_pubspecs.ps1
```

## Publishing

First-time package creation requires local placeholder publishing. See [`docs/publishing-placeholders.md`](docs/publishing-placeholders.md).

After the three packages exist on pub.dev and GitHub Actions automated publishing is enabled, publish synchronized releases with:

```bash
git tag cloudflared_tunnel-v1.0.0
git push origin cloudflared_tunnel-v1.0.0
```

The publish workflow builds native libraries, publishes the Android sidecar packages first, waits for pub.dev visibility, then publishes `cloudflared_tunnel_full`.

## License

This project is licensed under the MIT License. It includes cloudflared, which is licensed under the Apache License 2.0.