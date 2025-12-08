#!/bin/bash

# Fix Swift-only module import issues in GeneratedPluginRegistrant.m
# When using dynamic frameworks, @import may not work for Swift-only modules
# This script comments out problematic @import statements
# The plugins will still work because Flutter's plugin system handles Swift plugins automatically

set -euo pipefail

GENERATED_FILE="${SRCROOT}/Runner/GeneratedPluginRegistrant.m"

# Exit gracefully if file doesn't exist yet (it will be generated during build)
if [ ! -f "$GENERATED_FILE" ]; then
    echo "⚠️ GeneratedPluginRegistrant.m not found yet, skipping fix (will be generated during build)"
    exit 0
fi

if [ -f "$GENERATED_FILE" ]; then
    # List of Swift-only plugins that cause @import issues with static frameworks
    # Comment out their @import statements - the plugins will be auto-registered
    # Note: open_file_ios is NOT in this list because we need it to work for PDF opening
    SWIFT_ONLY_PLUGINS=("app_links" "connectivity_plus" "firebase_core" "firebase_messaging" "flutter_app_badger" "flutter_local_notifications" "flutter_native_splash" "image_picker_ios" "mobile_scanner" "printing" "shared_preferences_foundation" "sqflite_darwin" "url_launcher_ios" "video_player_avfoundation")
    
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
    # Ensure OpenFilePlugin is NOT commented out - it's needed for opening PDFs
    # The plugin is Swift-only, so we need to uncomment the @import
    # Replace the commented @import with an active @import
    sed -i '' 's|// @import open_file_ios; // Swift-only, auto-registered|@import open_file_ios;|g' "$GENERATED_FILE"
    # Uncomment the registration if it was commented
    sed -i '' 's|^  // \[OpenFilePlugin registerWithRegistrar:\[registry registrarForPlugin:@"OpenFilePlugin"\]\]; // Swift-only$|  [OpenFilePlugin registerWithRegistrar:[registry registrarForPlugin:@"OpenFilePlugin"]];|g' "$GENERATED_FILE"
    # Also handle if it was commented with dynamic registration - remove those lines
    perl -i -0pe 's/  \/\/ Use dynamic registration for OpenFilePlugin to avoid import issues\n  Class OpenFilePluginClass = NSClassFromString\(@"OpenFilePlugin"\);\n  if \(OpenFilePluginClass\) \{\n    \[OpenFilePluginClass performSelector:@selector\(registerWithRegistrar:\) withObject:\[registry registrarForPlugin:@"OpenFilePlugin"\]\];\n  \}//g' "$GENERATED_FILE"
    # Ensure the registration line exists and is not commented
    if ! grep -q "^  \[OpenFilePlugin registerWithRegistrar:" "$GENERATED_FILE"; then
        # Find the line after MobileScannerPlugin and add OpenFilePlugin registration
        perl -i -0pe 's/(\[MobileScannerPlugin registerWithRegistrar:\[registry registrarForPlugin:@"MobileScannerPlugin"\]\]; \/\/ Swift-only\n)/$1  [OpenFilePlugin registerWithRegistrar:[registry registrarForPlugin:@"OpenFilePlugin"]];\n/g' "$GENERATED_FILE"
    fi
    perl -i -0pe 's/^\s*\[PrintingPlugin registerWithRegistrar:\[registry registrarForPlugin:@"PrintingPlugin"\]\];\s*$/\n  \/\/ [PrintingPlugin registerWithRegistrar:[registry registrarForPlugin:@"PrintingPlugin"]]; \/\/ Swift-only\n/gm' "$GENERATED_FILE"
    perl -i -0pe 's/^\s*\[SharedPreferencesPlugin registerWithRegistrar:\[registry registrarForPlugin:@"SharedPreferencesPlugin"\]\];\s*$/\n  \/\/ [SharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharedPreferencesPlugin"]]; \/\/ Swift-only\n/gm' "$GENERATED_FILE"
    perl -i -0pe 's/^\s*\[SqflitePlugin registerWithRegistrar:\[registry registrarForPlugin:@"SqflitePlugin"\]\];\s*$/\n  \/\/ [SqflitePlugin registerWithRegistrar:[registry registrarForPlugin:@"SqflitePlugin"]]; \/\/ Swift-only\n/gm' "$GENERATED_FILE"
    perl -i -0pe 's/^\s*\[URLLauncherPlugin registerWithRegistrar:\[registry registrarForPlugin:@"URLLauncherPlugin"\]\];\s*$/\n  \/\/ [URLLauncherPlugin registerWithRegistrar:[registry registrarForPlugin:@"URLLauncherPlugin"]]; \/\/ Swift-only\n/gm' "$GENERATED_FILE"
    perl -i -0pe 's/^\s*\[FVPVideoPlayerPlugin registerWithRegistrar:\[registry registrarForPlugin:@"FVPVideoPlayerPlugin"\]\];\s*$/\n  \/\/ [FVPVideoPlayerPlugin registerWithRegistrar:[registry registrarForPlugin:@"FVPVideoPlayerPlugin"]]; \/\/ Swift-only\n/gm' "$GENERATED_FILE"
    
    echo "✅ Fixed Swift-only module imports in GeneratedPluginRegistrant.m"
else
    echo "⚠️ GeneratedPluginRegistrant.m not found, skipping fix"
fi

