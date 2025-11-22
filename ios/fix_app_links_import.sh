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
    
    # Comment out entire registration lines for Swift-only plugins
    # Use perl for multiline matching to handle the full registration call
    perl -i -0pe 's/^\s*\[AppLinksIosPlugin registerWithRegistrar:\[registry registrarForPlugin:@"AppLinksIosPlugin"\]\];\s*$/\n  \/\/ [AppLinksIosPlugin registerWithRegistrar:[registry registrarForPlugin:@"AppLinksIosPlugin"]]; \/\/ Swift-only\n/gm' "$GENERATED_FILE"
    perl -i -0pe 's/^\s*\[ConnectivityPlusPlugin registerWithRegistrar:\[registry registrarForPlugin:@"ConnectivityPlusPlugin"\]\];\s*$/\n  \/\/ [ConnectivityPlusPlugin registerWithRegistrar:[registry registrarForPlugin:@"ConnectivityPlusPlugin"]]; \/\/ Swift-only\n/gm' "$GENERATED_FILE"
    perl -i -0pe 's/^\s*\[FLTFirebaseCorePlugin registerWithRegistrar:\[registry registrarForPlugin:@"FLTFirebaseCorePlugin"\]\];\s*$/\n  \/\/ [FLTFirebaseCorePlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTFirebaseCorePlugin"]]; \/\/ Swift-only\n/gm' "$GENERATED_FILE"
    perl -i -0pe 's/^\s*\[FLTFirebaseMessagingPlugin registerWithRegistrar:\[registry registrarForPlugin:@"FLTFirebaseMessagingPlugin"\]\];\s*$/\n  \/\/ [FLTFirebaseMessagingPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTFirebaseMessagingPlugin"]]; \/\/ Swift-only\n/gm' "$GENERATED_FILE"
    perl -i -0pe 's/^\s*\[FlutterAppBadgerPlugin registerWithRegistrar:\[registry registrarForPlugin:@"FlutterAppBadgerPlugin"\]\];\s*$/\n  \/\/ [FlutterAppBadgerPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterAppBadgerPlugin"]]; \/\/ Swift-only\n/gm' "$GENERATED_FILE"
    perl -i -0pe 's/^\s*\[FlutterLocalNotificationsPlugin registerWithRegistrar:\[registry registrarForPlugin:@"FlutterLocalNotificationsPlugin"\]\];\s*$/\n  \/\/ [FlutterLocalNotificationsPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterLocalNotificationsPlugin"]]; \/\/ Swift-only\n/gm' "$GENERATED_FILE"
    perl -i -0pe 's/^\s*\[FlutterNativeSplashPlugin registerWithRegistrar:\[registry registrarForPlugin:@"FlutterNativeSplashPlugin"\]\];\s*$/\n  \/\/ [FlutterNativeSplashPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterNativeSplashPlugin"]]; \/\/ Swift-only\n/gm' "$GENERATED_FILE"
    perl -i -0pe 's/^\s*\[FLTImagePickerPlugin registerWithRegistrar:\[registry registrarForPlugin:@"FLTImagePickerPlugin"\]\];\s*$/\n  \/\/ [FLTImagePickerPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTImagePickerPlugin"]]; \/\/ Swift-only\n/gm' "$GENERATED_FILE"
    perl -i -0pe 's/^\s*\[MobileScannerPlugin registerWithRegistrar:\[registry registrarForPlugin:@"MobileScannerPlugin"\]\];\s*$/\n  \/\/ [MobileScannerPlugin registerWithRegistrar:[registry registrarForPlugin:@"MobileScannerPlugin"]]; \/\/ Swift-only\n/gm' "$GENERATED_FILE"
    perl -i -0pe 's/^\s*\[OpenFilePlugin registerWithRegistrar:\[registry registrarForPlugin:@"OpenFilePlugin"\]\];\s*$/\n  \/\/ [OpenFilePlugin registerWithRegistrar:[registry registrarForPlugin:@"OpenFilePlugin"]]; \/\/ Swift-only\n/gm' "$GENERATED_FILE"
    perl -i -0pe 's/^\s*\[PrintingPlugin registerWithRegistrar:\[registry registrarForPlugin:@"PrintingPlugin"\]\];\s*$/\n  \/\/ [PrintingPlugin registerWithRegistrar:[registry registrarForPlugin:@"PrintingPlugin"]]; \/\/ Swift-only\n/gm' "$GENERATED_FILE"
    perl -i -0pe 's/^\s*\[SharedPreferencesPlugin registerWithRegistrar:\[registry registrarForPlugin:@"SharedPreferencesPlugin"\]\];\s*$/\n  \/\/ [SharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharedPreferencesPlugin"]]; \/\/ Swift-only\n/gm' "$GENERATED_FILE"
    perl -i -0pe 's/^\s*\[SqflitePlugin registerWithRegistrar:\[registry registrarForPlugin:@"SqflitePlugin"\]\];\s*$/\n  \/\/ [SqflitePlugin registerWithRegistrar:[registry registrarForPlugin:@"SqflitePlugin"]]; \/\/ Swift-only\n/gm' "$GENERATED_FILE"
    perl -i -0pe 's/^\s*\[URLLauncherPlugin registerWithRegistrar:\[registry registrarForPlugin:@"URLLauncherPlugin"\]\];\s*$/\n  \/\/ [URLLauncherPlugin registerWithRegistrar:[registry registrarForPlugin:@"URLLauncherPlugin"]]; \/\/ Swift-only\n/gm' "$GENERATED_FILE"
    perl -i -0pe 's/^\s*\[FVPVideoPlayerPlugin registerWithRegistrar:\[registry registrarForPlugin:@"FVPVideoPlayerPlugin"\]\];\s*$/\n  \/\/ [FVPVideoPlayerPlugin registerWithRegistrar:[registry registrarForPlugin:@"FVPVideoPlayerPlugin"]]; \/\/ Swift-only\n/gm' "$GENERATED_FILE"
    
    echo "✅ Fixed Swift-only module imports in GeneratedPluginRegistrant.m"
fi

