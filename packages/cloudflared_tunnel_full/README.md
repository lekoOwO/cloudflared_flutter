# cloudflared_tunnel_full

Flutter plugin for Cloudflare Tunnel with full Android ABI support through split platform packages.

## Android ABI support

This package depends on:

- `cloudflared_tunnel_android_arm` for `arm64-v8a` and `armeabi-v7a`
- `cloudflared_tunnel_android_x86` for `x86_64` and `x86`

Add only the app-facing package to your app:

```yaml
dependencies:
  cloudflared_tunnel_full: ^1.0.0
```

Use either import:

```dart
import 'package:cloudflared_tunnel_full/cloudflared_tunnel_full.dart';
```

or the compatibility entrypoint:

```dart
import 'package:cloudflared_tunnel_full/cloudflared_tunnel.dart';
```

The public Dart API exposes `CloudflaredTunnel`.