#!/bin/bash

# Patch GeneratedPluginRegistrant.m to fix Swift-only plugin module import issues
# This script runs during the build process to patch the file after Flutter generates it

GENERATED_FILE="${SRCROOT}/Runner/GeneratedPluginRegistrant.m"

if [ ! -f "$GENERATED_FILE" ]; then
    echo "⚠️ GeneratedPluginRegistrant.m not found, skipping patch"
    exit 0
fi

# Backup original
cp "$GENERATED_FILE" "${GENERATED_FILE}.bak"

# Fix app_links
sed -i '' 's/#else$/#elif __has_include(<app_links\/app_links-Swift.h>)\
#import <app_links\/app_links-Swift.h>\
#else\
\/\/ app_links is Swift-only, will be registered via Swift plugin registry\
#endif/g' "$GENERATED_FILE"

# Fix connectivity_plus  
sed -i '' 's/@import connectivity_plus;/\/\/ connectivity_plus is Swift-only, will be registered via Swift plugin registry/g' "$GENERATED_FILE"

# More robust approach: replace the entire pattern for each plugin
perl -i -pe 's/#if __has_include\(<app_links\/AppLinksIosPlugin\.h>\)\s*#import <app_links\/AppLinksIosPlugin\.h>\s*#else\s*@import app_links;\s*#endif/#if __has_include(<app_links\/AppLinksIosPlugin.h>)\n#import <app_links\/AppLinksIosPlugin.h>\n#elif __has_include(<app_links\/app_links-Swift.h>)\n#import <app_links\/app_links-Swift.h>\n#else\n\/\/ app_links is Swift-only\n#endif/gs' "$GENERATED_FILE"

perl -i -pe 's/#if __has_include\(<connectivity_plus\/ConnectivityPlusPlugin\.h>\)\s*#import <connectivity_plus\/ConnectivityPlusPlugin\.h>\s*#else\s*@import connectivity_plus;\s*#endif/#if __has_include(<connectivity_plus\/ConnectivityPlusPlugin.h>)\n#import <connectivity_plus\/ConnectivityPlusPlugin.h>\n#elif __has_include(<connectivity_plus\/connectivity_plus-Swift.h>)\n#import <connectivity_plus\/connectivity_plus-Swift.h>\n#else\n\/\/ connectivity_plus is Swift-only\n#endif/gs' "$GENERATED_FILE"

echo "✅ Patched GeneratedPluginRegistrant.m for Swift-only plugins"

