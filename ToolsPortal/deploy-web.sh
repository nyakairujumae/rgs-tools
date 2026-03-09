#!/bin/bash

echo "🚀 Deploying RGS Tools Web App..."

# Clean and rebuild
echo "📦 Building Flutter web app..."
flutter clean
flutter pub get
flutter build web --release

# Copy to public directory
echo "📁 Copying build files..."
rm -rf public
mkdir -p public
cp -r build/web/* public/

echo "✅ Web app ready for deployment!"
echo "📂 Files are in the 'public' directory"
echo "🌐 You can now drag and drop the 'public' folder to Netlify"
echo ""
echo "📋 Next steps:"
echo "1. Go to https://app.netlify.com"
echo "2. Drag and drop the 'public' folder"
echo "3. Your app will be live at the provided URL!"