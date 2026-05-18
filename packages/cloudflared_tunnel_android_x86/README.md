# cloudflared_tunnel_android_x86

Android x86 sidecar package for `cloudflared_tunnel_full`.

This package is normally installed transitively by `cloudflared_tunnel_full`.
It contributes native libraries for:

- `x86_64`
- `x86`

It does not register Flutter method channels. The runtime Android implementation is provided by `cloudflared_tunnel_android_arm`.