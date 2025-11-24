#!/bin/bash
# Script to fix GoogleDataTransport version conflict between Firebase and MLKit
# This script modifies the Podfile.lock to use GoogleDataTransport 10.1.0

PODFILE_LOCK="Podfile.lock"

if [ ! -f "$PODFILE_LOCK" ]; then
    echo "Podfile.lock not found. Run 'pod install' first."
    exit 1
fi

echo "Attempting to fix GoogleDataTransport version conflict..."

# Backup Podfile.lock
cp "$PODFILE_LOCK" "${PODFILE_LOCK}.backup"

# Replace GoogleDataTransport 9.x with 10.1.0 in Podfile.lock
sed -i '' 's/GoogleDataTransport ([^)]*9\.[^)]*)/GoogleDataTransport (10.1.0)/g' "$PODFILE_LOCK"

echo "Modified Podfile.lock. You may need to run 'pod install --repo-update' again."
echo "Note: This is a workaround. MLKit may not work correctly with GoogleDataTransport 10.1.0."




