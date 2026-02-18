#!/bin/bash

# exit on error
set -e

printf "\nBuilding LuLu-Lockdown...\n\n"

# workspace and scheme
WORKSPACE="lulu.xcworkspace"
SCHEME="LuLu"
CONFIGURATION="Release"
DERIVED_DATA_PATH="build"

# clean and build
xcodebuild -workspace "$WORKSPACE" \
           -scheme "$SCHEME" \
           -configuration "$CONFIGURATION" \
           -derivedDataPath "$DERIVED_DATA_PATH" \
           clean build

# copy build results to a predictable location
mkdir -p Release
cp -R "$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/LuLu.app" Release/

printf "\nBuild successful! LuLu.app is in the Release/ directory.\n"
