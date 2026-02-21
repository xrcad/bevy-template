# Bevy Cross-Platform CI

Multi-stage CI pipeline for a Bevy 0.18 app targeting Android, WASM, and Linux.

## Pipeline Overview

```
build-rust.yml
├── android-lib   → jniLibs artifact (arm64-v8a .so + libc++_shared.so)
├── wasm-lib      → wasm-out artifact (wasm-bindgen output)
└── linux-bin     → linux-bin artifact

assemble-android.yml  (triggered by build-rust.yml success)
└── downloads jniLibs → runs Gradle → uploads debug + release APK

package-wasm.yml  (triggered by build-rust.yml success)
└── downloads wasm-out → packages with assets → optionally deploys to Pages
```

Each stage is independently re-runnable via `workflow_dispatch` by supplying
the run ID of an existing `Build Rust Libraries` run.

## Required GitHub Secrets

Add these in **Settings → Secrets and variables → Actions**:

| Secret | Description |
|--------|-------------|
| `RELEASE_KEYSTORE_B64` | Base64-encoded release keystore: `base64 -w0 release.keystore` |
| `RELEASE_KEYSTORE_PASS` | Keystore password |
| `RELEASE_KEY_ALIAS` | Key alias inside the keystore |
| `RELEASE_KEY_PASS` | Key password |

Generate a keystore if you don't have one:
```bash
keytool -genkey -v \
  -keystore release.keystore \
  -alias myapp \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

## Android Project Customisation

Before using, replace these throughout `android-project/`:

| Placeholder | Replace with |
|-------------|--------------|
| `com.example.myapp` | Your actual package name |
| `myapp` | Your Cargo package name (must match `[lib] name` in Cargo.toml) |
| `My App` | Your app display name |

## Local Android Build

Prerequisites: Rust stable, Android NDK, cargo-ndk.

```bash
# Install cargo-ndk
cargo install cargo-ndk --locked

# Add Android target
rustup target add aarch64-linux-android

# Build .so and place into jniLibs
cargo ndk \
  --target aarch64-linux-android \
  --platform 26 \
  -o android-project/app/src/main/jniLibs \
  build

# Copy libc++_shared.so (path may vary by NDK version)
cp "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" \
   android-project/app/src/main/jniLibs/arm64-v8a/

# Assemble debug APK
cd android-project && ./gradlew assembleDebug
# Output: android-project/app/build/outputs/apk/debug/app-debug.apk
```

## Notes

- **GameActivity vs NativeActivity**: Bevy defaults to `android-game-activity`, which
  requires minSdk 31 and a `Theme.AppCompat` theme. If you need older device support,
  swap to `android-native-activity` in Cargo.toml, change `MainActivity` to extend
  `NativeActivity`, revert the theme, and drop `minSdk` back to 26.

- **libc++_shared.so**: Handled automatically by the `android_shared_stdcxx` Bevy feature,
  which tells cargo-ndk to copy it alongside the `.so`. No dummy CMake target needed.

- **Vulkan vs GLES**: The manifest marks Vulkan as `required=false` so wgpu can fall
  back to GLES on hardware that doesn't support it.

- **NDK version**: Pinned in `build-rust.yml` via `NDK_VERSION`. Change it in one place
  and it propagates to both the Rust and Gradle builds.
