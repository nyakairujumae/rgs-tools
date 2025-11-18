#!/bin/bash
# Fix Firebase Messaging import issue
# This script patches the FLTFirebaseMessagingPlugin.h file to use FirebaseCore instead of Firebase

FIREBASE_PLUGIN_PATH="${PUB_CACHE:-$HOME/.pub-cache}/hosted/pub.dev/firebase_messaging-14.7.10/ios/Classes/FLTFirebaseMessagingPlugin.h"

if [ -f "$FIREBASE_PLUGIN_PATH" ]; then
    # Backup original
    cp "$FIREBASE_PLUGIN_PATH" "${FIREBASE_PLUGIN_PATH}.backup"
    
    # Replace the problematic import
    sed -i '' 's/#import <Firebase\/Firebase.h>/#import <FirebaseCore\/FirebaseCore.h>/g' "$FIREBASE_PLUGIN_PATH" 2>/dev/null || \
    sed -i 's/#import <Firebase\/Firebase.h>/#import <FirebaseCore\/FirebaseCore.h>/g' "$FIREBASE_PLUGIN_PATH"
    
    echo "✅ Patched Firebase Messaging plugin header"
else
    echo "⚠️ Firebase Messaging plugin header not found at $FIREBASE_PLUGIN_PATH"
fi
