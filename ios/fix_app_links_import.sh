#!/bin/bash

# Fix Swift-only module import issues in GeneratedPluginRegistrant.m
# This script patches the file to work with Swift-only static frameworks

GENERATED_FILE="${SRCROOT}/Runner/GeneratedPluginRegistrant.m"

if [ -f "$GENERATED_FILE" ]; then
    # Comment out all @import statements for Swift-only modules that cause issues
    # These modules will be auto-registered by Flutter's Swift plugin system
    sed -i '' 's/@import app_links;/\/\/ @import app_links; \/\/ Swift-only, auto-registered/g' "$GENERATED_FILE"
    sed -i '' 's/@import connectivity_plus;/\/\/ @import connectivity_plus; \/\/ Swift-only, auto-registered/g' "$GENERATED_FILE"
    sed -i '' 's/@import firebase_core;/\/\/ @import firebase_core; \/\/ Swift-only, auto-registered/g' "$GENERATED_FILE"
    sed -i '' 's/@import firebase_messaging;/\/\/ @import firebase_messaging; \/\/ Swift-only, auto-registered/g' "$GENERATED_FILE"
    
    # Comment out registrations for plugins we can't import
    sed -i '' 's/\[AppLinksIosPlugin registerWithRegistrar:/\/\/ [AppLinksIosPlugin registerWithRegistrar:/g' "$GENERATED_FILE"
    sed -i '' 's/\[registry registrarForPlugin:@"AppLinksIosPlugin"\]\];/\/\/ [registry registrarForPlugin:@"AppLinksIosPlugin"]]; \/\/ Swift-only/g' "$GENERATED_FILE"
    
    echo "✅ Fixed Swift-only module imports in GeneratedPluginRegistrant.m"
fi

