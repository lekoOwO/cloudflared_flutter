$ErrorActionPreference = 'Stop'

$root = 'build/placeholders'
if (Test-Path $root) {
  Remove-Item $root -Recurse -Force
}
New-Item -ItemType Directory -Force $root | Out-Null

$packages = @(
  @{ Name = 'cloudflared_tunnel_full'; Description = 'Placeholder for the app-facing Cloudflare Tunnel Flutter plugin package.' },
  @{ Name = 'cloudflared_tunnel_android_arm'; Description = 'Placeholder for the Android ARM implementation package.' },
  @{ Name = 'cloudflared_tunnel_android_x86'; Description = 'Placeholder for the Android x86 sidecar package.' }
)

foreach ($pkg in $packages) {
  $dir = Join-Path $root $pkg.Name
  New-Item -ItemType Directory -Force (Join-Path $dir 'lib') | Out-Null

  @"
name: $($pkg.Name)
description: $($pkg.Description)
version: 0.0.1-dev.1
homepage: https://github.com/lekoOwO/cloudflared_flutter
repository: https://github.com/lekoOwO/cloudflared_flutter
issue_tracker: https://github.com/lekoOwO/cloudflared_flutter/issues

environment:
  sdk: ^3.0.0

"@ | Set-Content (Join-Path $dir 'pubspec.yaml') -NoNewline

  @"
# $($pkg.Name)

Placeholder package used to enable pub.dev automated publishing.

The full implementation starts at version `1.0.0`.
"@ | Set-Content (Join-Path $dir 'README.md') -NoNewline

  @"
# Changelog

## 0.0.1-dev.1

- Placeholder package used to enable pub.dev automated publishing.
"@ | Set-Content (Join-Path $dir 'CHANGELOG.md') -NoNewline

  @"
library $($pkg.Name);
"@ | Set-Content (Join-Path $dir "lib/$($pkg.Name).dart") -NoNewline

  Copy-Item 'flutter_plugin/cloudflared_tunnel/LICENSE' (Join-Path $dir 'LICENSE')
}

Write-Host "Created placeholder packages under $root"