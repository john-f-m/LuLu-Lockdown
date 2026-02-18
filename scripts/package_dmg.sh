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

# mount it and get mount point
# we use -plist to get structured data and then parse out the mount point
# this is robust against spaces in the volume name
MOUNT_POINT=$(hdiutil attach "$TMP_DMG" -plist | grep -A1 'mount-point' | tail -n1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')

if [ -z "$MOUNT_POINT" ]; then
    echo "Error: Failed to mount $TMP_DMG"
    exit 1
fi

printf "Mounted at: $MOUNT_POINT\n"

# handle cleanup on exit (detach volume)
function cleanup {
    printf "\nDetaching $MOUNT_POINT...\n"
    hdiutil detach "$MOUNT_POINT" || true
    rm -f "$TMP_DMG"
}
trap cleanup EXIT

# copy the app
printf "Copying $APP_NAME.app to DMG...\n"
cp -R "$APP_PATH" "$MOUNT_POINT/"

# create a link to Applications
printf "Creating Applications shortcut...\n"
ln -s /Applications "$MOUNT_POINT/Applications"

# convert to compressed read-only DMG
printf "Converting to final DMG...\n"
hdiutil convert "$TMP_DMG" -format UDZO -o "$DMG_NAME"

printf "\nDone! $DMG_NAME created.\n"
