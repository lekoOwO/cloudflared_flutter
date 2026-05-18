$ErrorActionPreference = 'Stop'

git checkout -- packages/cloudflared_tunnel_full/pubspec.yaml packages/cloudflared_tunnel_full/example/pubspec.yaml
Write-Host 'Restored package pubspec files from git.'