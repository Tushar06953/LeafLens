# LeafLens — Real API Setup Guide

Follow these steps in order. Each step takes 5–15 minutes.

---

## STEP 1 — Pl@ntNet API Key (Plant Identification)

1. Go to **https://my.plantnet.org**
2. Click **Sign up** → create a free account
3. After login, go to **My Account → API Keys**
4. Click **Create new API key** → copy it (looks like `2b10abcd...`)
5. Free tier: **500 requests/day** — enough for development

**Save it** as `PLANTNET_API_KEY=2b10xxxx...`

---

## STEP 2 — Supabase Project (Database + Auth + Storage)

### 2a. Create project
1. Go to **https://supabase.com** → Sign in with GitHub
2. Click **New Project**
   - Name: `leaflens`
   - Database password: generate a strong one (save it)
   - Region: **Southeast Asia (Singapore)** — closest to India
3. Wait ~2 minutes for provisioning

### 2b. Run the database schema
1. In the Supabase dashboard, click **SQL Editor** (left sidebar)
2. Click **New query**
3. Open `docs/supabase_schema.sql` from this repo
4. Paste the entire file and click **Run**
5. You should see: `Success. No rows returned`

### 2c. Get your API keys
Go to **Settings → API** (left sidebar):

| Variable | Where to find it |
|---|---|
| `SUPABASE_URL` | "Project URL" — looks like `https://abcxyz.supabase.co` |
| `SUPABASE_ANON_KEY` | "anon public" key — long JWT string |
| `SUPABASE_SERVICE_KEY` | "service_role" key — longer JWT (keep secret!) |

### 2d. Enable Google Sign-In
1. Go to **Authentication → Providers**
2. Click **Google** → toggle **Enable**
3. You need a Google OAuth Client ID and Secret:
   - Go to **https://console.cloud.google.com**
   - Create a new project (or use existing)
   - APIs & Services → Credentials → Create OAuth 2.0 Client ID
   - Application type: **Web application**
   - Add to "Authorised redirect URIs":
     ```
     https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback
     ```
   - Copy the **Client ID** and **Client Secret** back into Supabase
4. Also create an **Android** OAuth client:
   - Application type: **Android**
   - Package name: `com.leaflens.leaflens`
   - SHA-1: run `cd android && ./gradlew signingReport` and copy the debug SHA-1

---

## STEP 3 — Deploy Backend to Render (Free)

### 3a. Push backend to GitHub
```bash
# From the leaflens project root
git init
git add backend/
git commit -m "Add LeafLens FastAPI backend"
# Create a repo on github.com, then:
git remote add origin https://github.com/YOUR_USERNAME/leaflens-backend.git
git push -u origin main
```

### 3b. Deploy on Render
1. Go to **https://render.com** → Sign in with GitHub
2. Click **New → Web Service**
3. Connect your GitHub repo
4. Settings:
   - **Name:** `leaflens-api`
   - **Root Directory:** `backend`
   - **Runtime:** Python 3
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `uvicorn main:app --host 0.0.0.0 --port $PORT`
5. Click **Advanced → Add Environment Variables**:

| Key | Value |
|---|---|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_SERVICE_KEY` | Your service_role key (NOT the anon key) |
| `PLANTNET_API_KEY` | Your Pl@ntNet key from Step 1 |

6. Click **Create Web Service**
7. Wait 3–5 minutes for the first deploy
8. Test: open `https://leaflens-api.onrender.com/` — should return `{"status":"ok"}`

> **Free tier note:** Render free tier sleeps after 15 min of inactivity.
> First scan after sleep takes ~30 sec (cold start). This is normal.

---

## STEP 4 — Configure the Flutter App

### 4a. Create a `.env` file (never commit this)
```bash
# leaflens/.env  (add to .gitignore)
SUPABASE_URL=https://abcxyz.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
BACKEND_URL=https://leaflens-api.onrender.com
```

### 4b. Add `.env` to `.gitignore`
```bash
echo ".env" >> .gitignore
```

### 4c. Run the app with dart-define
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://abcxyz.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGci... \
  --dart-define=BACKEND_URL=https://leaflens-api.onrender.com
```

### 4d. VS Code shortcut — create `.vscode/launch.json`
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "LeafLens (dev)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=SUPABASE_URL=https://abcxyz.supabase.co",
        "--dart-define=SUPABASE_ANON_KEY=eyJhbGci...",
        "--dart-define=BACKEND_URL=https://leaflens-api.onrender.com"
      ]
    }
  ]
}
```
Then press **F5** to run.

### 4e. Android — add internet permission
In `android/app/src/main/AndroidManifest.xml`, inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

---

## STEP 5 — Google Sign-In Android Setup

In `android/app/src/main/res/values/strings.xml` (create if missing):
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">LeafLens</string>
    <string name="default_web_client_id">YOUR_WEB_CLIENT_ID.apps.googleusercontent.com</string>
</resources>
```

In `android/app/build.gradle`, under `android { defaultConfig {`:
```groovy
manifestPlaceholders += [
    'appAuthRedirectScheme': 'com.leaflens.leaflens'
]
```

---

## STEP 6 — Verify Everything Works

### 6a. Test the backend identify endpoint
```bash
curl -X POST https://leaflens-api.onrender.com/identify \
  -F "files=@/path/to/leaf_photo.jpg" \
  -F "organ=leaf"
```
Expected: JSON with `scientific_name`, `common_name`, `confidence`, etc.

### 6b. Test Supabase connection
Run the app, sign in with Google. Then in Supabase dashboard:
- **Authentication → Users** — you should see your Google account appear
- Scan a plant — check **Table Editor → scans** for the new row
- Save a plant — check **Table Editor → saved_plants**

### 6c. Full flow checklist
- [ ] Splash screen loads (no white screen / crash)
- [ ] Google Sign-In completes → lands on Home
- [ ] Scan screen opens camera
- [ ] Take a photo → Analyzing screen runs → Result screen shows real plant name
- [ ] Confidence > 20% for a clear leaf photo
- [ ] "Save Plant" button → row appears in Supabase `saved_plants`
- [ ] History screen shows real past scans
- [ ] Encyclopedia loads plants from `plants` table
- [ ] Profile stats show real numbers

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `SUPABASE_URL is empty` | You forgot `--dart-define` flags when running |
| Google Sign-In fails | SHA-1 mismatch — re-run `signingReport` and update Google Console |
| `PlantNet error 401` | API key wrong or not passed as env var on Render |
| Render returns 502 | Cold start — wait 30 sec and try again |
| `confidence < 0.20` error | Photo too blurry — use good lighting, try multi-angle mode |
| Supabase RLS error | Make sure you ran the full schema SQL including the policy blocks |
| Camera black screen | Missing `CAMERA` permission in AndroidManifest |

---

## Cost Summary

| Service | Free Tier Limit | What happens at limit |
|---|---|---|
| Pl@ntNet | 500 req/day | Returns 429 — add retry logic |
| Supabase | 500 MB DB, 1 GB storage, 50k MAU | Upgrade to Pro ($25/mo) |
| Render | 750 hrs/month, sleeps after 15 min | Upgrade to Starter ($7/mo) to remove sleep |
| Wikipedia API | Unlimited | No limit |
| GBIF API | Unlimited | No limit |
