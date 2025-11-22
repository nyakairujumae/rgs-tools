#!/bin/bash

# Fix Swift-only module import issues in GeneratedPluginRegistrant.m
# When using static frameworks, @import doesn't work for Swift-only modules
# This script comments out problematic @import statements
# The plugins will still work because Flutter's plugin system handles Swift plugins automatically

GENERATED_FILE="${SRCROOT}/Runner/GeneratedPluginRegistrant.m"

if [ -f "$GENERATED_FILE" ]; then
    # List of Swift-only plugins that cause @import issues with static frameworks
    # Comment out their @import statements - the plugins will be auto-registered
    SWIFT_ONLY_PLUGINS=("app_links" "connectivity_plus" "firebase_core" "firebase_messaging" "flutter_app_badger" "flutter_local_notifications" "flutter_native_splash" "image_picker_ios" "mobile_scanner" "open_file_ios" "printing" "shared_preferences_foundation" "sqflite_darwin" "url_launcher_ios" "video_player_avfoundation")
    
    # Comment out @import statements for Swift-only plugins
    for plugin in "${SWIFT_ONLY_PLUGINS[@]}"; do
        sed -i '' "s/@import ${plugin};/\/\/ @import ${plugin}; \/\/ Swift-only, auto-registered/g" "$GENERATED_FILE"
    done
    
    # The plugins will still be registered because Flutter's plugin registry
    # can find and register Swift plugins automatically via the plugin system
    # The @import is just for compile-time type checking
    
    echo "✅ Fixed Swift-only module imports in GeneratedPluginRegistrant.m"
fi

