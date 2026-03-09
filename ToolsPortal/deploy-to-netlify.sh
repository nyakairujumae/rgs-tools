#!/bin/bash

echo "🚀 Deploying RGS Tools to Netlify..."

# Ensure we have the latest build
echo "📦 Building Flutter web app..."
flutter clean
flutter pub get
flutter build web --release

# Copy to public directory
echo "📁 Copying build files..."
rm -rf public
mkdir -p public
cp -r build/web/* public/

# Copy netlify config
cp netlify.toml public/

echo "✅ Files ready for Netlify deployment!"
echo ""
echo "📂 Files are in the 'public' directory"
echo "🌐 Deploy instructions:"
echo "1. Go to https://app.netlify.com"
echo "2. Drag and drop the 'public' folder"
echo "3. Wait for deployment to complete"
echo "4. Your app will be live!"
echo ""
echo "📋 Alternative: Use Netlify CLI"
echo "npm install -g netlify-cli"
echo "netlify deploy --dir=public --prod"



