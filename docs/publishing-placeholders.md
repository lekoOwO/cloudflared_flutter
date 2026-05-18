# Publishing placeholder packages

Run this only once, before enabling pub.dev GitHub Actions publishing for the three packages.

```powershell
powershell -ExecutionPolicy Bypass -File tool/create_placeholder_packages.ps1
```

For each generated package:

```powershell
cd build/placeholders/<package-name>
dart pub publish --dry-run
dart pub publish
```

Publish these versions:

- `cloudflared_tunnel_full` `0.0.1-dev.1`
- `cloudflared_tunnel_android_arm` `0.0.1-dev.1`
- `cloudflared_tunnel_android_x86` `0.0.1-dev.1`

After all three exist on pub.dev, open each package Admin page and enable GitHub Actions automated publishing with:

- Repository: `lekoOwO/cloudflared_flutter`
- Tag pattern: `cloudflared_tunnel-v{{version}}`
- Workflow file: `.github/workflows/publish.yml`