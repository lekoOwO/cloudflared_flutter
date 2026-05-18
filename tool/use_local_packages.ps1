$ErrorActionPreference = 'Stop'

function Add-Overrides($pubspec, $armPath, $x86Path) {
  $content = Get-Content $pubspec -Raw
  $content = $content -replace '(?s)\r?\ndependency_overrides:\r?\n  cloudflared_tunnel_android_arm:\r?\n    path: .+?\r?\n  cloudflared_tunnel_android_x86:\r?\n    path: .+?\r?\n?', ''
  $content = $content.TrimEnd() + @"

dependency_overrides:
  cloudflared_tunnel_android_arm:
    path: $armPath
  cloudflared_tunnel_android_x86:
    path: $x86Path
"@
  Set-Content $pubspec $content -NoNewline
}

Add-Overrides 'packages/cloudflared_tunnel_full/pubspec.yaml' '../cloudflared_tunnel_android_arm' '../cloudflared_tunnel_android_x86'
Add-Overrides 'packages/cloudflared_tunnel_full/example/pubspec.yaml' '../../cloudflared_tunnel_android_arm' '../../cloudflared_tunnel_android_x86'

Write-Host 'Added local dependency overrides for split packages.'