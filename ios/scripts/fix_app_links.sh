#!/bin/bash
# Fix GeneratedPluginRegistrant.m to use app_links_stub instead of app_links
# Run this after flutter build ios

REGISTRANT_FILE="$(dirname "$0")/../Runner/GeneratedPluginRegistrant.m"

if [ -f "$REGISTRANT_FILE" ]; then
    # Replace app_links import with app_links_stub import
    sed -i '' 's/#if __has_include(<app_links\/AppLinksIosPlugin.h>)/#import <app_links_stub\/app_links_stub-Swift.h>/' "$REGISTRANT_FILE"
    sed -i '' '/#import <app_links\/AppLinksIosPlugin.h>/d' "$REGISTRANT_FILE"
    sed -i '' '/#else/d' "$REGISTRANT_FILE"
    sed -i '' '/@import app_links;/d' "$REGISTRANT_FILE"
    sed -i '' '/#endif/d' "$REGISTRANT_FILE"

    echo "Fixed app_links in GeneratedPluginRegistrant.m"
else
    echo "GeneratedPluginRegistrant.m not found at $REGISTRANT_FILE"
    exit 1
fi
