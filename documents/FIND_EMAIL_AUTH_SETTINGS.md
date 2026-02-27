# How to Find Email Auth Settings in Supabase Dashboard

## 🎯 Step-by-Step Guide

### **Step 1: Open Supabase Dashboard**
1. Go to [supabase.com](https://supabase.com)
2. Sign in to your account
3. Click on your project: **"rgs tools"**

### **Step 2: Navigate to Authentication Settings**

#### **Method A: Using the Left Sidebar**
1. Look at the **left sidebar** (the dark area on the left)
2. Find the section called **"AUTHENTICATION"** (it has a key icon 🔑)
3. Click on **"Authentication"** to expand it
4. Click on **"Settings"** (it's usually the first option under Authentication)

#### **Method B: Using the Top Navigation**
1. Look at the **top of the page** (below the project name "rgs tools")
2. You should see tabs like: **"Table Editor"**, **"SQL Editor"**, **"Authentication"**, etc.
3. Click on **"Authentication"** tab
4. Then click on **"Settings"** in the left sidebar

### **Step 3: Find Email Auth Section**

Once you're in Authentication → Settings, you'll see several sections:

1. **"General"** (at the top)
2. **"Email Auth"** ← **THIS IS WHAT WE NEED!**
3. **"Phone Auth"**
4. **"Social Auth"**
5. **"SAML"**
6. **"MFA"**

### **Step 4: Look for These Settings in "Email Auth"**

In the **"Email Auth"** section, you should see:

#### **A. "Enable email confirmations"**
- This is a **toggle switch** (ON/OFF)
- **Turn this OFF** (slide it to the left/grey)

#### **B. "Allowed email domains"**
- This might be a text input field
- **Leave it empty** or add: `gmail.com, mekar.ae, outlook.com`

#### **C. "Disable email confirmations"**
- This might be a checkbox
- **Check this box** if it exists

---

## 🖼️ Visual Guide

### **What You Should See:**

```
Supabase Dashboard
├── Left Sidebar
│   ├── 🏠 Home
│   ├── 📊 Table Editor
│   ├── 📝 SQL Editor
│   ├── 🔑 Authentication  ← CLICK HERE
│   │   ├── Settings       ← THEN CLICK HERE
│   │   ├── Users
│   │   └── Policies
│   ├── 🗄️ Database
│   └── ...
```

### **In Authentication Settings, Look For:**

```
Authentication Settings
├── General
├── Email Auth          ← THIS SECTION
│   ├── Enable email confirmations: [OFF]  ← TURN OFF
│   ├── Allowed email domains: [empty]     ← LEAVE EMPTY
│   └── Disable email confirmations: [✓]   ← CHECK THIS
├── Phone Auth
└── Social Auth
```

---

## 🚨 If You Can't Find It

### **Alternative Method:**
1. Go to **"Authentication"** in the left sidebar
2. Click on **"Users"** (not Settings)
3. Look for a **"Settings"** or **"Configuration"** button at the top
4. Or look for a **gear icon** ⚙️

### **If Still Can't Find:**
1. Try the **URL directly**: `https://supabase.com/dashboard/project/[your-project-id]/auth/settings`
2. Or look for **"Project Settings"** in the left sidebar
3. Then look for **"Authentication"** within project settings

---

## 📱 Mobile/Tablet Users

If you're on mobile or tablet:
1. Look for a **hamburger menu** (☰) in the top left
2. Tap it to open the sidebar
3. Find **"Authentication"** → **"Settings"**

---

## 🔍 What to Look For

The key settings we need to change:

### **✅ Turn OFF:**
- "Enable email confirmations"
- "Require email verification"
- "Email confirmation required"

### **✅ Turn ON:**
- "Disable email confirmations"
- "Skip email verification"

### **✅ Leave Empty:**
- "Allowed email domains"
- "Email domain restrictions"

---

## 💡 Pro Tip

If you're still having trouble finding it:

1. **Take a screenshot** of your Supabase Dashboard
2. **Share it with me** - I can point out exactly where to click
3. Or try **searching** for "email" in the dashboard (Ctrl+F or Cmd+F)

The settings are definitely there - we just need to find the right path! 🎯





