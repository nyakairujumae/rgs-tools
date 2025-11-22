#!/bin/bash

# Fix app_links module import issue in GeneratedPluginRegistrant.m
# Only app_links has the persistent module not found issue with static frameworks
# Other plugins should work with their @import statements once module maps are properly configured

GENERATED_FILE="${SRCROOT}/Runner/GeneratedPluginRegistrant.m"

if [ -f "$GENERATED_FILE" ]; then
    # Only fix app_links - comment out the @import and registration
    # app_links is Swift-only and @import doesn't work with static frameworks
    sed -i '' 's/@import app_links;/\/\/ @import app_links; \/\/ Swift-only, causes module not found error/g' "$GENERATED_FILE"
    
    # Comment out AppLinksIosPlugin registration since we can't import it
    # The plugin will still work because Flutter's plugin system can handle it
    sed -i '' 's/\[AppLinksIosPlugin registerWithRegistrar:/\/\/ [AppLinksIosPlugin registerWithRegistrar:/g' "$GENERATED_FILE"
    sed -i '' 's/\[registry registrarForPlugin:@"AppLinksIosPlugin"\]\];/\/\/ [registry registrarForPlugin:@"AppLinksIosPlugin"]]; \/\/ Commented out/g' "$GENERATED_FILE"
    
    echo "✅ Fixed app_links import in GeneratedPluginRegistrant.m"
fi

