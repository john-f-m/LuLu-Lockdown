#!/bin/bash
# Build LuLu-Lockdown from the command line.
#
# Usage:
#   ./scripts/build_app.sh              # ad-hoc signed (local dev)
#   ./scripts/build_app.sh --release    # uses project signing settings (needs provisioning profiles)

set -e

printf "\nBuilding LuLu-Lockdown...\n\n"

WORKSPACE="lulu.xcworkspace"
SCHEME="LuLu"
CONFIGURATION="Release"
DERIVED_DATA_PATH="build"
MODE="${1:-}"

# ensure dependencies
NETIQUETTE_PATH="LuLu/Binaries/Netiquette.app"
if [ ! -d "$NETIQUETTE_PATH" ]; then
    printf "Dependency missing: Netiquette.app. Fetching from Objective-See releases...\n"
    mkdir -p LuLu/Binaries
    cd LuLu/Binaries
    curl -fsSL -o Netiquette.zip "https://github.com/objective-see/Netiquette/releases/download/v2.3.0/Netiquette_2.3.0.zip"
    unzip -o Netiquette.zip
    rm Netiquette.zip
    cd ../..
    printf "Netiquette.app successfully downloaded.\n\n"
fi

# Base command
BUILD_CMD=(
  xcodebuild
  -workspace "$WORKSPACE"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -derivedDataPath "$DERIVED_DATA_PATH"
)

if [ "$MODE" = "--release" ]; then
  printf "Building with project signing settings (requires provisioning profiles)...\n\n"
else
  printf "Building with ad-hoc signing (local development)...\n\n"
  BUILD_CMD+=(
    CODE_SIGN_IDENTITY="-"
    CODE_SIGNING_REQUIRED=NO
    CODE_SIGNING_ALLOWED=NO
    PROVISIONING_PROFILE_SPECIFIER=""
    DEVELOPMENT_TEAM=""
  )
fi

# Clean and build
"${BUILD_CMD[@]}" clean build

# Copy build results to a predictable location
mkdir -p Release
cp -R "$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/LuLu.app" Release/

printf "\nBuild successful! LuLu.app is in the Release/ directory.\n"
