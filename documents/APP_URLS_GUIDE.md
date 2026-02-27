# App URLs Configuration Guide for Supabase

This guide explains how to get and configure your app URLs for Supabase Authentication.

## 📱 Your App Identifiers

Based on your app configuration:
- **iOS Bundle ID**: `com.rgs.app`
- **Android Package**: `com.rgs.app`
- **App Name**: RGS

---

## 🔗 URLs You Need for Supabase

### 1. **Mobile App Deep Link URLs** (Required)

For mobile apps, Supabase uses deep link URLs based on your bundle ID/package name.

#### iOS Deep Links:
```
com.rgs.app://
com.rgs.app://callback
com.rgs.app://auth/callback
```

#### Android Deep Links:
```
com.rgs.app://
com.rgs.app://callback
com.rgs.app://auth/callback
```

**Note**: Both iOS and Android use the same format: `{bundle-id}://`

---

### 2. **Web URLs** (If you have a web version)

If you deploy your Flutter web app, you'll need:

```
https://yourdomain.com
https://yourdomain.com/callback
https://yourdomain.com/auth/callback
```

**Replace `yourdomain.com` with your actual domain.**

---

### 3. **Site URL** (Main URL)

This is the primary URL Supabase uses for redirects. For mobile apps, use:
```
com.rgs.app://
```

For web apps, use:
```
https://yourdomain.com
```

---

## ⚙️ How to Configure in Supabase

### Step 1: Go to Authentication → URL Configuration

1. Open your Supabase Dashboard
2. Navigate to **Authentication** → **URL Configuration**
3. You'll see two sections:
   - **Site URL**
   - **Redirect URLs**

### Step 2: Set Site URL

**For Mobile App (iOS/Android):**
```
com.rgs.app://
```

**For Web App:**
```
https://yourdomain.com
```

### Step 3: Add Redirect URLs

Click **"Add URL"** and add each of these (one at a time):

#### Mobile App URLs:
```
com.rgs.app://
com.rgs.app://callback
com.rgs.app://auth/callback
```

#### Web URLs (if applicable):
```
https://yourdomain.com
https://yourdomain.com/callback
https://yourdomain.com/auth/callback
```

#### Development URLs (optional, for testing):
```
http://localhost:*
http://localhost:8080
http://localhost:8080/callback
```

---

## 🔧 Configure URL Schemes in Your App

### For iOS (Info.plist)

You need to add URL schemes to your `ios/Runner/Info.plist`. Add this inside the `<dict>` tag:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.rgs.app</string>
        </array>
    </dict>
</array>
```

### For Android (AndroidManifest.xml)

Add this inside the `<activity>` tag in `android/app/src/main/AndroidManifest.xml`:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="com.rgs.app" />
</intent-filter>
```

---

## 📝 Complete Supabase Configuration Example

### Site URL:
```
com.rgs.app://
```

### Redirect URLs (add all of these):
```
com.rgs.app://
com.rgs.app://callback
com.rgs.app://auth/callback
```

**If you have a web version, also add:**
```
https://yourdomain.com
https://yourdomain.com/callback
https://yourdomain.com/auth/callback
```

---

## 🧪 Testing Your URLs

### Test Deep Links on iOS:
1. Open Safari on your iPhone
2. Type in the address bar: `com.rgs.app://callback`
3. Your app should open (if installed)

### Test Deep Links on Android:
1. Open Chrome on your Android device
2. Type in the address bar: `com.rgs.app://callback`
3. Your app should open (if installed)

### Test in Supabase:
1. Try signing up/logging in through your app
2. After authentication, Supabase should redirect back to your app
3. Check the Supabase logs if redirects fail

---

## 🚨 Common Issues

### Issue 1: "Invalid redirect URL"
**Solution**: Make sure the exact URL is added to Supabase's Redirect URLs list. URLs are case-sensitive and must match exactly.

### Issue 2: App doesn't open after authentication
**Solution**: 
- Verify URL schemes are configured in Info.plist (iOS) and AndroidManifest.xml (Android)
- Check that the redirect URL in Supabase matches your app's URL scheme

### Issue 3: "Redirect URL not allowed"
**Solution**: 
- Go to Supabase → Authentication → URL Configuration
- Add the exact redirect URL that's being used
- URLs must match exactly (including trailing slashes)

---

## 📋 Quick Checklist

- [ ] Site URL set in Supabase: `com.rgs.app://`
- [ ] Redirect URLs added in Supabase:
  - [ ] `com.rgs.app://`
  - [ ] `com.rgs.app://callback`
  - [ ] `com.rgs.app://auth/callback`
- [ ] iOS URL scheme configured in `Info.plist`
- [ ] Android URL scheme configured in `AndroidManifest.xml`
- [ ] Tested deep link opening the app
- [ ] Tested authentication redirect

---

## 🌐 If You Deploy a Web Version

If you plan to deploy your Flutter app as a web app:

1. **Get your web domain** (e.g., `https://rgs-tools.com`)

2. **Add to Supabase Site URL:**
   ```
   https://rgs-tools.com
   ```

3. **Add to Redirect URLs:**
   ```
   https://rgs-tools.com
   https://rgs-tools.com/callback
   https://rgs-tools.com/auth/callback
   ```

4. **Configure CORS** in Supabase:
   - Go to **Settings → API → CORS**
   - Add your domain: `https://rgs-tools.com`

---

## 💡 Pro Tips

1. **Use wildcards for development**: You can use `http://localhost:*` to allow any localhost port
2. **Test in production mode**: Some redirects only work in release builds
3. **Check Supabase logs**: If redirects fail, check Authentication → Logs
4. **Keep URLs consistent**: Use the same URL format across your app and Supabase

---

## 📞 Need Help?

If you're still having issues:
1. Check Supabase Authentication logs
2. Verify your bundle ID matches exactly
3. Test with a simple deep link first
4. Check that your app is properly signed (for iOS)



