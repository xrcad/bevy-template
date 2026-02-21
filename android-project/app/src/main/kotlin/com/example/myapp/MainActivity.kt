package com.example.myapp

import com.google.androidgamesdk.GameActivity

/**
 * Thin Kotlin host activity. All rendering and logic lives in the Rust/Bevy library.
 *
 * GameActivity (from the Android Game Development Kit) is the current recommended
 * base class for native game apps — it supersedes the legacy NativeActivity.
 * Bevy uses it by default via the `android-game-activity` feature.
 *
 * Requirements:
 *   - minSdk 31 (GameActivity requirement)
 *   - Theme must derive from Theme.AppCompat (see res/values/themes.xml)
 *   - The `android-game-activity` feature must be enabled in Cargo.toml
 */
class MainActivity : GameActivity() {
    companion object {
        init {
            // Must match the `[lib] name` in your Cargo.toml
            System.loadLibrary("myapp")
        }
    }
}
