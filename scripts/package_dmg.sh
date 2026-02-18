#!/bin/bash

# exit on error
set -e

APP_NAME="LuLu"
APP_PATH="Release/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: $APP_PATH not found. Run scripts/build_app.sh first."
    exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$APP_PATH/Contents/Info.plist")
DMG_NAME="${APP_NAME}_${VERSION}.dmg"
TMP_DMG="tmp.dmg"
VOLUME_NAME="${APP_NAME} v${VERSION}"

printf "\nCreating Disk Image for $APP_NAME v$VERSION...\n\n"

# cleanup
rm -f "$DMG_NAME" "$TMP_DMG"

# create a temporary read/write DMG
hdiutil create -size 300m -fs HFS+ -volname "$VOLUME_NAME" "$TMP_DMG"

# mount it
MOUNT_POINT=$(hdiutil attach "$TMP_DMG" | grep "Volumes" | awk '{print $3}')

# copy the app
cp -R "$APP_PATH" "$MOUNT_POINT/"

# create a link to Applications
ln -s /Applications "$MOUNT_POINT/Applications"

# TODO: Add custom styling (background, icon positioning) if hdiutil supports it easily via AppleScript
# For now, this creates a functional, standard DMG.

# detach
hdiutil detach "$MOUNT_POINT"

# convert to compressed read-only DMG
hdiutil convert "$TMP_DMG" -format UDZO -o "$DMG_NAME"

# cleanup
rm "$TMP_DMG"

printf "\nDone! $DMG_NAME created.\n"
