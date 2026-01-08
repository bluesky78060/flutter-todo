#!/bin/bash

# Disable problematic plugins for iOS 26+ compatibility
# This script modifies GeneratedPluginRegistrant.m to remove plugins that cause crashes
# Run this script AFTER flutter pub get or flutter run regenerates the file
#
# Known problematic plugins on iOS 26:
# - app_links: causes EXC_BAD_ACCESS crash in AppLinksIosPlugin.register()
# - connectivity_plus: causes EXC_BAD_ACCESS crash in ConnectivityPlusPlugin.register()
# - battery_plus: may cause issues on iOS 26 beta
# - flutter_activity_recognition: may cause issues on iOS 26 beta
# - geofence_service: may cause issues on iOS 26 beta
# - fl_location: may cause issues on iOS 26 beta
# - workmanager_apple: may cause issues on iOS 26 beta

PLUGIN_REGISTRANT="${SRCROOT:-/Users/leechanhee/todo_app/ios}/Runner/GeneratedPluginRegistrant.m"

if [ -f "$PLUGIN_REGISTRANT" ]; then
    echo "Disabling problematic plugins in: $PLUGIN_REGISTRANT"

    # List of plugins to disable (add more as needed)
    PLUGINS_TO_DISABLE=(
        "app_links:AppLinksIosPlugin"
        "connectivity_plus:ConnectivityPlusPlugin"
        "battery_plus:FPPBatteryPlusPlugin"
        "flutter_activity_recognition:FlutterActivityRecognitionPlugin"
        "geofence_service:GeofenceServicePlugin"
        "fl_location:FlLocationPlugin"
        "workmanager_apple:WorkmanagerPlugin"
    )

    # Create temp file
    cp "$PLUGIN_REGISTRANT" "${PLUGIN_REGISTRANT}.tmp"

    for plugin_pair in "${PLUGINS_TO_DISABLE[@]}"; do
        IFS=':' read -r plugin_name plugin_class <<< "$plugin_pair"

        # Comment out the ENTIRE #if...#else...#endif block for this plugin
        # Pattern: #if __has_include(<plugin_name/...) ... #else ... #endif
        sed -i '' "s|^#if __has_include(<${plugin_name}/|// DISABLED: #if __has_include(<${plugin_name}/|g" "${PLUGIN_REGISTRANT}.tmp"
        sed -i '' "s|^#import <${plugin_name}/|// DISABLED: #import <${plugin_name}/|g" "${PLUGIN_REGISTRANT}.tmp"

        # Comment out the #else and @import and #endif that follow a DISABLED block
        # This requires multi-line handling, so we use a different approach:
        # Replace the pattern in-place

        # Comment out registration lines
        sed -i '' "s|\\[${plugin_class} registerWithRegistrar:|// DISABLED: [${plugin_class} registerWithRegistrar:|g" "${PLUGIN_REGISTRANT}.tmp"

        echo "  - Disabled: ${plugin_name} (${plugin_class})"
    done

    # Now handle the orphaned #else and #endif after disabled blocks
    # We need to comment out #else and #endif that appear right after DISABLED lines
    # Use awk for multi-line processing
    awk '
    BEGIN { in_disabled_block = 0 }
    /^\/\/ DISABLED: #if/ { in_disabled_block = 1; print; next }
    /^\/\/ DISABLED: #import/ { print; next }
    /^\/\/ DISABLED: @import/ { in_disabled_block = 0; print; next }
    /^#else$/ {
        if (in_disabled_block) {
            print "// DISABLED: #else"
            next
        }
    }
    /^@import [a-z_]+;$/ {
        if (in_disabled_block) {
            print "// DISABLED: " $0
            next
        }
    }
    /^#endif$/ {
        if (in_disabled_block) {
            print "// DISABLED: #endif"
            in_disabled_block = 0
            next
        }
    }
    { print }
    ' "${PLUGIN_REGISTRANT}.tmp" > "${PLUGIN_REGISTRANT}.tmp2"

    mv "${PLUGIN_REGISTRANT}.tmp2" "$PLUGIN_REGISTRANT"
    rm -f "${PLUGIN_REGISTRANT}.tmp"

    echo "Problematic plugins disabled successfully"
    echo "Disabled plugins: ${#PLUGINS_TO_DISABLE[@]}"
else
    echo "Warning: GeneratedPluginRegistrant.m not found at $PLUGIN_REGISTRANT"
fi
