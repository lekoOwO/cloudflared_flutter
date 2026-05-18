# cloudflared_tunnel 多套件分拆與發布設計

日期：2026-05-18  
目標 repo：`lekoOwO/cloudflared_flutter`  
主要套件：`cloudflared_tunnel_full`

## 背景

此 repository 是 `cloudflared_tunnel` 的 GitHub fork。原 package README 提到 Android 只支援 `arm64-v8a` 與 `armeabi-v7a`，未包含 `x86_64` 與 `x86`，導致 Android emulator 或特殊 x86 裝置支援不完整。

目前 repository 狀態：

- package 位於 `flutter_plugin/cloudflared_tunnel/`。
- 目前 `pubspec.yaml` package 名稱為 `cloudflared_tunnel`，版本為 `1.0.1`。
- Android native libraries 目前只包含：
  - `android/src/main/jniLibs/arm64-v8a/libgojni.so`
  - `android/src/main/jniLibs/armeabi-v7a/libgojni.so`
- repository 目前沒有 `.github/workflows/`。
- `mobile/` 內有 gomobile build script 與 Go wrapper。
- `cloudflared/` 是 `cloudflare/cloudflared` submodule。

## 目標

1. 發布新的 fork package，不覆蓋既有 `cloudflared_tunnel`。
2. 使用者只需依賴 `cloudflared_tunnel_full`，即可取得完整 Android ABI 支援。
3. Android ABI 初版完整支援：
   - `arm64-v8a`
   - `armeabi-v7a`
   - `x86_64`
   - `x86`
4. 避免單一 pub.dev package 因 native binaries 過大而接近或超過限制。
5. 建立 GitHub Actions build、dry-run 與 release publish 流程。
6. package 架構要能自然擴展到未來 Windows、Linux、macOS 支援。

## 非目標

- 不在本次設計內實作 Windows、Linux、macOS native 支援。
- 不改變既有 public Dart API class 名稱；仍保留 `CloudflaredTunnel`。
- 不重新設計 cloudflared Go wrapper 的功能行為。
- 不變更 Cloudflare tunnel token 取得方式。

## 已確認決策

### 新 package 名稱

採用平台明確命名：

1. `cloudflared_tunnel_full`
2. `cloudflared_tunnel_android_arm`
3. `cloudflared_tunnel_android_x86`

這三個名稱在 2026-05-18 透過 pub.dev API 查詢皆回傳 404，代表當下看起來尚未被佔用。

### 版本策略

placeholder 首版：

- `cloudflared_tunnel_full`: `0.0.1-dev.1`
- `cloudflared_tunnel_android_arm`: `0.0.1-dev.1`
- `cloudflared_tunnel_android_x86`: `0.0.1-dev.1`

正式完整 Android ABI 首版：

- `cloudflared_tunnel_full`: `1.0.0`
- `cloudflared_tunnel_android_arm`: `1.0.0`
- `cloudflared_tunnel_android_x86`: `1.0.0`

### 發布 tag

採用單一同步 tag 發布三個 package：

```text
cloudflared_tunnel-v{{version}}
```

正式 `1.0.0` 發布指令範例：

```bash
git tag cloudflared_tunnel-v1.0.0
git push origin cloudflared_tunnel-v1.0.0
```

### import 相容性

`cloudflared_tunnel_full` 同時支援：

```dart
import 'package:cloudflared_tunnel_full/cloudflared_tunnel_full.dart';
```

以及相容入口：

```dart
import 'package:cloudflared_tunnel_full/cloudflared_tunnel.dart';
```

README 與新文件主推 `cloudflared_tunnel_full.dart`。

### repository metadata

三個 package 的 pubspec metadata 改為 fork repository：

```yaml
homepage: https://github.com/lekoOwO/cloudflared_flutter
repository: https://github.com/lekoOwO/cloudflared_flutter
issue_tracker: https://github.com/lekoOwO/cloudflared_flutter/issues
documentation: https://github.com/lekoOwO/cloudflared_flutter/tree/main/packages/cloudflared_tunnel_full#readme
```

各 sidecar package 的 documentation 可以指向 monorepo 內對應 package README。

## Package 架構

採用三包架構，讓 `cloudflared_tunnel_full` 成為使用者-facing package，Android native binaries 由平台 package 提供。

### `cloudflared_tunnel_full`

用途：

- 使用者主要安裝與 import 的 package。
- 提供 Dart API 與 platform interface。
- 聚合 Android ARM 與 Android x86 sidecar packages。
- 未來可聚合 Windows、Linux、macOS packages。

內容：

- `lib/cloudflared_tunnel_full.dart`
- `lib/cloudflared_tunnel.dart`
- Dart API implementation。
- platform interface 與 MethodChannel Dart side。
- README、CHANGELOG、LICENSE。
- example app。

依賴：

```yaml
dependencies:
  flutter:
    sdk: flutter
  plugin_platform_interface: ^2.0.2
  cloudflared_tunnel_android_arm: ^1.0.0
  cloudflared_tunnel_android_x86: ^1.0.0
```

Flutter plugin declaration 中，Android default implementation 指向 `cloudflared_tunnel_android_arm`。`cloudflared_tunnel_android_x86` 作為 sidecar native package，透過 dependency 被納入 Android build。

### `cloudflared_tunnel_android_arm`

用途：

- Android 主要 runtime implementation。
- 負責註冊 Flutter MethodChannel / EventChannel。
- 負責 foreground service 與 notification permission 等 Android 行為。
- 提供 ARM ABI native libraries。

內容：

- 目前 `android/src/main/kotlin/com/cloudflare/cloudflared_tunnel/` 下的 Kotlin plugin 與 service。
- `android/libs/cloudflared-classes.jar`。
- `android/src/main/jniLibs/arm64-v8a/libgojni.so`。
- `android/src/main/jniLibs/armeabi-v7a/libgojni.so`。
- 最小 Dart entrypoint：`lib/cloudflared_tunnel_android_arm.dart`。

Android channel 名稱維持：

```text
com.cloudflare.cloudflared_tunnel/methods
com.cloudflare.cloudflared_tunnel/events
```

保留 channel 名稱可避免不必要的 Dart/native 介面破壞。

### `cloudflared_tunnel_android_x86`

用途：

- Android x86 native sidecar package。
- 只負責把 x86 native libraries 合併進 consuming app 的 Android build。
- 不註冊 MethodChannel 或 EventChannel，避免與 `cloudflared_tunnel_android_arm` 重複。

內容：

- `android/src/main/jniLibs/x86_64/libgojni.so`。
- `android/src/main/jniLibs/x86/libgojni.so`。
- 一個 no-op Android plugin class，讓 Flutter/Gradle 將此 package 視為 Android plugin module 並合併 `jniLibs`。
- 最小 Dart entrypoint：`lib/cloudflared_tunnel_android_x86.dart`。

no-op plugin 不應觸碰 tunnel lifecycle，不應註冊 channel，不應宣告 foreground service。

## 目標 repository 結構

```text
packages/
  cloudflared_tunnel_full/
    lib/
      cloudflared_tunnel_full.dart
      cloudflared_tunnel.dart
      src/
    example/
    pubspec.yaml
    README.md
    CHANGELOG.md
    LICENSE

  cloudflared_tunnel_android_arm/
    android/
      libs/cloudflared-classes.jar
      src/main/kotlin/com/cloudflare/cloudflared_tunnel/
      src/main/jniLibs/arm64-v8a/libgojni.so
      src/main/jniLibs/armeabi-v7a/libgojni.so
    lib/cloudflared_tunnel_android_arm.dart
    pubspec.yaml
    README.md
    CHANGELOG.md
    LICENSE

  cloudflared_tunnel_android_x86/
    android/
      src/main/kotlin/com/cloudflare/cloudflared_tunnel_android_x86/
      src/main/jniLibs/x86_64/libgojni.so
      src/main/jniLibs/x86/libgojni.so
    lib/cloudflared_tunnel_android_x86.dart
    pubspec.yaml
    README.md
    CHANGELOG.md
    LICENSE

mobile/
  build.sh
  cloudflared.go
  server.go
  go.mod
  go.sum

cloudflared/
  # git submodule

.github/workflows/
  build.yml
  publish.yml
```

原本的 `flutter_plugin/cloudflared_tunnel/` 可以在實作期間作為來源搬遷；完成後應避免同時保留兩份會混淆的可發布 package。若需要保留 legacy/reference，必須明確標註不再作為發布來源。

## Build 設計

### gomobile 輸出

CI 使用 gomobile build Android AAR，並產生四個 ABI：

- `arm64-v8a`
- `armeabi-v7a`
- `x86_64`
- `x86`

產物拆分：

- `classes.jar` 複製到 `cloudflared_tunnel_android_arm/android/libs/cloudflared-classes.jar`。
- ARM JNI libs 複製到 `cloudflared_tunnel_android_arm/android/src/main/jniLibs/`。
- x86 JNI libs 複製到 `cloudflared_tunnel_android_x86/android/src/main/jniLibs/`。

若 gomobile build 產物缺少任一 ABI，build workflow 必須失敗。

### package size guard

每個 package publish 前都要計算：

- dry-run package tarball gzip size。
- unpacked package size。

若任何 package 超過 pub.dev 文件所述限制或建議上限，workflow 應失敗並列出各 package size，不做自動降級。

## GitHub Actions 設計

### `build.yml`

觸發：

- Pull request。
- Push to `main`。
- Manual dispatch。

流程：

1. Checkout repository with submodules。
2. Setup Flutter。
3. Setup Go。
4. Install gomobile/gobind。
5. Run gomobile init。
6. Build Android AAR with all four ABI。
7. Split AAR outputs into `android_arm` 與 `android_x86` packages。
8. Run package validation：
   - `flutter pub get`
   - `flutter analyze`
   - `flutter test`
   - Android example assemble check
   - `dart pub publish --dry-run` for all three packages
9. Upload split package directories or package tarballs as artifacts。

### `publish.yml`

觸發：

- Tag：`cloudflared_tunnel-v*`
- Manual dispatch with version and dry-run controls。

必要權限：

```yaml
permissions:
  contents: read
  id-token: write
```

流程：

1. Parse version from tag or manual input。
2. Ensure version matches semantic version format。
3. Update three package `pubspec.yaml` versions。
4. Update `cloudflared_tunnel_full` dependencies to the same release line：
   - `cloudflared_tunnel_android_arm: ^<version>`
   - `cloudflared_tunnel_android_x86: ^<version>`
5. Build and split Android native outputs。
6. Run validation and publish dry-run for all packages。
7. If dry-run only, stop after reporting artifacts and validation results。
8. Publish order:
   1. `cloudflared_tunnel_android_arm`
   2. `cloudflared_tunnel_android_x86`
   3. Poll pub.dev API until both sidecar versions are visible.
   4. `cloudflared_tunnel_full`

The sidecar packages must be published first because `cloudflared_tunnel_full` depends on their published versions.

## pub.dev 首次發布流程

pub.dev automated publishing applies to existing packages, so each package must be created once before GitHub Actions OIDC publishing can be enabled.

Initial local placeholder publishing:

1. Create minimal `cloudflared_tunnel_full` package at `0.0.1-dev.1`.
2. Create minimal `cloudflared_tunnel_android_arm` package at `0.0.1-dev.1`.
3. Create minimal `cloudflared_tunnel_android_x86` package at `0.0.1-dev.1`.
4. Run `dart pub publish --dry-run` for each placeholder.
5. Publish each placeholder locally with `dart pub publish`.
6. Open each package Admin page on pub.dev.
7. Enable GitHub Actions automated publishing with:
   - Repository: `lekoOwO/cloudflared_flutter`
   - Tag pattern: `cloudflared_tunnel-v{{version}}`
   - Workflow file: `.github/workflows/publish.yml`

The placeholder packages should clearly state that the full implementation starts at `1.0.0`.

## Verification

Implementation is considered ready only after all of the following pass:

1. `flutter analyze` passes for all Dart packages that contain Dart logic.
2. `flutter test` passes for `cloudflared_tunnel_full`.
3. Android example assemble succeeds.
4. Built Android app contains:
   - `lib/arm64-v8a/libgojni.so`
   - `lib/armeabi-v7a/libgojni.so`
   - `lib/x86_64/libgojni.so`
   - `lib/x86/libgojni.so`
5. `dart pub publish --dry-run` passes for:
   - `cloudflared_tunnel_android_arm`
   - `cloudflared_tunnel_android_x86`
   - `cloudflared_tunnel_full`
6. GitHub Actions manual dry-run passes.
7. Release tag dry-run mode can build and stage all three packages.

## Risks and mitigations

### Risk: Sidecar x86 package may not merge `jniLibs`

Mitigation:

- Make `cloudflared_tunnel_android_x86` a valid Flutter Android plugin module with a no-op plugin class.
- Verify final APK/AAB contents in CI.

### Risk: `classes.jar` and native libraries drift apart

Mitigation:

- Build all ABI libraries from the same gomobile invocation in CI.
- Split outputs immediately after build.
- Publish ARM and x86 sidecar packages from the same workflow run and same version.

### Risk: pub.dev package visibility delay affects `full` publish

Mitigation:

- Publish sidecar packages first.
- Poll pub.dev API for the target sidecar versions before publishing `full`.
- Use bounded retries with clear failure messages.

### Risk: package size remains too large

Mitigation:

- Split ARM and x86 binaries into separate packages.
- Add explicit size reporting and guard in CI.
- If a sidecar package itself exceeds limits, fail the release and require a new packaging design.

### Risk: package naming becomes too Android-specific for future desktop support

Mitigation:

- Keep `cloudflared_tunnel_full` as the stable user-facing package.
- Use explicit platform package names such as `cloudflared_tunnel_windows`, `cloudflared_tunnel_linux`, and `cloudflared_tunnel_macos` for future additions.

## References

- Dart automated publishing: https://dart.dev/tools/pub/automated-publishing
- Dart publishing packages: https://dart.dev/tools/pub/publishing
- gomobile package documentation: https://pkg.go.dev/golang.org/x/mobile/cmd/gomobile
- Existing package page: https://pub.dev/packages/cloudflared_tunnel
