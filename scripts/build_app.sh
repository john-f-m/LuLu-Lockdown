#!/bin/bash
# Build LuLu-Lockdown from the command line.
#
# Usage:
#   ./scripts/build_app.sh              # ad-hoc signed (local dev - may NOT activate extension)
#   ./scripts/build_app.sh --team <ID>  # signs with your Developer Team ID (recommended for testing)
#   ./scripts/build_app.sh --release    # uses project signing settings (needs original provisioning profiles)

set -e

printf "\nBuilding LuLu-Lockdown...\n\n"

WORKSPACE="lulu.xcworkspace"
SCHEME="LuLu"
CONFIGURATION="Release"
DERIVED_DATA_PATH="build"
MODE=""
TEAM_ID=""

# parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --release) MODE="release" ;;
        --team) TEAM_ID="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Base command
BUILD_CMD=(
  xcodebuild
  -workspace "$WORKSPACE"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -derivedDataPath "$DERIVED_DATA_PATH"
)

if [ "$MODE" = "release" ]; then
  printf "Building with project signing settings (requires original provisioning profiles)...\n\n"
elif [ -n "$TEAM_ID" ]; then
  printf "Building and signing with Team ID: $TEAM_ID...\n\n"
  BUILD_CMD+=(
    DEVELOPMENT_TEAM="$TEAM_ID"
    CODE_SIGN_STYLE="Automatic"
  )
else
  printf "Building with ad-hoc signing (local development)...\n"
  printf "NOTE: Network Extensions often fail to activate with ad-hoc signing.\n"
  printf "      Use --team <YOUR_ID> for a full developer build.\n\n"
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

# cleanup intermediate build files
printf "\nCleaning up intermediate build artifacts...\n"
rm -rf "$DERIVED_DATA_PATH"

printf "\nBuild successful! LuLu.app is in the Release/ directory.\n"
