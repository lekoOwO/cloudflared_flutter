$ErrorActionPreference = 'Stop'

$pubspec = 'packages/cloudflared_tunnel_full/pubspec.yaml'
$content = Get-Content $pubspec -Raw

$content = $content -replace '(?s)\r?\ndependency_overrides:\r?\n  cloudflared_tunnel_android_arm:\r?\n    path: ../cloudflared_tunnel_android_arm\r?\n  cloudflared_tunnel_android_x86:\r?\n    path: ../cloudflared_tunnel_android_x86\r?\n?', ''
$content = $content.TrimEnd() + @"

dependency_overrides:
  cloudflared_tunnel_android_arm:
    path: ../cloudflared_tunnel_android_arm
  cloudflared_tunnel_android_x86:
    path: ../cloudflared_tunnel_android_x86
"@

Set-Content $pubspec $content -NoNewline
Write-Host 'Added local dependency overrides for split packages.'