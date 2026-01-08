#!/bin/bash
# Setup custom app_links implementation for iOS 26+ compatibility
# Run this after flutter pub get or flutter clean

SCRIPT_DIR="$(dirname "$0")"
IOS_DIR="$(dirname "$SCRIPT_DIR")"
LOCAL_APP_LINKS="$IOS_DIR/LocalPods/app_links"
SYMLINK_APP_LINKS="$IOS_DIR/.symlinks/plugins/app_links/ios"

if [ -d "$LOCAL_APP_LINKS" ]; then
    if [ -d "$SYMLINK_APP_LINKS" ]; then
        echo "Replacing app_links symlink with custom iOS 26+ compatible implementation..."
        rm -rf "$SYMLINK_APP_LINKS"
        cp -r "$LOCAL_APP_LINKS" "$SYMLINK_APP_LINKS"
        echo "Done! app_links has been replaced with custom implementation."
    else
        echo "Warning: .symlinks/plugins/app_links/ios not found. Run 'flutter pub get' first."
        exit 1
    fi
else
    echo "Error: LocalPods/app_links not found."
    exit 1
fi
