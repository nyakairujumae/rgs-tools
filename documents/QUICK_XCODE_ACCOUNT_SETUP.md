# 🚀 Quick Guide: Add Paid Developer Account in Xcode

## Method 1: Through Xcode Menu (Easiest)

1. **Click on "Xcode" in the top menu bar** (next to the Apple logo)
2. **Look for one of these options**:
   - `Settings...` (newer Xcode versions - Xcode 14+)
   - `Preferences...` (older Xcode versions)
   - **Keyboard shortcut**: Press `Cmd + ,` (Command + Comma)

3. **In the window that opens**:
   - Click the **"Accounts"** tab at the top
   - You'll see a list of accounts (probably empty or showing your personal account)

4. **Click the `+` button** at the bottom left
5. **Select "Apple ID"**
6. **Enter your Apple ID** (the one with your paid Developer account)
7. **Enter your password**
8. **Click "Sign In"**

## Method 2: Directly Through Project Settings (Alternative)

Since you already have Xcode open with your project:

1. **In the left sidebar** (Project Navigator), click on the **blue "Runner" project icon** at the very top
2. **In the center pane**, you should see project settings
3. **Click on "Runner" under TARGETS** (in the left column)
4. **Click the "Signing & Capabilities" tab** at the top
5. **Under "Signing"**, you'll see a **"Team" dropdown**
6. **Click the dropdown** - if you see "Add an Account..." or "Manage Accounts...", click it
7. This will open the Accounts window where you can add your paid account

## Method 3: If You Still Can't Find It

Try these keyboard shortcuts:
- **`Cmd + ,`** (Command + Comma) - Opens Settings/Preferences
- **`Cmd + ;`** (Command + Semicolon) - Sometimes opens Accounts directly

Or:
1. **Go to menu**: `Window` → `Organizer` (or press `Cmd + Shift + 2`)
2. In Organizer, look for account settings

## ✅ After Adding Your Account

Once you've added your paid Developer account:

1. **Go back to your project** (if you left it)
2. **Select "Runner" target** (under TARGETS in the left column)
3. **Click "Signing & Capabilities" tab**
4. **Under "Team"**, select your **paid Developer team** (it should show your team name, not "Personal Team")
5. **Xcode will automatically**:
   - Create provisioning profiles
   - Configure signing
   - Enable capabilities

## 🎯 Visual Guide - What to Look For

When you open Settings/Preferences (`Cmd + ,`):
- You'll see tabs at the top: **General**, **Accounts**, **Behaviors**, **Navigation**, **Fonts & Colors**, **Text Editing**, **Key Bindings**, **Locations**, **Components**, **Source Control**
- **Click "Accounts" tab**
- You should see a list with a `+` button at the bottom

## 🚨 Still Can't Find It?

If you're using a very old version of Xcode:
- Try: `Xcode` menu → `Preferences...` (instead of Settings)
- Or: `Xcode` menu → `Account...` (if available)

## 📸 Quick Check

After adding your account, in the **Signing & Capabilities** tab, you should see:
- ✅ **Team**: Your paid Developer team name (e.g., "Your Company Name" or "Your Name")
- ✅ **Bundle Identifier**: `com.rgs.app`
- ✅ **Provisioning Profile**: Should auto-generate
- ✅ **Status**: Should show "Signing Certificate" and "Provisioning Profile" as valid

---

**Try pressing `Cmd + ,` first - that's the fastest way!**



