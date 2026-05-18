$ErrorActionPreference = 'Stop'

git checkout -- packages/cloudflared_tunnel_full/pubspec.yaml
Write-Host 'Restored package pubspec files from git.'