# PhaseScriptExecution Error Fix Guide

## ✅ What We Fixed

1. **Made `fix_app_links_import.sh` more robust**:
   - Added error handling with `set -euo pipefail`
   - Gracefully exits if `GeneratedPluginRegistrant.m` doesn't exist yet
   - Prevents script from failing during initial build phases

2. **Reinstalled CocoaPods dependencies**:
   - Ran `pod install --repo-update` to ensure everything is synced

## 🔍 If Error Persists

### Step 1: Check Xcode Build Log
1. Open Xcode
2. Press `⌘9` to open Report Navigator
3. Find the failed build
4. Expand the "Run Script" phase that failed
5. Look for the specific error message

### Step 2: Common Causes & Fixes

#### A. Missing FLUTTER_ROOT
**Error**: `FLUTTER_ROOT: unbound variable`

**Fix**: 
```bash
# In Xcode, go to: Runner target → Build Phases → Run Script
# Add at the top of the script:
export FLUTTER_ROOT=$(dirname $(dirname $(which flutter)))
```

#### B. Script Permission Issues
**Error**: `Permission denied`

**Fix**:
```bash
chmod +x ios/fix_app_links_import.sh
```

#### C. GeneratedPluginRegistrant.m Not Found
**Error**: `No such file or directory: GeneratedPluginRegistrant.m`

**Fix**: This is now handled - script exits gracefully if file doesn't exist yet.

#### D. Perl/Sed Not Found
**Error**: `perl: command not found` or `sed: command not found`

**Fix**: These should be available on macOS. If not:
```bash
# Check if they exist
which perl
which sed

# If missing, install via Homebrew
brew install perl
```

### Step 3: Clean Build
```bash
# Clean Flutter
flutter clean

# Clean Xcode
cd ios
rm -rf Pods Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Reinstall
pod install
cd ..

# Get dependencies
flutter pub get
```

### Step 4: Check Script Phase Order
In Xcode → Runner target → Build Phases:
1. **Run Script** (Flutter build) should run BEFORE **Copy Pods Resources**
2. **fix_app_links_import.sh** should run AFTER Flutter build

### Step 5: Disable Script Sandboxing (if needed)
In `ios/Podfile`, we already have:
```ruby
config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
```

If error persists, also check:
- Xcode → Runner target → Build Settings
- Search for "ENABLE_USER_SCRIPT_SANDBOXING"
- Set to "No" for Debug and Release

## 🧪 Test the Script Manually

```bash
cd ios
export SRCROOT=$(pwd)
./fix_app_links_import.sh
```

Should output: `✅ Fixed Swift-only module imports in GeneratedPluginRegistrant.m` or `⚠️ GeneratedPluginRegistrant.m not found yet, skipping fix`

## 📝 Next Steps

1. Try building again in Xcode
2. If it fails, check the build log for the specific error
3. Share the exact error message for further troubleshooting



