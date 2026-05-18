$ErrorActionPreference = 'Stop'

$pubspec = 'packages/cloudflared_tunnel_full/pubspec.yaml'
$content = Get-Content $pubspec -Raw

$content = $content -replace 'cloudflared_tunnel_android_arm: \^1\.0\.0', "cloudflared_tunnel_android_arm:`r`n    path: ../cloudflared_tunnel_android_arm"
$content = $content -replace 'cloudflared_tunnel_android_x86: \^1\.0\.0', "cloudflared_tunnel_android_x86:`r`n    path: ../cloudflared_tunnel_android_x86"

Set-Content $pubspec $content -NoNewline
Write-Host 'Rewrote cloudflared_tunnel_full dependencies to local paths.'