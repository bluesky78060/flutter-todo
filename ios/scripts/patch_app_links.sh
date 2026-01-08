#!/bin/bash
# Disable app_links plugin registration for iOS 26 compatibility
# This script should be run after flutter pub get and before flutter build

REGISTRANT_FILE="$SRCROOT/Runner/GeneratedPluginRegistrant.m"

if [ -f "$REGISTRANT_FILE" ]; then
    echo "Patching GeneratedPluginRegistrant.m to disable app_links..."

    # Comment out app_links import
    sed -i '' 's/#if __has_include(<app_links\/AppLinksIosPlugin.h>)/\/\/ DISABLED FOR iOS 26: #if __has_include(<app_links\/AppLinksIosPlugin.h>)/g' "$REGISTRANT_FILE"
    sed -i '' 's/#import <app_links\/AppLinksIosPlugin.h>/\/\/ #import <app_links\/AppLinksIosPlugin.h>/g' "$REGISTRANT_FILE"
    sed -i '' 's/@import app_links;/\/\/ @import app_links;/g' "$REGISTRANT_FILE"
    sed -i '' 's/#endif \/\/ app_links/\/\/ #endif \/\/ app_links/g' "$REGISTRANT_FILE"

    # Comment out app_links registration
    sed -i '' 's/\[AppLinksIosPlugin registerWithRegistrar:\[registry registrarForPlugin:@"AppLinksIosPlugin"\]\];/\/\/ [AppLinksIosPlugin registerWithRegistrar:[registry registrarForPlugin:@"AppLinksIosPlugin"]]; \/\/ DISABLED FOR iOS 26/g' "$REGISTRANT_FILE"

    echo "app_links plugin disabled successfully"
else
    echo "Warning: GeneratedPluginRegistrant.m not found at $REGISTRANT_FILE"
fi
