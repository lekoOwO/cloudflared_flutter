# Legacy package location

The publishable packages now live under `packages/`.

Use `packages/cloudflared_tunnel_full` for the app-facing Flutter package. The old `flutter_plugin/cloudflared_tunnel` path is retained only as migration context and is marked `publish_to: none` to avoid accidental publication.