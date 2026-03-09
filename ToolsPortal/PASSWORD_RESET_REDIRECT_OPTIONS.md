# Password Reset Redirect Options

## Current Situation

The code is currently set to use:
```dart
final redirectUrl = redirectTo ?? 'https://rgstools.app/reset-password';
```

This means the password reset email contains a link to `https://rgstools.app/reset-password`, which then needs to redirect to the app deep link `com.rgs.app://reset-password`.

## Two Options

### Option 1: Direct Deep Link (Simpler - Recommended) ⭐

**Use the app deep link directly in the email.**

**Pros:**
- ✅ No web page needed
- ✅ Works immediately
- ✅ Simpler setup
- ✅ One less thing to maintain

**Cons:**
- ⚠️ Some email clients might flag it as suspicious (but less likely with proper email template)

**Implementation:**
Change the redirect URL back to direct deep link:
```dart
final redirectUrl = redirectTo ?? 'com.rgs.app://reset-password';
```

**Supabase Configuration:**
- Add `com.rgs.app://reset-password` to redirect URLs
- Site URL: `com.rgs.app://`

---

### Option 2: Web Redirect Page (More Professional)

**Create a web page that redirects to the app.**

**Pros:**
- ✅ More professional
- ✅ Less likely to be flagged by email clients
- ✅ Can show loading/instructions while redirecting
- ✅ Works on desktop (opens web page if app not installed)

**Cons:**
- ⚠️ Requires creating and hosting a web page
- ⚠️ More setup required
- ⚠️ Need to maintain the web page

**Implementation:**

1. **Create a web page** at `https://rgstools.app/reset-password` (or your domain)

2. **The page should:**
   - Extract tokens from URL query parameters
   - Redirect to app deep link: `com.rgs.app://reset-password?access_token=xxx&refresh_token=xxx&type=recovery`
   - Show loading message while redirecting
   - Handle case where app is not installed (show instructions)

3. **Example HTML page:**
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Password - RGS Tools</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            background: #f5f5f5;
        }
        .container {
            text-align: center;
            padding: 40px;
            background: white;
            border-radius: 12px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .spinner {
            border: 4px solid #f3f3f3;
            border-top: 4px solid #4CAF50;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 20px auto;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>RGS Tools</h1>
        <p>Opening app to reset your password...</p>
        <div class="spinner"></div>
        <p style="color: #666; font-size: 14px; margin-top: 20px;">
            If the app doesn't open, <a href="#" id="manualLink">click here</a>
        </p>
    </div>

    <script>
        // Get URL parameters
        const urlParams = new URLSearchParams(window.location.search);
        const accessToken = urlParams.get('access_token');
        const refreshToken = urlParams.get('refresh_token');
        const type = urlParams.get('type');

        // Build deep link
        const deepLink = `com.rgs.app://reset-password?access_token=${accessToken}&refresh_token=${refreshToken}&type=${type || 'recovery'}`;
        
        // Set manual link
        document.getElementById('manualLink').href = deepLink;

        // Try to open app
        window.location.href = deepLink;

        // Fallback: If app doesn't open after 2 seconds, show instructions
        setTimeout(() => {
            document.querySelector('.container').innerHTML = `
                <h1>RGS Tools</h1>
                <p>Please open the RGS Tools app to reset your password.</p>
                <p style="color: #666; font-size: 14px;">
                    If you have the app installed, <a href="${deepLink}">click here</a> to open it.
                </p>
                <p style="color: #999; font-size: 12px; margin-top: 20px;">
                    Or copy this link and open it in your device:<br>
                    <code style="font-size: 10px; word-break: break-all;">${deepLink}</code>
                </p>
            `;
        }, 2000);
    </script>
</body>
</html>
```

4. **Host this page** at `https://rgstools.app/reset-password`

5. **Keep the code as is:**
```dart
final redirectUrl = redirectTo ?? 'https://rgstools.app/reset-password';
```

---

## Recommendation

**For now, use Option 1 (Direct Deep Link)** because:
- ✅ Works immediately
- ✅ No web hosting needed
- ✅ Simpler to maintain
- ✅ Email template improvements should reduce flagging

**Later, if needed, implement Option 2** for:
- Better user experience
- Professional appearance
- Desktop support

---

## How to Switch to Direct Deep Link

Update `lib/providers/auth_provider.dart`:

```dart
Future<void> resetPassword(String email, {String? redirectTo}) async {
  try {
    // Use direct deep link (simpler, no web page needed)
    final redirectUrl = redirectTo ?? 'com.rgs.app://reset-password';
    
    await SupabaseService.client.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectUrl,
    );
  } catch (e) {
    debugPrint('Error resetting password: $e');
    rethrow;
  }
}
```

**Supabase Configuration:**
1. Go to **Authentication** → **URL Configuration**
2. Add redirect URL: `com.rgs.app://reset-password`
3. Set Site URL: `com.rgs.app://`
4. Save

---

## Current Flow (with web redirect)

1. User clicks link in email → `https://rgstools.app/reset-password?token=xxx`
2. Web page loads → Extracts tokens → Redirects to `com.rgs.app://reset-password?token=xxx`
3. App opens → Handles deep link → Shows reset password screen

## Simplified Flow (direct deep link)

1. User clicks link in email → `com.rgs.app://reset-password?token=xxx`
2. App opens directly → Shows reset password screen

**Much simpler!**



