$ErrorActionPreference = 'Stop'

$pubspec = 'packages/cloudflared_tunnel_full/pubspec.yaml'
$content = Get-Content $pubspec -Raw

$content = $content -replace 'cloudflared_tunnel_android_arm:\s*\^\S+', "cloudflared_tunnel_android_arm:`r`n    path: ../cloudflared_tunnel_android_arm"
$content = $content -replace 'cloudflared_tunnel_android_x86:\s*\^\S+', "cloudflared_tunnel_android_x86:`r`n    path: ../cloudflared_tunnel_android_x86"

Set-Content $pubspec $content -NoNewline
Write-Host 'Rewrote cloudflared_tunnel_full dependencies to local paths.'