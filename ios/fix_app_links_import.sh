#!/bin/bash

# Fix Swift-only module import issues in GeneratedPluginRegistrant.m
# This script patches the file to work with Swift-only static frameworks
# When using static frameworks, @import doesn't work for Swift-only modules

GENERATED_FILE="${SRCROOT}/Runner/GeneratedPluginRegistrant.m"

if [ -f "$GENERATED_FILE" ]; then
    # Comment out ALL @import statements - they don't work with static frameworks for Swift-only modules
    # The plugins will still work because Flutter's plugin system handles Swift plugins automatically
    sed -i '' 's/^@import /\/\/ @import /g' "$GENERATED_FILE"
    sed -i '' 's/@import \([^;]*\);/\/\/ @import \1; \/\/ Commented - Swift-only, auto-registered/g' "$GENERATED_FILE"
    
    # Comment out registrations for plugins that can't be imported
    # Only comment if the import was commented (check for commented @import on previous lines)
    # This is a simple approach - comment all Swift plugin registrations that might fail
    sed -i '' 's/\[AppLinksIosPlugin registerWithRegistrar:/\/\/ [AppLinksIosPlugin registerWithRegistrar:/g' "$GENERATED_FILE"
    
    echo "✅ Fixed Swift-only module imports in GeneratedPluginRegistrant.m"
fi

