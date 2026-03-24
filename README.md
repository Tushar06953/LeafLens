# LeafLens

**AI-powered plant identification app** — point your camera at any plant to get an instant botanical profile with care guides, medicinal uses, conservation status, and more.

Built with Flutter (mobile) and FastAPI (backend), running at $0/month on free-tier infrastructure.

---

## Features

- **Instant Plant ID** — upload or photograph a leaf, flower, or full plant; powered by the Pl@ntNet API
- **Multi-angle scanning** — capture up to 3 photos for higher-confidence identifications
- **Detailed botanical profiles** — Overview, Care, Uses, and Facts tabs per plant
- **Care guide** — soil type, sunlight, watering, pH range, and temperature requirements
- **Uses** — medicinal, culinary, cosmetic, and industrial applications; toxicity warning badge
- **Conservation** — IUCN status, distribution countries, cultural significance
- **Plant of the Day** — daily featured plant on Home and Encyclopedia screens
- **Scan history** — full timeline with date grouping, search, and category filters
- **Encyclopedia** — community-wide plant database that grows with every scan
- **Favorites** — save plants and manage your collection from the Profile screen
- **CSV export** — download your full scan history from the Profile screen
- **Google Sign-In** — one-tap auth via Supabase OAuth

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter (Dart) |
| State | Riverpod + code generation |
| Navigation | GoRouter |
| Backend | FastAPI (Python) |
| Auth & Database | Supabase (PostgreSQL + Auth + Storage) |
| Plant ID | Pl@ntNet REST API |
| Plant Data | Wikipedia REST API, GBIF |
| Hosting | Render.com (free tier) |

### Flutter packages

```
flutter_riverpod, riverpod_annotation, go_router, supabase_flutter,
google_sign_in, camera, image_picker, dio, cached_network_image,
flutter_animate, shimmer, share_plus, flutter_native_splash,
shared_preferences, google_fonts, flutter_launcher_icons
```

### Python packages

```
fastapi, uvicorn, supabase, httpx, pydantic, python-multipart, gunicorn
```

---

## Repository Structure

```
leaflens/
├── backend/                  # FastAPI backend (Render root directory)
│   ├── main.py               # App entry, CORS, router registration
│   ├── requirements.txt
│   ├── .env.example
│   └── routers/
│       ├── identify.py       # POST /identify — full pipeline
│       └── plants.py         # GET /plants/* — POTD, search, all, by ID
└── app/                      # Flutter app
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── core/
        │   ├── theme/        # AppColors, AppTextStyles, AppTheme
        │   ├── router/       # GoRouter config (10 named routes)
        │   └── constants/    # API URLs, SharedPreferences keys
        ├── data/
        │   ├── models/       # PlantModel, ScanModel (immutable, copyWith)
        │   ├── repositories/ # Auth, Plant, Scan, SavedPlants repos
        │   └── services/     # IdentifyService (backend HTTP calls)
        ├── providers/        # Riverpod providers (auth, stats, POTD, history)
        └── ui/
            ├── screens/      # 11 screens (see table below)
            └── widgets/      # BottomNav, PlantCard, HistoryItem, etc.
```

### Screen map

| Screen | File |
|---|---|
| Splash | `lib/ui/screens/splash/splash_screen.dart` |
| Onboarding | `lib/ui/screens/onboarding/onboarding_screen.dart` |
| Home | `lib/ui/screens/home/home_screen.dart` |
| Scan | `lib/ui/screens/scan/scan_screen.dart` |
| Analyzing | `lib/ui/screens/analyzing/analyzing_screen.dart` |
| Result | `lib/ui/screens/result/result_screen.dart` |
| History | `lib/ui/screens/history/history_screen.dart` |
| Encyclopedia | `lib/ui/screens/encyclopedia/encyclopedia_screen.dart` |
| Plant Detail | `lib/ui/screens/plant_detail/plant_detail_screen.dart` |
| Profile | `lib/ui/screens/profile/profile_screen.dart` |
| Bottom Nav | `lib/ui/widgets/bottom_nav.dart` |

---

## Getting Started

### Prerequisites

- Flutter SDK >= 3.10.4
- Python 3.11+
- A [Supabase](https://supabase.com) project
- A [Pl@ntNet API key](https://my.plantnet.org) (500 req/day free)
- A [Render](https://render.com) account (free tier)

### 1. Clone the repo

```bash
git clone https://github.com/your-username/leaflens.git
cd leaflens
```

### 2. Set up the backend

```bash
cd backend
cp .env.example .env
# Fill in SUPABASE_URL, SUPABASE_SERVICE_KEY, PLANTNET_API_KEY
pip install -r requirements.txt
uvicorn main:app --reload
```

Test with:

```bash
curl http://localhost:8000/
# {"status":"ok"}
```

### 3. Set up the Flutter app

```bash
cd app
flutter pub get
```

Pass configuration via `--dart-define` when running:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=BACKEND_URL=http://10.0.2.2:8000
```

> Use `10.0.2.2` instead of `localhost` when targeting the Android emulator.

### 4. Supabase schema

Run the following SQL in the Supabase SQL editor:

```sql
-- Plants (community-wide, grows with each scan)
create table plants (
  id uuid primary key default gen_random_uuid(),
  scientific_name text unique not null,
  common_name text,
  family text,
  description text,
  care_data jsonb,
  uses jsonb,
  iucn_status text,
  region_pills text[],
  emoji text,
  potd_date date,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Scans (per-user history)
create table scans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  plant_id uuid references plants,
  image_url text,
  confidence float,
  scan_mode text,
  scanned_at timestamptz default now()
);

-- Saved plants (user favourites)
create table saved_plants (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  plant_id uuid references plants not null,
  created_at timestamptz default now(),
  unique(user_id, plant_id)
);
```

Enable Row Level Security and add policies so users can only read/write their own rows in `scans` and `saved_plants`.

Create a storage bucket named `plant-images` (public read).

### 5. Google Sign-In

1. Create an OAuth 2.0 Client ID in [Google Cloud Console](https://console.cloud.google.com)
2. Add your SHA-1 fingerprint (Android) and bundle ID (iOS)
3. Download `google-services.json` → `app/android/app/`
4. Download `GoogleService-Info.plist` → `app/ios/Runner/`
5. Configure the OAuth provider in your Supabase project dashboard

---

## Deploying the Backend to Render

1. Push the repo to GitHub
2. Create a new **Web Service** on Render pointing to this repo
3. Set **Root Directory** to `backend`
4. **Build command:** `pip install -r requirements.txt`
5. **Start command:** `uvicorn main:app --host 0.0.0.0 --port $PORT`
6. Add environment variables: `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `PLANTNET_API_KEY`

> **Cold-start note:** Render free tier spins down after 15 minutes of inactivity. The app pre-warms the backend when the Analyzing screen mounts and uses a 60-second connection timeout to handle the first-request delay gracefully.

---

## Identification Pipeline

```
User taps shutter
       │
       ▼
POST /identify  (multipart: images + organ)
       │
       ├─► Pl@ntNet API     ──► scientific name, family, confidence score
       │
       ├─► Wikipedia API    ──► description, thumbnail URL
       │
       ├─► GBIF API         ──► care data, distribution (best-effort fallback)
       │
       ├─► Supabase Storage ──► upload original image → image_url
       │
       ├─► plants table     ──► upsert on scientific_name
       │
       └─► scans table      ──► insert scan record for user
               │
               ▼
       Assembled PlantModel JSON returned to Flutter
               │
               ▼
       Result Screen (4 tabs: Overview / Care / Uses / Facts)
```

**Low confidence:** if Pl@ntNet score < 0.20, the API returns `{"error": "low_confidence"}` and the app prompts the user to try a multi-angle scan.

---

```

---
