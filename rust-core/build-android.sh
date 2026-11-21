#!/usr/bin/env bash
set -euo pipefail

# Cross-compile FerroDL Rust Core (Phase 1 + Phase 2) for Android arm64-v8a and armeabi-v7a
# using cargo-ndk and generate UniFFI Kotlin bindings.
#
# Prerequisites:
#   rustup target add aarch64-linux-android armv7-linux-androideabi
#   cargo install cargo-ndk
#   export ANDROID_NDK_HOME=/path/to/ndk

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JNI_LIBS_DIR="${SCRIPT_DIR}/../app/src/main/jniLibs"
KOTLIN_OUT_DIR="${SCRIPT_DIR}/../app/src/main/java"

cd "${SCRIPT_DIR}"

echo "[FerroDL] Checking complete 7-crate Rust workspace on host..."
cargo check --workspace

echo "[FerroDL] Running Rust workspace unit & integration tests..."
cargo test --workspace

if command -v cargo-ndk >/dev/null 2>&1; then
    echo "[FerroDL] Building libferro_android_ffi.so (arm64-v8a, armeabi-v7a)..."
    mkdir -p "${JNI_LIBS_DIR}"
    cargo ndk \
        -p 24 \
        -t aarch64-linux-android \
        -t armv7-linux-androideabi \
        -o "${JNI_LIBS_DIR}" \
        build --release -p android-ffi

    if command -v uniffi-bindgen >/dev/null 2>&1; then
        echo "[FerroDL] Generating UniFFI Kotlin bindings..."
        uniffi-bindgen generate \
            --library "${JNI_LIBS_DIR}/arm64-v8a/libferro_android_ffi.so" \
            --language kotlin \
            --out-dir "${KOTLIN_OUT_DIR}"
    else
        echo "[FerroDL] uniffi-bindgen not found on PATH; skipping Kotlin stub regeneration."
    fi

    echo "[FerroDL] Native libraries ready in ${JNI_LIBS_DIR}"
else
    echo "[FerroDL] cargo-ndk not installed; host checks completed."
fi
