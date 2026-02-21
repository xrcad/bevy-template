{
  description = "Bevy cross-platform app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];

        # ── Android SDK composition ──────────────────────────────────────────
        # Uncomment this block (and the references to it below) when you want
        # to do local Android builds. Commented out by default because it
        # downloads several gigabytes of Android SDK/NDK on first use.
        #
        # pkgsAndroid = import nixpkgs {
        #   inherit system overlays;
        #   config = {
        #     android_sdk.accept_license = true;
        #     allowUnfree = true;
        #   };
        # };
        #
        # buildToolsVersion = "35.0.0";
        # ndkVersion = "27.2.12479018";  # must match CI NDK_VERSION
        #
        # androidComposition = pkgsAndroid.androidenv.composeAndroidPackages {
        #   platformToolsVersion = "35.0.2";
        #   buildToolsVersions = [ buildToolsVersion ];
        #   platformVersions = [ "35" ];
        #   includeNDK = true;
        #   ndkVersions = [ ndkVersion ];
        #   includeEmulator = false;
        #   includeSources = false;
        #   includeSystemImages = false;
        #   abiVersions = [ "arm64-v8a" ];
        # };
        # ────────────────────────────────────────────────────────────────────

        pkgs = import nixpkgs { inherit system overlays; };

        # Rust toolchain — stable with the targets we need
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          targets = [
            "wasm32-unknown-unknown"
            # Uncomment for Android builds:
            # "aarch64-linux-android"
          ];
        };

        # Linux system deps required by Bevy's default feature set
        bevyLinuxDeps = with pkgs; [
          alsa-lib
          udev
          libxkbcommon
          wayland
          libGL
          vulkan-loader
          vulkan-headers
          vulkan-validation-layers
          pkg-config
        ];

      in
      {
        devShells = {

          # ── Default shell: Linux desktop + WASM development ───────────────
          default = pkgs.mkShell {
            name = "bevy-dev";

            buildInputs = [
              rustToolchain
              pkgs.wasm-bindgen-cli
              pkgs.cargo-ndk   # available for reference even without Android SDK
              pkgs.jdk21       # needed if you run gradle locally
              pkgs.gradle
            ] ++ bevyLinuxDeps;

            # Dynamic linker path so Vulkan/Wayland libs are found at runtime
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath bevyLinuxDeps;

            shellHook = ''
              echo "Bevy dev shell ready"
              echo "  cargo run          — desktop"
              echo "  cargo build --target wasm32-unknown-unknown — WASM"
            '';
          };

          # ── Android shell: uncomment the androidComposition block above ───
          # then switch to this shell with: nix develop .#android
          #
          # android = pkgsAndroid.mkShell rec {
          #   name = "bevy-android";
          #
          #   ANDROID_SDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk";
          #   ANDROID_NDK_HOME = "${ANDROID_SDK_ROOT}/ndk/${ndkVersion}";
          #
          #   # Required on NixOS: override the aapt2 gradle downloads with the
          #   # Nix store version, which is correctly patched for NixOS's linker.
          #   GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_SDK_ROOT}/build-tools/${buildToolsVersion}/aapt2";
          #
          #   buildInputs = [
          #     (pkgsAndroid.rust-bin.stable.latest.default.override {
          #       targets = [ "aarch64-linux-android" "wasm32-unknown-unknown" ];
          #     })
          #     androidComposition.androidsdk
          #     pkgsAndroid.cargo-ndk
          #     pkgsAndroid.jdk21
          #     pkgsAndroid.gradle
          #   ] ++ (with pkgsAndroid; [ pkg-config ]);
          #
          #   shellHook = ''
          #     echo "Android dev shell ready"
          #     echo "  ANDROID_SDK_ROOT = $ANDROID_SDK_ROOT"
          #     echo "  ANDROID_NDK_HOME = $ANDROID_NDK_HOME"
          #     echo ""
          #     echo "  cargo ndk -t arm64-v8a -o android-project/app/src/main/jniLibs build"
          #     echo "  cd android-project && ./gradlew assembleDebug"
          #   '';
          # };

        };
      }
    );
}
