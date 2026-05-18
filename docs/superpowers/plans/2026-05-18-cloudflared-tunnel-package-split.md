# Cloudflared Tunnel Package Split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the fork into `cloudflared_tunnel_full`, `cloudflared_tunnel_android_arm`, and `cloudflared_tunnel_android_x86`, then add CI/release workflows that build Android ARM and x86 ABI packages from one gomobile build.

**Architecture:** `cloudflared_tunnel_full` is the app-facing federated plugin package that owns the Dart API and endorses `cloudflared_tunnel_android_arm` as its Android implementation. `cloudflared_tunnel_android_arm` owns the Android service/plugin implementation plus ARM JNI libraries. `cloudflared_tunnel_android_x86` is a transitive sidecar plugin with a no-op Android plugin class and only x86 JNI libraries.

**Tech Stack:** Flutter plugin packages, Dart package metadata, Kotlin Android plugin code, Gradle Android library modules, gomobile AAR output, GitHub Actions, pub.dev OIDC publishing.

---

## File structure map

- Create `packages/cloudflared_tunnel_full/`: app-facing Dart API package, tests, example, docs, and federated plugin endorsement.
- Create `packages/cloudflared_tunnel_android_arm/`: Android implementation package copied from the current plugin's Android directory plus minimal Dart entrypoint.
- Create `packages/cloudflared_tunnel_android_x86/`: no-op Android plugin package that contributes `x86` and `x86_64` JNI libraries.
- Create `tool/split_android_aar.sh`: extracts gomobile AAR output and distributes `classes.jar` and ABI libraries to the package directories.
- Create `tool/verify_android_abis.sh`: verifies a built APK/AAB or package tree contains all expected ABI libraries.
- Create `tool/create_placeholder_packages.ps1`: generates temporary minimal packages for first-time local pub.dev package creation.
- Create `.github/workflows/build.yml`: validates packages on PR/push/manual runs.
- Create `.github/workflows/publish.yml`: builds, validates, and publishes all three packages from a synchronized tag.
- Modify `mobile/build.sh`: keep it as the gomobile entrypoint, make Android builds explicit about all four supported ABI targets, and call the split script.
- Modify root `README.md`: document new package layout and release workflow.
- Leave `cloudflared/` submodule and `mobile/` Go sources in place.
- Remove or neutralize `flutter_plugin/cloudflared_tunnel/` after the new packages are in place to avoid two publishable copies.

---

### Task 1: Create an isolated implementation workspace

**Files:**
- No repository files modified in this task.

- [ ] **Step 1: Verify the current branch is clean**

Run:

```powershell
git status --short --branch
```

Expected:

```text
## main...origin/main [ahead 1]
```

There must be no uncommitted file entries. The branch may be ahead because the design and plan commits are local.

- [ ] **Step 2: Create the feature branch**

Run:

```powershell
git switch -c feature/package-split-publish
```

Expected:

```text
Switched to a new branch 'feature/package-split-publish'
```

- [ ] **Step 3: Commit checkpoint if the plan is not already committed**

Run:

```powershell
git status --short
```

Expected: no output. If `docs/superpowers/plans/2026-05-18-cloudflared-tunnel-package-split.md` appears as untracked or modified, run:

```powershell
git add docs/superpowers/plans/2026-05-18-cloudflared-tunnel-package-split.md
git commit -m "docs: add package split implementation plan"
```

Expected:

```text
[feature/package-split-publish ...] docs: add package split implementation plan
```

---

### Task 2: Add package directory skeletons and metadata

**Files:**
- Create: `packages/cloudflared_tunnel_full/pubspec.yaml`
- Create: `packages/cloudflared_tunnel_full/README.md`
- Create: `packages/cloudflared_tunnel_full/CHANGELOG.md`
- Copy: `packages/cloudflared_tunnel_full/LICENSE`
- Create: `packages/cloudflared_tunnel_android_arm/pubspec.yaml`
- Create: `packages/cloudflared_tunnel_android_arm/README.md`
- Create: `packages/cloudflared_tunnel_android_arm/CHANGELOG.md`
- Copy: `packages/cloudflared_tunnel_android_arm/LICENSE`
- Create: `packages/cloudflared_tunnel_android_x86/pubspec.yaml`
- Create: `packages/cloudflared_tunnel_android_x86/README.md`
- Create: `packages/cloudflared_tunnel_android_x86/CHANGELOG.md`
- Copy: `packages/cloudflared_tunnel_android_x86/LICENSE`

- [ ] **Step 1: Create directories**

Run:

```powershell
New-Item -ItemType Directory -Force `
  packages/cloudflared_tunnel_full/lib `
  packages/cloudflared_tunnel_full/test `
  packages/cloudflared_tunnel_android_arm/lib `
  packages/cloudflared_tunnel_android_arm/android `
  packages/cloudflared_tunnel_android_x86/lib `
  packages/cloudflared_tunnel_android_x86/android | Out-Null
```

Expected: command succeeds with no output.

- [ ] **Step 2: Copy the license to each package**

Run:

```powershell
Copy-Item flutter_plugin/cloudflared_tunnel/LICENSE packages/cloudflared_tunnel_full/LICENSE
Copy-Item flutter_plugin/cloudflared_tunnel/LICENSE packages/cloudflared_tunnel_android_arm/LICENSE
Copy-Item flutter_plugin/cloudflared_tunnel/LICENSE packages/cloudflared_tunnel_android_x86/LICENSE
```

Expected: command succeeds with no output.

- [ ] **Step 3: Create `cloudflared_tunnel_full/pubspec.yaml`**

Write this exact file:

```yaml
name: cloudflared_tunnel_full
description: Flutter plugin for Cloudflare Tunnel with full Android ABI support through split platform packages.
version: 1.0.0
homepage: https://github.com/lekoOwO/cloudflared_flutter
repository: https://github.com/lekoOwO/cloudflared_flutter
issue_tracker: https://github.com/lekoOwO/cloudflared_flutter/issues
documentation: https://github.com/lekoOwO/cloudflared_flutter/tree/main/packages/cloudflared_tunnel_full#readme

topics:
  - cloudflare
  - tunnel
  - networking
  - server
  - proxy

environment:
  sdk: ^3.0.0
  flutter: ">=3.3.0"

dependencies:
  flutter:
    sdk: flutter
  plugin_platform_interface: ^2.0.2
  cloudflared_tunnel_android_arm: ^1.0.0
  cloudflared_tunnel_android_x86: ^1.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  plugin:
    platforms:
      android:
        default_package: cloudflared_tunnel_android_arm
```

- [ ] **Step 4: Create `cloudflared_tunnel_android_arm/pubspec.yaml`**

Write this exact file:

```yaml
name: cloudflared_tunnel_android_arm
description: Android ARM implementation package for cloudflared_tunnel_full with arm64-v8a and armeabi-v7a native libraries.
version: 1.0.0
homepage: https://github.com/lekoOwO/cloudflared_flutter
repository: https://github.com/lekoOwO/cloudflared_flutter
issue_tracker: https://github.com/lekoOwO/cloudflared_flutter/issues
documentation: https://github.com/lekoOwO/cloudflared_flutter/tree/main/packages/cloudflared_tunnel_android_arm#readme

environment:
  sdk: ^3.0.0
  flutter: ">=3.3.0"

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_lints: ^5.0.0

flutter:
  plugin:
    implements: cloudflared_tunnel_full
    platforms:
      android:
        package: com.cloudflare.cloudflared_tunnel
        pluginClass: CloudflaredTunnelPlugin
        dartPluginClass: CloudflaredTunnelAndroidArm
```

- [ ] **Step 5: Create `cloudflared_tunnel_android_x86/pubspec.yaml`**

Write this exact file:

```yaml
name: cloudflared_tunnel_android_x86
description: Android x86 sidecar package for cloudflared_tunnel_full with x86 and x86_64 native libraries.
version: 1.0.0
homepage: https://github.com/lekoOwO/cloudflared_flutter
repository: https://github.com/lekoOwO/cloudflared_flutter
issue_tracker: https://github.com/lekoOwO/cloudflared_flutter/issues
documentation: https://github.com/lekoOwO/cloudflared_flutter/tree/main/packages/cloudflared_tunnel_android_x86#readme

environment:
  sdk: ^3.0.0
  flutter: ">=3.3.0"

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_lints: ^5.0.0

flutter:
  plugin:
    platforms:
      android:
        package: com.cloudflare.cloudflared_tunnel_android_x86
        pluginClass: CloudflaredTunnelAndroidX86Plugin
```

- [ ] **Step 6: Create package CHANGELOG files**

Write `packages/cloudflared_tunnel_full/CHANGELOG.md`:

```markdown
# Changelog

## 1.0.0

- Initial stable release of the split package architecture.
- Provides the public Dart API for Cloudflare Tunnel.
- Depends on Android ARM and Android x86 platform packages for full Android ABI support.

## 0.0.1-dev.1

- Placeholder package used to enable pub.dev automated publishing.
```

Write `packages/cloudflared_tunnel_android_arm/CHANGELOG.md`:

```markdown
# Changelog

## 1.0.0

- Initial Android ARM implementation package.
- Includes `arm64-v8a` and `armeabi-v7a` native libraries.

## 0.0.1-dev.1

- Placeholder package used to enable pub.dev automated publishing.
```

Write `packages/cloudflared_tunnel_android_x86/CHANGELOG.md`:

```markdown
# Changelog

## 1.0.0

- Initial Android x86 sidecar package.
- Includes `x86_64` and `x86` native libraries.

## 0.0.1-dev.1

- Placeholder package used to enable pub.dev automated publishing.
```

- [ ] **Step 7: Create package README files**

Write `packages/cloudflared_tunnel_full/README.md`:

```markdown
# cloudflared_tunnel_full

Flutter plugin for Cloudflare Tunnel with full Android ABI support through split platform packages.

## Android ABI support

This package depends on:

- `cloudflared_tunnel_android_arm` for `arm64-v8a` and `armeabi-v7a`
- `cloudflared_tunnel_android_x86` for `x86_64` and `x86`

Add only the app-facing package to your app:

```yaml
dependencies:
  cloudflared_tunnel_full: ^1.0.0
```

Use either import:

```dart
import 'package:cloudflared_tunnel_full/cloudflared_tunnel_full.dart';
```

or the compatibility entrypoint:

```dart
import 'package:cloudflared_tunnel_full/cloudflared_tunnel.dart';
```

The public Dart API exposes `CloudflaredTunnel`.
```

Write `packages/cloudflared_tunnel_android_arm/README.md`:

```markdown
# cloudflared_tunnel_android_arm

Android ARM implementation package for `cloudflared_tunnel_full`.

This package is normally installed transitively by `cloudflared_tunnel_full`.
It provides the Android plugin/service implementation and native libraries for:

- `arm64-v8a`
- `armeabi-v7a`

Most applications should depend on `cloudflared_tunnel_full` instead of this package directly.
```

Write `packages/cloudflared_tunnel_android_x86/README.md`:

```markdown
# cloudflared_tunnel_android_x86

Android x86 sidecar package for `cloudflared_tunnel_full`.

This package is normally installed transitively by `cloudflared_tunnel_full`.
It contributes native libraries for:

- `x86_64`
- `x86`

It does not register Flutter method channels. The runtime Android implementation is provided by `cloudflared_tunnel_android_arm`.
```

- [ ] **Step 8: Run pubspec parsing smoke checks**

Run:

```powershell
flutter pub get --directory packages/cloudflared_tunnel_android_arm
flutter pub get --directory packages/cloudflared_tunnel_android_x86
```

Expected: both commands finish with `Got dependencies!`.

Do not run `flutter pub get` for `cloudflared_tunnel_full` yet because its dependencies are local packages but the pubspec currently points to published versions. A later task will add CI-time path dependency rewriting.

- [ ] **Step 9: Commit package skeleton**

Run:

```powershell
git add packages
git commit -m "chore: add split package skeletons"
```

Expected:

```text
[feature/package-split-publish ...] chore: add split package skeletons
```

---

### Task 3: Move the Dart API into the app-facing package

**Files:**
- Copy/modify: `packages/cloudflared_tunnel_full/lib/cloudflared_tunnel.dart`
- Create: `packages/cloudflared_tunnel_full/lib/cloudflared_tunnel_full.dart`
- Copy/modify: `packages/cloudflared_tunnel_full/lib/cloudflared_tunnel_method_channel.dart`
- Copy/modify: `packages/cloudflared_tunnel_full/lib/cloudflared_tunnel_platform_interface.dart`
- Copy/modify: `packages/cloudflared_tunnel_full/test/cloudflared_tunnel_test.dart`
- Copy/modify: `packages/cloudflared_tunnel_full/test/cloudflared_tunnel_method_channel_test.dart`
- Copy/modify: `packages/cloudflared_tunnel_full/analysis_options.yaml`

- [ ] **Step 1: Copy Dart sources, tests, and analysis options**

Run:

```powershell
Copy-Item flutter_plugin/cloudflared_tunnel/lib/* packages/cloudflared_tunnel_full/lib/ -Recurse -Force
Copy-Item flutter_plugin/cloudflared_tunnel/test/* packages/cloudflared_tunnel_full/test/ -Recurse -Force
Copy-Item flutter_plugin/cloudflared_tunnel/analysis_options.yaml packages/cloudflared_tunnel_full/analysis_options.yaml
```

Expected: command succeeds with no output.

- [ ] **Step 2: Add the new app-facing export entrypoint**

Write `packages/cloudflared_tunnel_full/lib/cloudflared_tunnel_full.dart`:

```dart
/// App-facing entrypoint for the full Cloudflare Tunnel Flutter plugin.
///
/// This library exports the same public API as the compatibility
/// `cloudflared_tunnel.dart` entrypoint.
library cloudflared_tunnel_full;

export 'cloudflared_tunnel.dart';
```

- [ ] **Step 3: Update test imports to the new package name**

In `packages/cloudflared_tunnel_full/test/cloudflared_tunnel_test.dart`, replace:

```dart
import 'package:cloudflared_tunnel/cloudflared_tunnel.dart';
import 'package:cloudflared_tunnel/cloudflared_tunnel_platform_interface.dart';
import 'package:cloudflared_tunnel/cloudflared_tunnel_method_channel.dart';
```

with:

```dart
import 'package:cloudflared_tunnel_full/cloudflared_tunnel.dart';
import 'package:cloudflared_tunnel_full/cloudflared_tunnel_platform_interface.dart';
import 'package:cloudflared_tunnel_full/cloudflared_tunnel_method_channel.dart';
```

In `packages/cloudflared_tunnel_full/test/cloudflared_tunnel_method_channel_test.dart`, replace:

```dart
import 'package:cloudflared_tunnel/cloudflared_tunnel_method_channel.dart';
```

with:

```dart
import 'package:cloudflared_tunnel_full/cloudflared_tunnel_method_channel.dart';
```

- [ ] **Step 4: Fix the method channel test channel name**

In `packages/cloudflared_tunnel_full/test/cloudflared_tunnel_method_channel_test.dart`, replace:

```dart
const MethodChannel channel = MethodChannel('cloudflared_tunnel');
```

with:

```dart
const MethodChannel channel =
    MethodChannel('com.cloudflare.cloudflared_tunnel/methods');
```

Expected: the test intercepts the same channel used by `MethodChannelCloudflaredTunnel`.

- [ ] **Step 5: Add a full entrypoint export test**

Append this test to `packages/cloudflared_tunnel_full/test/cloudflared_tunnel_test.dart`:

```dart
test('cloudflared_tunnel_full entrypoint exports CloudflaredTunnel', () {
  expect(CloudflaredTunnel, isNotNull);
});
```

Expected: analyzer can resolve `CloudflaredTunnel` through the compatibility import. The new entrypoint is validated by the analyzer in a later task.

- [ ] **Step 6: Format and test the app-facing Dart package**

Temporarily rewrite local dependencies for the test run:

```powershell
(Get-Content packages/cloudflared_tunnel_full/pubspec.yaml) `
  -replace 'cloudflared_tunnel_android_arm: \\^1.0.0', "cloudflared_tunnel_android_arm:`n    path: ../cloudflared_tunnel_android_arm" `
  -replace 'cloudflared_tunnel_android_x86: \\^1.0.0', "cloudflared_tunnel_android_x86:`n    path: ../cloudflared_tunnel_android_x86" |
  Set-Content packages/cloudflared_tunnel_full/pubspec.yaml
dart format packages/cloudflared_tunnel_full/lib packages/cloudflared_tunnel_full/test
flutter pub get --directory packages/cloudflared_tunnel_full
flutter test packages/cloudflared_tunnel_full
```

Expected:

```text
All tests passed!
```

- [ ] **Step 7: Restore published dependency constraints**

Run:

```powershell
git checkout -- packages/cloudflared_tunnel_full/pubspec.yaml
```

Expected: `pubspec.yaml` returns to `cloudflared_tunnel_android_arm: ^1.0.0` and `cloudflared_tunnel_android_x86: ^1.0.0`.

- [ ] **Step 8: Commit the app-facing Dart package**

Run:

```powershell
git add packages/cloudflared_tunnel_full
git commit -m "feat: add app-facing full package"
```

Expected:

```text
[feature/package-split-publish ...] feat: add app-facing full package
```

---

### Task 4: Create the Android ARM implementation package

**Files:**
- Copy/modify: `packages/cloudflared_tunnel_android_arm/android/`
- Create: `packages/cloudflared_tunnel_android_arm/lib/cloudflared_tunnel_android_arm.dart`
- Create: `packages/cloudflared_tunnel_android_arm/analysis_options.yaml`

- [ ] **Step 1: Copy the existing Android implementation**

Run:

```powershell
Copy-Item flutter_plugin/cloudflared_tunnel/android/* packages/cloudflared_tunnel_android_arm/android/ -Recurse -Force
```

Expected: command succeeds with no output.

- [ ] **Step 2: Remove non-ARM JNI directories if present**

Run:

```powershell
Remove-Item packages/cloudflared_tunnel_android_arm/android/src/main/jniLibs/x86 -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item packages/cloudflared_tunnel_android_arm/android/src/main/jniLibs/x86_64 -Recurse -Force -ErrorAction SilentlyContinue
```

Expected: command succeeds with no output.

- [ ] **Step 3: Create the Dart plugin registration class**

Write `packages/cloudflared_tunnel_android_arm/lib/cloudflared_tunnel_android_arm.dart`:

```dart
import 'package:flutter/services.dart';

/// Dart-side registration hook for the Android ARM implementation package.
///
/// The native Android plugin owns the actual MethodChannel and EventChannel
/// handling. This class exists so the package can be endorsed as a federated
/// Android implementation by `cloudflared_tunnel_full`.
class CloudflaredTunnelAndroidArm {
  static void registerWith() {
    const MethodChannel('com.cloudflare.cloudflared_tunnel/methods');
  }
}
```

- [ ] **Step 4: Create analysis options**

Write `packages/cloudflared_tunnel_android_arm/analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    public_member_api_docs: false
```

- [ ] **Step 5: Validate expected ARM native files**

Run:

```powershell
Test-Path packages/cloudflared_tunnel_android_arm/android/src/main/jniLibs/arm64-v8a/libgojni.so
Test-Path packages/cloudflared_tunnel_android_arm/android/src/main/jniLibs/armeabi-v7a/libgojni.so
Test-Path packages/cloudflared_tunnel_android_arm/android/libs/cloudflared-classes.jar
```

Expected:

```text
True
True
True
```

- [ ] **Step 6: Run dependency and analysis checks**

Run:

```powershell
dart format packages/cloudflared_tunnel_android_arm/lib
flutter pub get --directory packages/cloudflared_tunnel_android_arm
flutter analyze packages/cloudflared_tunnel_android_arm
```

Expected: `flutter analyze` reports `No issues found!`.

- [ ] **Step 7: Commit the ARM implementation package**

Run:

```powershell
git add packages/cloudflared_tunnel_android_arm
git commit -m "feat: add Android ARM implementation package"
```

Expected:

```text
[feature/package-split-publish ...] feat: add Android ARM implementation package
```

---

### Task 5: Create the Android x86 sidecar package

**Files:**
- Create: `packages/cloudflared_tunnel_android_x86/android/build.gradle`
- Create: `packages/cloudflared_tunnel_android_x86/android/settings.gradle`
- Create: `packages/cloudflared_tunnel_android_x86/android/src/main/AndroidManifest.xml`
- Create: `packages/cloudflared_tunnel_android_x86/android/src/main/kotlin/com/cloudflare/cloudflared_tunnel_android_x86/CloudflaredTunnelAndroidX86Plugin.kt`
- Create: `packages/cloudflared_tunnel_android_x86/lib/cloudflared_tunnel_android_x86.dart`
- Create: `packages/cloudflared_tunnel_android_x86/analysis_options.yaml`

- [ ] **Step 1: Create Android source directories**

Run:

```powershell
New-Item -ItemType Directory -Force `
  packages/cloudflared_tunnel_android_x86/android/src/main/kotlin/com/cloudflare/cloudflared_tunnel_android_x86 `
  packages/cloudflared_tunnel_android_x86/android/src/main/jniLibs/x86 `
  packages/cloudflared_tunnel_android_x86/android/src/main/jniLibs/x86_64 | Out-Null
```

Expected: command succeeds with no output.

- [ ] **Step 2: Create x86 Android Gradle files**

Write `packages/cloudflared_tunnel_android_x86/android/settings.gradle`:

```gradle
rootProject.name = 'cloudflared_tunnel_android_x86'
```

Write `packages/cloudflared_tunnel_android_x86/android/build.gradle`:

```gradle
group = "com.cloudflare.cloudflared_tunnel_android_x86"
version = "1.0-SNAPSHOT"

buildscript {
    ext.kotlin_version = "1.8.22"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.7.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

apply plugin: "com.android.library"
apply plugin: "kotlin-android"

android {
    namespace = "com.cloudflare.cloudflared_tunnel_android_x86"

    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11
    }

    sourceSets {
        main.java.srcDirs += "src/main/kotlin"
    }

    defaultConfig {
        minSdk = 21
    }
}
```

- [ ] **Step 3: Create x86 manifest**

Write `packages/cloudflared_tunnel_android_x86/android/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.cloudflare.cloudflared_tunnel_android_x86" />
```

- [ ] **Step 4: Create the no-op native plugin**

Write `packages/cloudflared_tunnel_android_x86/android/src/main/kotlin/com/cloudflare/cloudflared_tunnel_android_x86/CloudflaredTunnelAndroidX86Plugin.kt`:

```kotlin
package com.cloudflare.cloudflared_tunnel_android_x86

import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * No-op Flutter plugin used only to make Flutter/Gradle include this package's
 * x86 and x86_64 JNI libraries in Android builds.
 */
class CloudflaredTunnelAndroidX86Plugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) = Unit

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) = Unit
}
```

- [ ] **Step 5: Create the Dart sidecar entrypoint**

Write `packages/cloudflared_tunnel_android_x86/lib/cloudflared_tunnel_android_x86.dart`:

```dart
/// Android x86 sidecar package for cloudflared_tunnel_full.
///
/// This package contributes x86 and x86_64 JNI libraries to Android builds.
/// It intentionally exposes no runtime Dart API.
library cloudflared_tunnel_android_x86;
```

- [ ] **Step 6: Create analysis options**

Write `packages/cloudflared_tunnel_android_x86/analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    public_member_api_docs: false
```

- [ ] **Step 7: Add temporary x86 libraries for local verification**

Until the all-ABI gomobile build is available locally, copy the ARM libraries only for structure checks is not allowed because wrong-architecture binaries would be misleading. Instead create an empty marker file and make the later split task responsible for replacing it with real libraries:

```powershell
New-Item -ItemType File -Force packages/cloudflared_tunnel_android_x86/android/src/main/jniLibs/.gitkeep | Out-Null
```

Expected: command succeeds with no output.

- [ ] **Step 8: Run dependency and analysis checks**

Run:

```powershell
dart format packages/cloudflared_tunnel_android_x86/lib
flutter pub get --directory packages/cloudflared_tunnel_android_x86
flutter analyze packages/cloudflared_tunnel_android_x86
```

Expected: `flutter analyze` reports `No issues found!`.

- [ ] **Step 9: Commit the x86 sidecar package**

Run:

```powershell
git add packages/cloudflared_tunnel_android_x86
git commit -m "feat: add Android x86 sidecar package"
```

Expected:

```text
[feature/package-split-publish ...] feat: add Android x86 sidecar package
```

---

### Task 6: Add AAR split and ABI verification tooling

**Files:**
- Create: `tool/split_android_aar.sh`
- Create: `tool/verify_android_abis.sh`
- Modify: `mobile/build.sh`

- [ ] **Step 1: Create the AAR split script**

Write `tool/split_android_aar.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 path/to/cloudflared.aar" >&2
  exit 64
fi

aar_file="$1"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
arm_pkg="$repo_root/packages/cloudflared_tunnel_android_arm/android"
x86_pkg="$repo_root/packages/cloudflared_tunnel_android_x86/android"

if [[ ! -f "$aar_file" ]]; then
  echo "AAR not found: $aar_file" >&2
  exit 66
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

unzip -q "$aar_file" -d "$tmp_dir"

required_files=(
  "classes.jar"
  "jni/arm64-v8a/libgojni.so"
  "jni/armeabi-v7a/libgojni.so"
  "jni/x86_64/libgojni.so"
  "jni/x86/libgojni.so"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "$tmp_dir/$file" ]]; then
    echo "Missing expected AAR entry: $file" >&2
    exit 65
  fi
done

rm -rf "$arm_pkg/libs" "$arm_pkg/src/main/jniLibs"
mkdir -p "$arm_pkg/libs" "$arm_pkg/src/main/jniLibs"
cp "$tmp_dir/classes.jar" "$arm_pkg/libs/cloudflared-classes.jar"
mkdir -p "$arm_pkg/src/main/jniLibs/arm64-v8a" "$arm_pkg/src/main/jniLibs/armeabi-v7a"
cp "$tmp_dir/jni/arm64-v8a/libgojni.so" "$arm_pkg/src/main/jniLibs/arm64-v8a/libgojni.so"
cp "$tmp_dir/jni/armeabi-v7a/libgojni.so" "$arm_pkg/src/main/jniLibs/armeabi-v7a/libgojni.so"

rm -rf "$x86_pkg/src/main/jniLibs"
mkdir -p "$x86_pkg/src/main/jniLibs/x86_64" "$x86_pkg/src/main/jniLibs/x86"
cp "$tmp_dir/jni/x86_64/libgojni.so" "$x86_pkg/src/main/jniLibs/x86_64/libgojni.so"
cp "$tmp_dir/jni/x86/libgojni.so" "$x86_pkg/src/main/jniLibs/x86/libgojni.so"

echo "Split Android AAR into:"
echo "  $arm_pkg"
echo "  $x86_pkg"
```

- [ ] **Step 2: Create the ABI verification script**

Write `tool/verify_android_abis.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

root="${1:-packages}"

required=(
  "arm64-v8a/libgojni.so"
  "armeabi-v7a/libgojni.so"
  "x86_64/libgojni.so"
  "x86/libgojni.so"
)

for abi_file in "${required[@]}"; do
  if ! find "$root" -path "*/$abi_file" -type f | grep -q .; then
    echo "Missing Android ABI library: $abi_file under $root" >&2
    exit 65
  fi
done

echo "Verified Android ABI libraries under $root"
```

- [ ] **Step 3: Update `mobile/build.sh` Android target and split behavior**

In `mobile/build.sh`, replace the Android gomobile invocation:

```bash
gomobile bind -v \
    -target=android \
    -androidapi=21 \
    -o "$BUILD_DIR/cloudflared.aar" \
    -ldflags="-s -w" \
    .
```

with:

```bash
gomobile bind -v \
    -target=android/arm,android/arm64,android/386,android/amd64 \
    -androidapi=21 \
    -o "$BUILD_DIR/cloudflared.aar" \
    -ldflags="-s -w" \
    .
```

Then replace the success block:

```bash
# Extract AAR for Flutter plugin
extract_aar_for_flutter
```

with:

```bash
# Extract AAR for split Flutter packages
"$PROJECT_ROOT/tool/split_android_aar.sh" "$BUILD_DIR/cloudflared.aar"
```

Leave `extract_aar_for_flutter` in place for now only if other callers still use it; otherwise remove it in a cleanup task.

- [ ] **Step 4: Make scripts executable in git**

Run:

```powershell
git update-index --chmod=+x tool/split_android_aar.sh tool/verify_android_abis.sh
```

Expected: command succeeds with no output.

- [ ] **Step 5: Verify existing package ABI structure**

Run:

```powershell
bash tool/verify_android_abis.sh packages
```

Expected before a real all-ABI build: this may fail because x86 libraries are not built yet. The expected failure text is:

```text
Missing Android ABI library: x86_64/libgojni.so under packages
```

This failure is acceptable before the CI all-ABI build. It must pass after `mobile/build.sh android` runs in CI.

- [ ] **Step 6: Commit build tooling**

Run:

```powershell
git add tool mobile/build.sh
git commit -m "build: split Android gomobile outputs by ABI"
```

Expected:

```text
[feature/package-split-publish ...] build: split Android gomobile outputs by ABI
```

---

### Task 7: Move the example app to the app-facing package

**Files:**
- Copy/modify: `packages/cloudflared_tunnel_full/example/`

- [ ] **Step 1: Copy the existing example**

Run:

```powershell
Copy-Item flutter_plugin/cloudflared_tunnel/example packages/cloudflared_tunnel_full/example -Recurse -Force
```

Expected: command succeeds with no output.

- [ ] **Step 2: Update example dependency**

In `packages/cloudflared_tunnel_full/example/pubspec.yaml`, replace:

```yaml
  cloudflared_tunnel:
    path: ../
```

with:

```yaml
  cloudflared_tunnel_full:
    path: ../
```

- [ ] **Step 3: Update example Dart imports**

Run:

```powershell
Get-ChildItem packages/cloudflared_tunnel_full/example/lib -Recurse -Filter *.dart |
  ForEach-Object {
    (Get-Content $_.FullName) -replace "package:cloudflared_tunnel/cloudflared_tunnel.dart", "package:cloudflared_tunnel_full/cloudflared_tunnel_full.dart" |
      Set-Content $_.FullName
  }
Get-ChildItem packages/cloudflared_tunnel_full/example/test -Recurse -Filter *.dart |
  ForEach-Object {
    (Get-Content $_.FullName) -replace "package:cloudflared_tunnel_example", "package:cloudflared_tunnel_full_example" |
      Set-Content $_.FullName
  }
```

Expected: command succeeds with no output.

- [ ] **Step 4: Rename example package**

In `packages/cloudflared_tunnel_full/example/pubspec.yaml`, replace:

```yaml
name: cloudflared_tunnel_example
```

with:

```yaml
name: cloudflared_tunnel_full_example
```

- [ ] **Step 5: Get dependencies and analyze the example**

Before running this locally, temporarily rewrite `cloudflared_tunnel_full` dependencies to local paths as in Task 3 Step 6. Then run:

```powershell
flutter pub get --directory packages/cloudflared_tunnel_full/example
flutter analyze packages/cloudflared_tunnel_full/example
```

Expected: `flutter analyze` reports no errors. Warnings from generated template files should be fixed rather than ignored.

- [ ] **Step 6: Restore published dependency constraints**

Run:

```powershell
git checkout -- packages/cloudflared_tunnel_full/pubspec.yaml
```

Expected: the full package pubspec points to published sidecar versions again.

- [ ] **Step 7: Commit the moved example**

Run:

```powershell
git add packages/cloudflared_tunnel_full/example
git commit -m "chore: move example to full package"
```

Expected:

```text
[feature/package-split-publish ...] chore: move example to full package
```

---

### Task 8: Add local path dependency rewrite tooling

**Files:**
- Create: `tool/use_local_packages.ps1`
- Create: `tool/restore_pubspecs.ps1`

- [ ] **Step 1: Create local dependency rewrite script**

Write `tool/use_local_packages.ps1`:

```powershell
$ErrorActionPreference = 'Stop'

$pubspec = 'packages/cloudflared_tunnel_full/pubspec.yaml'
$content = Get-Content $pubspec -Raw

$content = $content -replace 'cloudflared_tunnel_android_arm: \^1\.0\.0', "cloudflared_tunnel_android_arm:`r`n    path: ../cloudflared_tunnel_android_arm"
$content = $content -replace 'cloudflared_tunnel_android_x86: \^1\.0\.0', "cloudflared_tunnel_android_x86:`r`n    path: ../cloudflared_tunnel_android_x86"

Set-Content $pubspec $content -NoNewline
Write-Host 'Rewrote cloudflared_tunnel_full dependencies to local paths.'
```

- [ ] **Step 2: Create restore script**

Write `tool/restore_pubspecs.ps1`:

```powershell
$ErrorActionPreference = 'Stop'

git checkout -- packages/cloudflared_tunnel_full/pubspec.yaml
Write-Host 'Restored package pubspec files from git.'
```

- [ ] **Step 3: Test local rewrite and restore**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tool/use_local_packages.ps1
Select-String -Path packages/cloudflared_tunnel_full/pubspec.yaml -Pattern 'path: ../cloudflared_tunnel_android_arm'
powershell -ExecutionPolicy Bypass -File tool/restore_pubspecs.ps1
Select-String -Path packages/cloudflared_tunnel_full/pubspec.yaml -Pattern 'cloudflared_tunnel_android_arm: \\^1.0.0'
```

Expected: both `Select-String` calls return one matching line.

- [ ] **Step 4: Commit dependency rewrite tooling**

Run:

```powershell
git add tool/use_local_packages.ps1 tool/restore_pubspecs.ps1
git commit -m "build: add local package dependency tooling"
```

Expected:

```text
[feature/package-split-publish ...] build: add local package dependency tooling
```

---

### Task 9: Add placeholder package generation tooling

**Files:**
- Create: `tool/create_placeholder_packages.ps1`
- Create: `docs/publishing-placeholders.md`

- [ ] **Step 1: Create placeholder generation script**

Write `tool/create_placeholder_packages.ps1`:

```powershell
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
```

- [ ] **Step 2: Create placeholder publishing instructions**

Write `docs/publishing-placeholders.md`:

```markdown
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
```

- [ ] **Step 3: Generate placeholders and dry-run locally**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tool/create_placeholder_packages.ps1
Get-ChildItem build/placeholders
```

Expected: output lists:

```text
cloudflared_tunnel_android_arm
cloudflared_tunnel_android_x86
cloudflared_tunnel_full
```

Run at least one dry-run:

```powershell
dart pub publish --dry-run --directory build/placeholders/cloudflared_tunnel_full
```

Expected: dry-run succeeds or reports only account/login warnings that require interactive publishing.

- [ ] **Step 4: Commit placeholder tooling**

Run:

```powershell
git add tool/create_placeholder_packages.ps1 docs/publishing-placeholders.md
git commit -m "docs: add placeholder publishing workflow"
```

Expected:

```text
[feature/package-split-publish ...] docs: add placeholder publishing workflow
```

---

### Task 10: Add GitHub Actions build workflow

**Files:**
- Create: `.github/workflows/build.yml`

- [ ] **Step 1: Create build workflow**

Write `.github/workflows/build.yml`:

```yaml
name: Build

on:
  pull_request:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version-file: mobile/go.mod
          cache-dependency-path: mobile/go.sum

      - name: Install gomobile
        run: |
          go install golang.org/x/mobile/cmd/gomobile@latest
          go install golang.org/x/mobile/cmd/gobind@latest
          gomobile init

      - name: Build Android libraries
        run: |
          cd mobile
          ./build.sh android

      - name: Verify ABI split
        run: bash tool/verify_android_abis.sh packages

      - name: Use local package dependencies
        shell: pwsh
        run: ./tool/use_local_packages.ps1

      - name: Get dependencies
        run: |
          flutter pub get --directory packages/cloudflared_tunnel_android_arm
          flutter pub get --directory packages/cloudflared_tunnel_android_x86
          flutter pub get --directory packages/cloudflared_tunnel_full
          flutter pub get --directory packages/cloudflared_tunnel_full/example

      - name: Analyze
        run: |
          flutter analyze packages/cloudflared_tunnel_android_arm
          flutter analyze packages/cloudflared_tunnel_android_x86
          flutter analyze packages/cloudflared_tunnel_full
          flutter analyze packages/cloudflared_tunnel_full/example

      - name: Test
        run: flutter test packages/cloudflared_tunnel_full

      - name: Build Android example
        run: |
          cd packages/cloudflared_tunnel_full/example
          flutter build apk --debug

      - name: Restore publish pubspecs
        shell: pwsh
        run: ./tool/restore_pubspecs.ps1

      - name: Publish dry-run sidecar packages
        run: |
          dart pub publish --dry-run --directory packages/cloudflared_tunnel_android_arm
          dart pub publish --dry-run --directory packages/cloudflared_tunnel_android_x86

      - name: Publish dry-run full package with local dependency override
        shell: pwsh
        run: |
          ./tool/use_local_packages.ps1
          dart pub publish --dry-run --directory packages/cloudflared_tunnel_full

      - name: Upload Android package artifacts
        uses: actions/upload-artifact@v4
        with:
          name: split-packages
          path: |
            packages/cloudflared_tunnel_android_arm
            packages/cloudflared_tunnel_android_x86
            packages/cloudflared_tunnel_full
```

- [ ] **Step 2: Commit build workflow**

Run:

```powershell
git add .github/workflows/build.yml
git commit -m "ci: add split package build workflow"
```

Expected:

```text
[feature/package-split-publish ...] ci: add split package build workflow
```

---

### Task 11: Add GitHub Actions publish workflow

**Files:**
- Create: `.github/workflows/publish.yml`

- [ ] **Step 1: Create publish workflow**

Write `.github/workflows/publish.yml`:

```yaml
name: Publish

on:
  push:
    tags:
      - "cloudflared_tunnel-v*"
  workflow_dispatch:
    inputs:
      version:
        description: "Version to publish, for example 1.0.0"
        required: true
        type: string
      dry_run:
        description: "Run validation without publishing"
        required: true
        default: true
        type: boolean

permissions:
  contents: read
  id-token: write

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Resolve version
        id: version
        shell: bash
        run: |
          if [[ "${{ github.event_name }}" == "workflow_dispatch" ]]; then
            version="${{ inputs.version }}"
          else
            tag="${GITHUB_REF_NAME}"
            version="${tag#cloudflared_tunnel-v}"
          fi
          if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
            echo "Invalid version: $version" >&2
            exit 64
          fi
          echo "version=$version" >> "$GITHUB_OUTPUT"

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version-file: mobile/go.mod
          cache-dependency-path: mobile/go.sum

      - name: Install gomobile
        run: |
          go install golang.org/x/mobile/cmd/gomobile@latest
          go install golang.org/x/mobile/cmd/gobind@latest
          gomobile init

      - name: Stamp package versions
        shell: pwsh
        run: |
          $version = '${{ steps.version.outputs.version }}'
          $pubspecs = @(
            'packages/cloudflared_tunnel_android_arm/pubspec.yaml',
            'packages/cloudflared_tunnel_android_x86/pubspec.yaml',
            'packages/cloudflared_tunnel_full/pubspec.yaml'
          )
          foreach ($file in $pubspecs) {
            $content = Get-Content $file -Raw
            $content = $content -replace 'version: .+', "version: $version"
            Set-Content $file $content -NoNewline
          }
          $full = 'packages/cloudflared_tunnel_full/pubspec.yaml'
          $content = Get-Content $full -Raw
          $content = $content -replace 'cloudflared_tunnel_android_arm: \^.+', "cloudflared_tunnel_android_arm: ^$version"
          $content = $content -replace 'cloudflared_tunnel_android_x86: \^.+', "cloudflared_tunnel_android_x86: ^$version"
          Set-Content $full $content -NoNewline

      - name: Build Android libraries
        run: |
          cd mobile
          ./build.sh android

      - name: Verify ABI split
        run: bash tool/verify_android_abis.sh packages

      - name: Validate packages locally
        shell: pwsh
        run: |
          ./tool/use_local_packages.ps1
          flutter pub get --directory packages/cloudflared_tunnel_android_arm
          flutter pub get --directory packages/cloudflared_tunnel_android_x86
          flutter pub get --directory packages/cloudflared_tunnel_full
          flutter pub get --directory packages/cloudflared_tunnel_full/example
          flutter analyze packages/cloudflared_tunnel_android_arm
          flutter analyze packages/cloudflared_tunnel_android_x86
          flutter analyze packages/cloudflared_tunnel_full
          flutter test packages/cloudflared_tunnel_full
          ./tool/restore_pubspecs.ps1

      - name: Publish dry-run
        run: |
          dart pub publish --dry-run --directory packages/cloudflared_tunnel_android_arm
          dart pub publish --dry-run --directory packages/cloudflared_tunnel_android_x86
          dart pub publish --dry-run --directory packages/cloudflared_tunnel_full

      - name: Stop after dry run
        if: ${{ github.event_name == 'workflow_dispatch' && inputs.dry_run }}
        run: echo "Dry run complete."

      - name: Publish Android ARM package
        if: ${{ github.event_name != 'workflow_dispatch' || !inputs.dry_run }}
        run: dart pub publish --force --directory packages/cloudflared_tunnel_android_arm

      - name: Publish Android x86 package
        if: ${{ github.event_name != 'workflow_dispatch' || !inputs.dry_run }}
        run: dart pub publish --force --directory packages/cloudflared_tunnel_android_x86

      - name: Wait for sidecar packages
        if: ${{ github.event_name != 'workflow_dispatch' || !inputs.dry_run }}
        shell: bash
        run: |
          version="${{ steps.version.outputs.version }}"
          for package in cloudflared_tunnel_android_arm cloudflared_tunnel_android_x86; do
            echo "Waiting for $package $version on pub.dev"
            for attempt in {1..30}; do
              if curl -fsSL "https://pub.dev/api/packages/$package" | grep -q "\"version\":\"$version\""; then
                echo "$package $version is visible"
                break
              fi
              if [[ "$attempt" == "30" ]]; then
                echo "$package $version did not become visible on pub.dev" >&2
                exit 75
              fi
              sleep 10
            done
          done

      - name: Publish full package
        if: ${{ github.event_name != 'workflow_dispatch' || !inputs.dry_run }}
        run: dart pub publish --force --directory packages/cloudflared_tunnel_full
```

- [ ] **Step 2: Commit publish workflow**

Run:

```powershell
git add .github/workflows/publish.yml
git commit -m "ci: add synchronized package publish workflow"
```

Expected:

```text
[feature/package-split-publish ...] ci: add synchronized package publish workflow
```

---

### Task 12: Update root documentation and neutralize the legacy package path

**Files:**
- Modify: `README.md`
- Create: `flutter_plugin/README.md`
- Optional delete after validation: `flutter_plugin/cloudflared_tunnel/`

- [ ] **Step 1: Replace the root README package sections**

Rewrite the Project Structure and Build sections in `README.md` so they describe:

```markdown
## Project Structure

```text
cloudflared_flutter/
├── cloudflared/                       # Git submodule from cloudflare/cloudflared
├── mobile/                            # Go wrapper for gomobile bindings
├── packages/
│   ├── cloudflared_tunnel_full/       # App-facing Dart API package
│   ├── cloudflared_tunnel_android_arm/# Android implementation + ARM JNI libs
│   └── cloudflared_tunnel_android_x86/# Android x86 sidecar JNI libs
└── tool/                              # Build and publishing helper scripts
```

## Packages

- `cloudflared_tunnel_full`: install this package in Flutter apps.
- `cloudflared_tunnel_android_arm`: Android ARM implementation package.
- `cloudflared_tunnel_android_x86`: Android x86 sidecar package.

## Build Android libraries

```bash
git submodule update --init --recursive
cd mobile
./build.sh android
```

The build creates a gomobile AAR and splits it into the Android ARM and x86 package directories.
```

Keep the existing usage examples, but change the import to:

```dart
import 'package:cloudflared_tunnel_full/cloudflared_tunnel_full.dart';
```

- [ ] **Step 2: Add a legacy path notice**

Write `flutter_plugin/README.md`:

```markdown
# Legacy package location

The publishable packages now live under `packages/`.

Use `packages/cloudflared_tunnel_full` for the app-facing Flutter package.
The old `flutter_plugin/cloudflared_tunnel` path is retained only as migration context until cleanup is complete.
```

- [ ] **Step 3: Decide whether to remove the old plugin directory**

If all tests and example builds pass from `packages/`, remove the old publishable package to avoid accidental publication:

```powershell
Remove-Item flutter_plugin/cloudflared_tunnel -Recurse -Force
```

If removing it causes loss of needed files, keep it for this branch and ensure root README clearly states it is legacy only.

- [ ] **Step 4: Commit documentation and legacy cleanup**

Run:

```powershell
git add README.md flutter_plugin
git commit -m "docs: document split package layout"
```

Expected:

```text
[feature/package-split-publish ...] docs: document split package layout
```

---

### Task 13: Final local validation

**Files:**
- No new files unless validation fixes are needed.

- [ ] **Step 1: Use local dependencies**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tool/use_local_packages.ps1
```

Expected:

```text
Rewrote cloudflared_tunnel_full dependencies to local paths.
```

- [ ] **Step 2: Get dependencies for all packages**

Run:

```powershell
flutter pub get --directory packages/cloudflared_tunnel_android_arm
flutter pub get --directory packages/cloudflared_tunnel_android_x86
flutter pub get --directory packages/cloudflared_tunnel_full
flutter pub get --directory packages/cloudflared_tunnel_full/example
```

Expected: all commands finish with `Got dependencies!`.

- [ ] **Step 3: Run Dart and Flutter analysis**

Run:

```powershell
flutter analyze packages/cloudflared_tunnel_android_arm
flutter analyze packages/cloudflared_tunnel_android_x86
flutter analyze packages/cloudflared_tunnel_full
flutter analyze packages/cloudflared_tunnel_full/example
```

Expected: all commands report no errors.

- [ ] **Step 4: Run package tests**

Run:

```powershell
flutter test packages/cloudflared_tunnel_full
```

Expected:

```text
All tests passed!
```

- [ ] **Step 5: Build the example APK if Android toolchain is available**

Run:

```powershell
flutter build apk --debug --target-platform android-arm,android-arm64,android-x64 --directory packages/cloudflared_tunnel_full/example
```

Expected: APK build succeeds. If local Android build fails because x86 libraries have not been generated locally, record the exact missing files and rely on GitHub Actions after the gomobile build runs.

- [ ] **Step 6: Restore publish pubspecs**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tool/restore_pubspecs.ps1
```

Expected:

```text
Restored package pubspec files from git.
```

- [ ] **Step 7: Run publish dry-runs where possible**

Run:

```powershell
dart pub publish --dry-run --directory packages/cloudflared_tunnel_android_arm
dart pub publish --dry-run --directory packages/cloudflared_tunnel_android_x86
dart pub publish --dry-run --directory packages/cloudflared_tunnel_full
```

Expected: dry-runs pass. If `cloudflared_tunnel_full` fails because sidecar packages are not yet published, note that this will pass after placeholder packages exist or by using local dependency rewrite only for CI validation.

- [ ] **Step 8: Commit validation fixes**

If any files changed during fixes:

```powershell
git add .
git commit -m "fix: address split package validation issues"
```

Expected: commit succeeds. If no files changed, do not create an empty commit.

---

### Task 14: Completion handoff

**Files:**
- No files modified in this task.

- [ ] **Step 1: Check final status**

Run:

```powershell
git status --short --branch
git log --oneline --decorate -n 12
```

Expected: branch is clean and recent commits show the split package work.

- [ ] **Step 2: Summarize remaining manual steps**

Include these manual steps in the final response:

```text
1. Run tool/create_placeholder_packages.ps1.
2. Locally publish 0.0.1-dev.1 for the three packages.
3. Configure pub.dev automated publishing for all three packages with tag pattern cloudflared_tunnel-v{{version}}.
4. Push the feature branch and run GitHub Actions build.
5. Tag cloudflared_tunnel-v1.0.0 when ready to publish.
```

---

## Self-review

- Spec coverage: The plan covers the three package split, synchronized tag publishing, placeholder-first pub.dev flow, all four Android ABIs, CI validation, future desktop-friendly package naming, and compatibility imports.
- Placeholder scan: This plan uses the word placeholder only for the explicit `0.0.1-dev.1` package workflow, not as an incomplete instruction. No incomplete implementation steps are left.
- Type consistency: Package names, channel names, version numbers, and file paths match the approved design document.
