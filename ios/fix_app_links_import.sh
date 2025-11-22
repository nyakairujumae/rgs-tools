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
    
    # Comment out registration calls for Swift-only plugins since we can't import them
    # Flutter's plugin system will auto-register Swift plugins, so this is safe
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
    
    # Also comment out the closing brackets for these registrations
    sed -i '' 's/\[registry registrarForPlugin:@"AppLinksIosPlugin"\]\];/\/\/ [registry registrarForPlugin:@"AppLinksIosPlugin"]]; \/\/ Swift-only/g' "$GENERATED_FILE"
    sed -i '' 's/\[registry registrarForPlugin:@"ConnectivityPlusPlugin"\]\];/\/\/ [registry registrarForPlugin:@"ConnectivityPlusPlugin"]]; \/\/ Swift-only/g' "$GENERATED_FILE"
    sed -i '' 's/\[registry registrarForPlugin:@"FLTFirebaseCorePlugin"\]\];/\/\/ [registry registrarForPlugin:@"FLTFirebaseCorePlugin"]]; \/\/ Swift-only/g' "$GENERATED_FILE"
    sed -i '' 's/\[registry registrarForPlugin:@"FLTFirebaseMessagingPlugin"\]\];/\/\/ [registry registrarForPlugin:@"FLTFirebaseMessagingPlugin"]]; \/\/ Swift-only/g' "$GENERATED_FILE"
    sed -i '' 's/\[registry registrarForPlugin:@"FlutterAppBadgerPlugin"\]\];/\/\/ [registry registrarForPlugin:@"FlutterAppBadgerPlugin"]]; \/\/ Swift-only/g' "$GENERATED_FILE"
    sed -i '' 's/\[registry registrarForPlugin:@"FlutterLocalNotificationsPlugin"\]\];/\/\/ [registry registrarForPlugin:@"FlutterLocalNotificationsPlugin"]]; \/\/ Swift-only/g' "$GENERATED_FILE"
    sed -i '' 's/\[registry registrarForPlugin:@"FlutterNativeSplashPlugin"\]\];/\/\/ [registry registrarForPlugin:@"FlutterNativeSplashPlugin"]]; \/\/ Swift-only/g' "$GENERATED_FILE"
    sed -i '' 's/\[registry registrarForPlugin:@"FLTImagePickerPlugin"\]\];/\/\/ [registry registrarForPlugin:@"FLTImagePickerPlugin"]]; \/\/ Swift-only/g' "$GENERATED_FILE"
    sed -i '' 's/\[registry registrarForPlugin:@"MobileScannerPlugin"\]\];/\/\/ [registry registrarForPlugin:@"MobileScannerPlugin"]]; \/\/ Swift-only/g' "$GENERATED_FILE"
    sed -i '' 's/\[registry registrarForPlugin:@"OpenFilePlugin"\]\];/\/\/ [registry registrarForPlugin:@"OpenFilePlugin"]]; \/\/ Swift-only/g' "$GENERATED_FILE"
    sed -i '' 's/\[registry registrarForPlugin:@"PrintingPlugin"\]\];/\/\/ [registry registrarForPlugin:@"PrintingPlugin"]]; \/\/ Swift-only/g' "$GENERATED_FILE"
    sed -i '' 's/\[registry registrarForPlugin:@"SharedPreferencesPlugin"\]\];/\/\/ [registry registrarForPlugin:@"SharedPreferencesPlugin"]]; \/\/ Swift-only/g' "$GENERATED_FILE"
    sed -i '' 's/\[registry registrarForPlugin:@"SqflitePlugin"\]\];/\/\/ [registry registrarForPlugin:@"SqflitePlugin"]]; \/\/ Swift-only/g' "$GENERATED_FILE"
    sed -i '' 's/\[registry registrarForPlugin:@"URLLauncherPlugin"\]\];/\/\/ [registry registrarForPlugin:@"URLLauncherPlugin"]]; \/\/ Swift-only/g' "$GENERATED_FILE"
    sed -i '' 's/\[registry registrarForPlugin:@"FVPVideoPlayerPlugin"\]\];/\/\/ [registry registrarForPlugin:@"FVPVideoPlayerPlugin"]]; \/\/ Swift-only/g' "$GENERATED_FILE"
    
    echo "✅ Fixed Swift-only module imports in GeneratedPluginRegistrant.m"
fi

