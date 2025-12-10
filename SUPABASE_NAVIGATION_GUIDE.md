# Supabase Dashboard Navigation Guide

## 🎯 Exact Steps to Find Email Auth Settings

### **Step 1: Open Your Project**
1. Go to [supabase.com](https://supabase.com)
2. Click on your project: **"rgs tools"**

### **Step 2: Find Authentication (2 Ways)**

#### **Way 1: Left Sidebar**
```
Left Sidebar (Dark Area):
├── 🏠 Home
├── 📊 Table Editor  
├── 📝 SQL Editor
├── 🔑 Authentication  ← CLICK HERE
├── 🗄️ Database
└── ⚙️ Settings
```

#### **Way 2: Top Navigation**
```
Top Navigation Bar:
[Table Editor] [SQL Editor] [Authentication] [Database] [Storage] [Edge Functions]
                                    ↑
                              CLICK HERE
```

### **Step 3: Click on Settings**

After clicking "Authentication", you'll see:
```
Authentication Menu:
├── 👥 Users
├── ⚙️ Settings  ← CLICK HERE
├── 🔐 Policies
└── 📊 Reports
```

### **Step 4: Find Email Auth Section**

In Settings, scroll down to find:
```
Authentication Settings:
├── General
├── Email Auth          ← LOOK FOR THIS SECTION
│   ├── Enable email confirmations: [Toggle]
│   ├── Allowed email domains: [Text Input]
│   └── Disable email confirmations: [Checkbox]
├── Phone Auth
├── Social Auth
└── MFA
```

---

## 🔍 What Each Setting Does

### **"Enable email confirmations"**
- **What it is**: Toggle switch (ON/OFF)
- **What to do**: Turn it **OFF** (slide left to grey)
- **Why**: Prevents the need for email verification

### **"Allowed email domains"**
- **What it is**: Text input field
- **What to do**: Leave it **EMPTY** or add: `gmail.com, mekar.ae`
- **Why**: Allows all email domains

### **"Disable email confirmations"**
- **What it is**: Checkbox
- **What to do**: **Check this box** ✓
- **Why**: Skips email verification entirely

---

## 🚨 If You Still Can't Find It

### **Try These URLs:**
Replace `[your-project-id]` with your actual project ID:

```
https://supabase.com/dashboard/project/[your-project-id]/auth/settings
```

### **Or Try This Path:**
1. Click **"Settings"** in the left sidebar (gear icon ⚙️)
2. Look for **"Authentication"** in the settings menu
3. Click on **"Authentication"**
4. Look for **"Email"** or **"Email Auth"** section

### **Alternative Method:**
1. Go to **"Authentication"** → **"Users"**
2. Look for a **"Settings"** button at the top of the users page
3. Click **"Settings"**

---

## 📱 Mobile/Responsive View

If you're on a smaller screen:
1. Look for a **hamburger menu** (☰) in the top left
2. Tap it to open the sidebar
3. Find **"Authentication"** in the menu
4. Tap **"Settings"**

---

## 🔧 Quick Test

Once you find the settings, try this:

1. **Turn OFF** "Enable email confirmations"
2. **Leave empty** "Allowed email domains"  
3. **Check** "Disable email confirmations" if it exists
4. **Save** the settings
5. **Test** your Flutter app

---

## 💬 Still Can't Find It?

**Tell me:**
1. **What do you see** in the left sidebar?
2. **What do you see** when you click "Authentication"?
3. **Take a screenshot** and share it with me

I can guide you to the exact location! 🎯

---

## 🎯 The Goal

We need to find these settings and change them:
- ✅ **Email confirmations**: OFF
- ✅ **Domain restrictions**: NONE
- ✅ **Auto-confirm users**: ON

This will fix the "Database error granting user" issue! 🚀





