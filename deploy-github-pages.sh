#!/bin/bash
# Deploy RGS Tools web app to GitHub Pages (live at rgstools.app root)
# Usage: ./deploy-github-pages.sh [--no-clean]  (--no-clean skips flutter clean for faster redeploy)

set -e

NO_CLEAN=false
[[ "$1" == "--no-clean" ]] && NO_CLEAN=true

echo "🚀 Deploying RGS Tools to GitHub Pages (rgstools.app root)..."

# Build Flutter web app for root path
echo "📦 Building Flutter web app (base: /)..."
[[ "$NO_CLEAN" == false ]] && flutter clean
flutter pub get
flutter build web --release --base-href /

# Preserve GitHub Pages files
echo "📁 Preserving CNAME and static pages..."
CNAME_BACKUP=""
[[ -f docs/CNAME ]] && CNAME_BACKUP=$(cat docs/CNAME)

# Remove old docs/app (no longer used)
[[ -d docs/app ]] && rm -rf docs/app

# Preserve static pages
[[ -d docs/privacy ]] && mv docs/privacy /tmp/docs-privacy-bak
[[ -d docs/reset-password ]] && mv docs/reset-password /tmp/docs-reset-password-bak
[[ -d docs/support ]] && mv docs/support /tmp/docs-support-bak

# Remove existing docs content except CNAME
for item in docs/*; do
  [[ "$item" == "docs/CNAME" ]] && continue
  rm -rf "$item"
done

# Copy build output to docs root
echo "📂 Copying build to docs/..."
cp -r build/web/* docs/

# Restore preserved files
[[ -n "$CNAME_BACKUP" ]] && echo "$CNAME_BACKUP" > docs/CNAME
[[ -d /tmp/docs-privacy-bak ]] && mv /tmp/docs-privacy-bak docs/privacy
[[ -d /tmp/docs-reset-password-bak ]] && mv /tmp/docs-reset-password-bak docs/reset-password
[[ -d /tmp/docs-support-bak ]] && mv /tmp/docs-support-bak docs/support

echo "✅ Deploy files ready!"
echo ""
echo "📋 Next steps:"
echo "   git add docs/"
echo "   git commit -m 'Deploy web app to root (rgstools.app)'"
echo "   git push origin main"
echo ""
echo "🌐 App will be live at https://rgstools.app/"
