# API Key Configuration - Step-by-Step Guide

**Date:** January 6, 2026  
**Status:** Configuration Guide  
**Purpose:** Step-by-step instructions to provide API keys for secure configuration

---

## 🎯 **OVERVIEW**

This guide walks you through:
1. **Getting** the required API keys from providers
2. **Providing** them to me securely
3. **What I'll do** to configure them correctly
4. **Verification** that everything works

**Security:** All keys will be configured via environment variables or secure config files that are **NOT committed to git**.

---

## 📋 **REQUIRED API KEYS**

### **Priority 1 (Core Functionality):**
- ✅ **Google Places API Key** - For place list generation
- ✅ **Google Maps SDK Key (Android)** - For native map display on Android
- ✅ **Google Maps SDK Key (iOS)** - For native map display on iOS
- ✅ **Google OAuth Client ID (Android)** - For Google Sign-In on Android
- ✅ **Google OAuth Client ID (iOS)** - For Google Sign-In on iOS
- ✅ **OpenWeatherMap API Key** - For weather data (one key for both platforms)

### **Priority 2 (Optional - Social Media):**
- ⚠️ **Instagram OAuth** - Client ID + Secret
- ⚠️ **Facebook OAuth** - Client ID + Secret

**Note:** Google Maps SDK keys are **different** from Google Places API key. You need both:
- **Places API** = For searching/finding places (works on all platforms - HTTP-based)
- **Maps SDK** = For displaying the map itself (Android/iOS only - native SDK)

**Platform Strategy:**
- **Android:** Google Maps SDK (primary) - requires `GOOGLE_MAPS_ANDROID_API_KEY`
- **iOS:** Google Maps SDK (when enabled via `ENABLE_IOS_GOOGLE_MAPS`) - requires `GOOGLE_MAPS_IOS_API_KEY`
- **macOS/Windows/Linux/Web:** flutter_map (OpenStreetMap) - no Google Maps SDK keys needed
- **All platforms:** Google Places API works via HTTP (requires `GOOGLE_PLACES_API_KEY`)

---

## 🔑 **STEP 1: GET GOOGLE PLACES API KEY**

### **1.1: Go to Google Cloud Console**
1. Visit: https://console.cloud.google.com/
2. Sign in with your Google account

### **1.2: Create or Select Project**
1. Click the project dropdown at the top
2. Click "New Project" (or select existing)
3. Name it: "AVRAI" or "SPOTS"
4. Click "Create"

### **1.3: Enable Places API (New)**
1. Go to **"APIs & Services"** → **"Library"**
2. Search for: **"Places API (New)"**
3. Click on it
4. Click **"Enable"**
5. ⚠️ **Important:** Make sure it's **"Places API (New)"** not the legacy "Places API"

### **1.4: Create API Key**
1. Go to **"APIs & Services"** → **"Credentials"**
2. Click **"Create Credentials"** → **"API Key"**
3. Copy the API key (starts with `AIzaSy...`)
4. **Save this key** - you'll provide it to me in Step 3


### **1.5: Restrict API Key (Recommended)**
1. Click on the API key you just created
2. Under **"API restrictions"**, select **"Restrict key"**
3. Check only **"Places API (New)"**
4. Under **"Application restrictions"**, you can:
   - **Android:** Add package name: `com.avrai.app` + SHA-1 fingerprint
   - **iOS:** Add bundle ID: `com.avrai.app`
5. Click **"Save"**

**✅ You now have:** Google Places API Key (starts with `AIzaSy...`)

---

## 🗺️ **STEP 2: GET GOOGLE MAPS SDK KEYS**

**Important:** These are **different** from the Places API key. Maps SDK keys are for displaying the map itself.

### **2.1: Enable Maps SDK for Android**
1. In the same Google Cloud project, go to **"APIs & Services"** → **"Library"**
2. Search for: **"Maps SDK for Android"**
3. Click on it and click **"Enable"**

### **2.2: Enable Maps SDK for iOS**
1. Still in **"APIs & Services"** → **"Library"**
2. Search for: **"Maps SDK for iOS"**
3. Click on it and click **"Enable"**

### **2.3: Create Maps SDK API Keys**
You can use the **same API key** for both Maps SDK and Places API, OR create separate keys for better security.

**Option A: Use Same Key (Easier)**
- Use the same API key from Step 1.1.4
- Just make sure both "Places API (New)" and "Maps SDK for Android/iOS" are enabled

**Option B: Create Separate Keys (More Secure)**
1. Go to **"APIs & Services"** → **"Credentials"**
2. Click **"Create Credentials"** → **"API Key"**
3. Create two separate keys:
   - **Android Maps SDK Key** - Restrict to "Maps SDK for Android"
   - **iOS Maps SDK Key** - Restrict to "Maps SDK for iOS"
4. Copy both keys

**✅ You now have:**
- Google Maps SDK Key (Android) - Can be same as Places API or separate
- Google Maps SDK Key (iOS) - Can be same as Places API or separate

**Note:** For simplicity, you can use the same API key from Step 1 for all Google services (Places + Maps SDK). Just enable all three APIs (Places API New, Maps SDK Android, Maps SDK iOS) for that key.

---

## 🌦️ **STEP 3: GET OPENWEATHERMAP API KEY**

### **3.1: Sign Up for OpenWeatherMap**
1. Go to: https://openweathermap.org/api
2. Click **"Sign Up"** (top right)
3. Fill in:
   - **Username:** Choose a username
   - **Email:** Your email
   - **Password:** Create password
4. Click **"Create Account"**
5. Check your email and verify your account

### **3.2: Get API Key**
1. After logging in, go to: https://home.openweathermap.org/api_keys
2. You'll see your **default API key** (starts with random characters)
3. Copy the API key
4. **Save this key** - you'll provide it to me in Step 6

**Free Tier:**
- 1,000 calls/day
- 60 calls/minute
- Current weather + forecast
- Usually sufficient for development

**✅ You now have:** OpenWeatherMap API Key

**Note:** This is **one key for both iOS and Android** - not separate keys.

---

## 🔐 **STEP 4: GET GOOGLE OAUTH CLIENT IDs**

### **2.1: Configure OAuth Consent Screen**
1. In Google Cloud Console, go to **"APIs & Services"** → **"OAuth consent screen"**
2. Select **"External"** (or Internal if using Google Workspace)
3. Fill in:
   - **App name:** "AVRAI"
   - **User support email:** Your email
   - **Developer contact:** Your email
4. Click **"Save and Continue"** through:
   - Scopes (click "Save and Continue")
   - Test users (click "Save and Continue")
   - Summary (click "Back to Dashboard")

### **2.2: Get Android OAuth Client ID**
1. Go to **"APIs & Services"** → **"Credentials"**
2. Click **"Create Credentials"** → **"OAuth client ID"**
3. Select **"Android"** as application type
4. Fill in:
   - **Name:** "AVRAI Android"
   - **Package name:** `com.avrai.app`
   - **SHA-1 certificate fingerprint:** Get with:
     ```bash
     # For debug keystore (development):
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     
     # Look for "SHA1:" line, copy the value (without spaces)
     ```
5. Click **"Create"**
6. Copy the **Client ID** (looks like: `123456789-abcdefg.apps.googleusercontent.com`)
7. **Save this** - you'll provide it to me in Step 3

### **2.3: Get iOS OAuth Client ID**
1. Still in **"APIs & Services"** → **"Credentials"**
2. Click **"Create Credentials"** → **"OAuth client ID"**
3. Select **"iOS"** as application type
4. Fill in:
   - **Name:** "AVRAI iOS"
   - **Bundle ID:** `com.avrai.app`
5. Click **"Create"**
6. Copy the **Client ID** (looks like: `123456789-xyz.apps.googleusercontent.com`)
7. **Save this** - you'll provide it to me in Step 3

**✅ You now have:**
- Google OAuth Client ID (Android)
- Google OAuth Client ID (iOS)

---

## 📸 **STEP 5: GET INSTAGRAM OAUTH (OPTIONAL)**

### **3.1: Create Instagram App**
1. Go to: https://developers.facebook.com/
2. Click **"My Apps"** → **"Create App"**
3. Select **"Consumer"** app type
4. Fill in:
   - **App name:** "AVRAI"
   - **App contact email:** Your email
5. Click **"Create App"**

### **3.2: Add Instagram Basic Display**
1. In your app dashboard, click **"Add Product"**
2. Find **"Instagram Basic Display"** → Click **"Set Up"**
3. Fill in:
   - **Valid OAuth Redirect URIs:** `avrai://oauth/instagram/callback`
   - **Deauthorize Callback URL:** `avrai://oauth/instagram/deauthorize`
4. Click **"Save Changes"**

### **3.3: Get Credentials**
1. Go to **"Settings"** → **"Basic"**
2. Copy:
   - **App ID** (this is your Client ID)
   - **App Secret** (click "Show" to reveal)
3. **Save both** - you'll provide them to me in Step 3

**✅ You now have:**
- Instagram OAuth Client ID
- Instagram OAuth Client Secret

---

## 📘 **STEP 6: GET FACEBOOK OAUTH (OPTIONAL)**

### **4.1: Use Same Facebook App**
1. In the same Facebook app from Step 3
2. Go to **"Settings"** → **"Basic"**
3. The **App ID** and **App Secret** are the same as Instagram
4. **OR** create a separate Facebook app if preferred

### **4.2: Configure Facebook Login**
1. Click **"Add Product"** → **"Facebook Login"** → **"Set Up"**
2. Go to **"Settings"** → **"Facebook Login"** → **"Settings"**
3. Add **Valid OAuth Redirect URIs:**
   - `avrai://oauth/facebook/callback`
4. Click **"Save Changes"**

**✅ You now have:**
- Facebook OAuth Client ID (same as App ID)
- Facebook OAuth Client Secret (same as App Secret)

---

## 📝 **STEP 7: PROVIDE KEYS TO ME**

### **7.1: Format Your Response**

Provide the keys in this format (you can paste directly in chat):

```
=== API KEYS FOR CONFIGURATION ===

GOOGLE PLACES API KEY:
AAIzaSyAoxKJs4KwW51XOLQ7QZkjJAFvU0jOXlIQ

GOOGLE MAPS SDK KEY (ANDROID):
AIzaSyAoxKJs4KwW51XOLQ7QZkjJAFvU0jOXlIQ

GOOGLE MAPS SDK KEY (iOS):
AIzaSyAoxKJs4KwW51XOLQ7QZkjJAFvU0jOXlIQ

GOOGLE WEATHER API KEY:
AIzaSyAoxKJs4KwW51XOLQ7QZkjJAFvU0jOXlIQ

GOOGLE OAUTH CLIENT ID (ANDROID):
1081806889940-6383ubgii7119ckvl3678quglqocsh4j.apps.googleusercontent.com

GOOGLE OAUTH CLIENT ID (iOS):
1081806889940-m916phe4pkfj5g5auvikacv5nn2i4r2l.apps.googleusercontent.com

INSTAGRAM OAUTH CLIENT ID (OPTIONAL):
your_instagram_app_id

INSTAGRAM OAUTH CLIENT SECRET (OPTIONAL):
your_instagram_app_secret

FACEBOOK OAUTH CLIENT ID (OPTIONAL):
your_facebook_app_id

FACEBOOK OAUTH CLIENT SECRET (OPTIONAL):
your_facebook_app_secret

=== END API KEYS ===
```

**Note:** If you're using the same Google API key for Places + Maps SDK (easier), just paste it three times (once for each field).

### **7.2: Security Notes**
- ✅ **Safe to share in chat:** These are meant to be configured
- ✅ **I will NOT commit them to git:** All keys go in `.env` files or secure config files
- ✅ **Files are gitignored:** `.env` files are already in `.gitignore`
- ⚠️ **After configuration:** You can revoke/regenerate keys if needed

---

## 🔧 **STEP 8: WHAT I'LL DO**

Once you provide the keys, I will:

### **8.1: Create Secure Configuration Files**
1. **Create `.env` file** (gitignored) with all keys:
   - Google Places API Key
   - OpenWeatherMap API Key
   - OAuth credentials
2. **Create `ios/Flutter/Secrets.xcconfig`** (gitignored) for iOS Google Maps SDK key
3. **Update `android/local.properties`** (gitignored) for Android Google Maps SDK key
4. **Verify** all files are in `.gitignore`

### **8.2: Configure Code**
1. **Verify** `GooglePlacesConfig` reads from environment
2. **Verify** `WeatherConfig` reads from environment
3. **Verify** `OAuthConfig` reads from environment
4. **Update** `injection_container.dart` to use real keys (not `demo_key`)
5. **Set** `USE_REAL_OAUTH=true` flag
6. **Configure** Google Maps SDK keys in Android/iOS config files

### **8.3: Test Configuration**
1. **Run** configuration check
2. **Verify** keys are loaded correctly
3. **Test** that services can access keys
4. **Confirm** no keys are hardcoded in source files

---

## ✅ **STEP 9: VERIFICATION**

After I configure the keys, you can verify:

### **9.1: Check Logs**
Run the app and look for:
- ✅ `GooglePlacesConfig.isValid: true`
- ✅ `OAuthConfig.isGoogleConfigured: true`
- ✅ No warnings about missing API keys

### **9.2: Test Features**
1. **Google Places:**
   - Complete onboarding
   - Check logs: `"Found X places for category: ..."`
   - Should see real places, not empty lists

2. **Google Maps:**
   - Open the map view in the app
   - Should display Google Maps (not blank/error)
   - Maps should load tiles correctly

3. **Weather API:**
   - Check logs: `"Collected current weather: ..."`
   - Weather data should be collected for continuous learning

4. **Google OAuth:**
   - Try connecting Google account in onboarding
   - Should open real Google sign-in flow (not placeholder)
   - Check logs: `"Google OAuth flow started"`

### **9.3: Verify Security**
1. **Check `.gitignore`** - `.env` files should be listed
2. **Check git status** - No `.env` files should appear
3. **Verify** no keys in source code files

---

## 📋 **CHECKLIST**

Before providing keys to me:

- [ ] Google Places API key obtained
- [ ] Google Maps SDK key (Android) obtained (can be same as Places API)
- [ ] Google Maps SDK key (iOS) obtained (can be same as Places API)
- [ ] OpenWeatherMap API key obtained
- [ ] Google OAuth Client ID (Android) obtained
- [ ] Google OAuth Client ID (iOS) obtained
- [ ] (Optional) Instagram OAuth credentials obtained
- [ ] (Optional) Facebook OAuth credentials obtained
- [ ] All keys copied and ready to paste

---

## 🆘 **TROUBLESHOOTING**

### **Can't find SHA-1 fingerprint?**
```bash
# For Android debug keystore:
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Look for line starting with "SHA1:"
# Copy the value (remove colons and spaces)
```

### **OAuth consent screen stuck?**
- Make sure you complete all steps (scopes, test users, summary)
- You can add test users later if needed

### **Instagram/Facebook redirect URI?**
- Use: `avrai://oauth/<platform>/callback`
- This matches the redirect scheme in `OAuthConfig`

---

## 📚 **RESOURCES**

- **Google Cloud Console:** https://console.cloud.google.com/
- **Facebook Developers:** https://developers.facebook.com/
- **Google Places API Docs:** https://developers.google.com/maps/documentation/places
- **OAuth Setup Guide:** `docs/plans/onboarding/ONBOARDING_PROCESS_PLAN.md` (Phase 10)

---

## 🎯 **NEXT STEPS**

1. **Follow Steps 1-6** to get all API keys
2. **Format your response** per Step 7
3. **Paste keys in chat** - I'll configure them securely
4. **Verify** per Step 9 that everything works

---

## 📝 **QUICK REFERENCE: KEY DIFFERENCES**

| Key Type | Purpose | Separate for iOS/Android? |
|----------|---------|---------------------------|
| **Google Places API** | Search/find places | ❌ No (one key) |
| **Google Maps SDK** | Display map | ✅ Yes (separate keys, or use same) |
| **OpenWeatherMap** | Weather data | ❌ No (one key) |
| **Google OAuth** | Sign-in | ✅ Yes (separate Client IDs) |
| **Instagram OAuth** | Social connection | ❌ No (one Client ID + Secret) |
| **Facebook OAuth** | Social connection | ❌ No (one Client ID + Secret) |

**Tip:** For simplicity, you can use the **same Google API key** for Places API and Maps SDK (both Android and iOS). Just enable all three APIs (Places API New, Maps SDK Android, Maps SDK iOS) for that one key.

**Ready?** Start with Step 1 and work through each step. When you have all the keys, paste them in the format from Step 5, and I'll configure everything correctly!

---

**Last Updated:** January 6, 2026  
**Status:** Ready for use
