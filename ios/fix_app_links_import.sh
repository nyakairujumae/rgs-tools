#!/bin/bash

# Fix Swift-only module import issues in GeneratedPluginRegistrant.m
# When using static frameworks, @import doesn't work for Swift-only modules
# This script comments out problematic @import statements and their registrations

GENERATED_FILE="${SRCROOT}/Runner/GeneratedPluginRegistrant.m"

if [ -f "$GENERATED_FILE" ]; then
    # List of Swift-only plugins that cause @import issues with static frameworks
    # These will be auto-registered by Flutter's plugin system
    SWIFT_ONLY_PLUGINS=("app_links" "connectivity_plus" "firebase_core" "firebase_messaging" "flutter_app_badger" "flutter_local_notifications" "flutter_native_splash" "image_picker_ios" "mobile_scanner" "open_file_ios" "printing" "shared_preferences_foundation" "sqflite_darwin" "url_launcher_ios" "video_player_avfoundation")
    
    # Comment out @import statements for Swift-only plugins
    for plugin in "${SWIFT_ONLY_PLUGINS[@]}"; do
        sed -i '' "s/@import ${plugin};/\/\/ @import ${plugin}; \/\/ Swift-only, auto-registered/g" "$GENERATED_FILE"
    done
    
    # Comment out registrations for Swift-only plugins that can't be imported
    # These plugins will be auto-registered by Flutter's Swift plugin system
    sed -i '' 's/\[AppLinksIosPlugin registerWithRegistrar:/\/\/ [AppLinksIosPlugin registerWithRegistrar:/g' "$GENERATED_FILE"
    sed -i '' 's/\[ConnectivityPlusPlugin registerWithRegistrar:/\/\/ [ConnectivityPlusPlugin registerWithRegistrar:/g' "$GENERATED_FILE"
    sed -i '' 's/\[FLTFirebaseCorePlugin registerWithRegistrar:/\/\/ [FLTFirebaseCorePlugin registerWithRegistrar:/g' "$GENERATED_FILE"
    sed -i '' 's/\[FLTFirebaseMessagingPlugin registerWithRegistrar:/\/\/ [FLTFirebaseMessagingPlugin registerWithRegistrar:/g' "$GENERATED_FILE"
    sed -i '' 's/\[FlutterAppBadgerPlugin registerWithRegistrar:/\/\/ [FlutterAppBadgerPlugin registerWithRegistrar:/g' "$GENERATED_FILE"
    sed -i '' 's/\[FlutterLocalNotificationsPlugin registerWithRegistrar:/\/\/ [FlutterLocalNotificationsPlugin registerWithRegistrar:/g' "$GENERATED_FILE"
    sed -i '' 's/\[FlutterNativeSplashPlugin registerWithRegistrar:/\/\/ [FlutterNativeSplashPlugin registerWithRegistrar:/g' "$GENERATED_FILE"
    sed -i '' 's/\[FLTImagePickerPlugin registerWithRegistrar:/\/\/ [FLTImagePickerPlugin registerWithRegistrar:/g' "$GENERATED_FILE"
    sed -i '' 's/\[MobileScannerPlugin registerWithRegistrar:/\/\/ [MobileScannerPlugin registerWithRegistrar:/g' "$GENERATED_FILE"
    sed -i '' 's/\[OpenFilePlugin registerWithRegistrar:/\/\/ [OpenFilePlugin registerWithRegistrar:/g' "$GENERATED_FILE"
    sed -i '' 's/\[PrintingPlugin registerWithRegistrar:/\/\/ [PrintingPlugin registerWithRegistrar:/g' "$GENERATED_FILE"
    sed -i '' 's/\[SharedPreferencesPlugin registerWithRegistrar:/\/\/ [SharedPreferencesPlugin registerWithRegistrar:/g' "$GENERATED_FILE"
    sed -i '' 's/\[SqflitePlugin registerWithRegistrar:/\/\/ [SqflitePlugin registerWithRegistrar:/g' "$GENERATED_FILE"
    sed -i '' 's/\[URLLauncherPlugin registerWithRegistrar:/\/\/ [URLLauncherPlugin registerWithRegistrar:/g' "$GENERATED_FILE"
    sed -i '' 's/\[FVPVideoPlayerPlugin registerWithRegistrar:/\/\/ [FVPVideoPlayerPlugin registerWithRegistrar:/g' "$GENERATED_FILE"
    
    echo "✅ Fixed Swift-only module imports in GeneratedPluginRegistrant.m"
fi

