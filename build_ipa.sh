#!/usr/bin/env bash
set -euo pipefail

echo "Please enter the path to your decrypted BeReal IPA file:"
read -r IPA_PATH

# Remove single quotes if present
IPA_PATH=$(echo "$IPA_PATH" | sed "s/^'//;s/'$//")

if [ ! -f "$IPA_PATH" ]; then
    echo "Error: The file '$IPA_PATH' does not exist."
    exit 1
fi

echo "Using IPA: $IPA_PATH"

if ! command -v cyan >/dev/null 2>&1; then
    echo "Error: cyan (pyzule-rw) is not installed."
    echo "Install with: pip install --upgrade https://github.com/asdfzxcvbn/pyzule-rw/archive/main.zip"
    exit 1
fi

JAILED_DEB=$(find "$(pwd)/packages" -name "*_jailed.deb" -type f)

if [ -z "$JAILED_DEB" ]; then
    echo "Error: Could not find jailed deb file, please run ./build_release.sh first."
    echo "Contents of packages directory:"
    ls -la ./packages/
    exit 1
fi

echo "Found jailed deb: $JAILED_DEB"

# this is needed because else azule will fail
ABS_IPA_PATH=$(realpath "$IPA_PATH")
ABS_JAILED_DEB=$(realpath "$JAILED_DEB")

IPA_FILENAME=$(basename "$IPA_PATH")
TWEAK_VERSION=$(grep -E '^Version:' "$(pwd)/control" | sed 's/Version: *//')
OUTPUT_NAME="${IPA_FILENAME%.*}+com.yan.minibea_${TWEAK_VERSION}"
OUTPUT_PATH="$(pwd)/${OUTPUT_NAME}.ipa"

echo "Injecting tweak into IPA with cyan..."
cyan -i "$ABS_IPA_PATH" -o "$OUTPUT_PATH" -f "$ABS_JAILED_DEB" --overwrite
echo "Done! Patched IPA is in: $OUTPUT_PATH"
