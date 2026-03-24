# LeafLens — Build Plan

## Overview

7-week plan to go from repository setup to a polished, demo-ready Flutter + FastAPI app. Each week has a clear deliverable and definition of done.

---

## Week-by-Week Roadmap

### Week 1 — Foundations & Project Scaffold ✅ DONE
**Goal:** Both Flutter and FastAPI projects run locally with correct folder structure.

**Flutter tasks**
- [x] `flutter create leaflens` — created at `leaflens/`
- [x] Add dependencies (riverpod 2.5.1, go_router 13.2.0, supabase_flutter, image_picker, camera, dio, google_sign_in, etc.) — `flutter pub get` clean
- [x] Set up GoRouter with all 10 named routes in `lib/core/router/app_router.dart`
- [x] Create full `lib/` folder structure matching PLAN.md spec
- [x] Design tokens: `AppColors`, `AppTextStyles`, `AppTheme` — `flutter analyze` 0 issues
- [ ] Add Google Sign-In `google-services.json` / `GoogleService-Info.plist` — **needs real Supabase/Google project keys**

**FastAPI tasks**
- [x] `backend/main.py` with health `GET /`, CORS, routers
- [x] `backend/requirements.txt` — fastapi, uvicorn, httpx, supabase
- [x] `backend/.env.example`
- [x] `backend/routers/identify.py` — full Pl@ntNet → Wikipedia → GBIF → Supabase pipeline
- [x] `backend/routers/plants.py` — stub endpoints
- [ ] Deploy to Render — **needs user to push and set env vars**

**Supabase tasks**
- [ ] Create project, enable Google OAuth — **manual step**
- [ ] Create tables: `plants`, `scans`, `saved_plants`
- [ ] Enable Row Level Security
- [ ] Create storage bucket `plant-images`

**DoD:** Flutter project structure complete, 0 analysis errors. Backend scaffold ready. Awaiting Supabase/Render setup by user.

---

### Week 2 — Auth + Splash + Onboarding ✅ DONE
**Goal:** Complete screens 01–02; user can sign in and onboarding is shown once.

**Screens to build**
- [x] `SplashScreen` — animated rotating ring (12s) + counter-spinning inner circle, Get Started button with loading state
- [x] `OnboardingScreen` — 3-slide PageView, animated progress dots, Skip + Next/Start Exploring buttons
- [x] Auth flow: `AuthRepo` + `AuthNotifier` StateNotifierProvider

**State**
- [x] `SharedPreferences` flag `has_seen_onboarding` — GoRouter redirect logic
- [x] `AuthNotifier` (Riverpod) — `user`, `signInWithGoogle()`, `signOut()`, `isLoading`

**DoD:** Screens built. Needs Supabase credentials to verify Google auth flow end-to-end.

---

### Week 3 — Home Screen (Both States) + Bottom Nav
**Goal:** Complete screens 03 & 04; bottom nav works across all tabs.

**Screens to build**
- [ ] `HomeScreen` — checks Supabase `scans` count for current user on mount
  - Empty state: orbit illustration, scan CTA, tips strip, Plant of Day card
  - Filled state: stats row (total scanned / unique species / saved), recent 3 scans list, scan CTA button, Plant of Day card
- [ ] `BottomNavBar` widget — 4 tabs: Home / Scan / Encyclopedia / Profile

**Data**
- [ ] `ScanStatsProvider` — fetches count aggregates from Supabase
- [ ] `PlantOfDayProvider` — fetches one plant from `plants` table where `potd_date = today()`; falls back to random if none

**DoD:** Home shows correct state based on actual Supabase data; nav tabs route correctly.

---

### Week 4 — Scan → Analyzing → Result (Core Flow)
**Goal:** Complete screens 05, 06, 07; full identification pipeline works end to end.

**Scan Screen (Screen 05)**
- [ ] Camera preview using `camera` package
- [ ] 4 scan mode chips: Leaf / Flower / Bark / Full Plant (maps to Pl@ntNet organ param)
- [ ] Gallery button using `image_picker`
- [ ] Flash toggle, flip camera
- [ ] Multi-angle mode: collect up to 3 images before submitting
- [ ] On capture → navigate to Analyzing with image data

**FastAPI — `/identify` endpoint**
- [ ] `POST /identify` — accepts multipart image(s) + organ type
- [ ] Calls Pl@ntNet API, extracts top result (scientific name, confidence, common name, family)
- [ ] Calls Wikipedia REST for description
- [ ] Calls Trefle/GBIF for care data (soil, sunlight, water, pH, temp)
- [ ] Builds full plant JSON response
- [ ] Saves to `plants` table (upsert on `scientific_name`)
- [ ] Saves scan record to `scans` table
- [ ] Uploads image to Supabase Storage, stores URL in scan record
- [ ] Returns assembled plant profile JSON

**Analyzing Screen (Screen 06)**
- [ ] POST request to FastAPI `/identify`
- [ ] 4-step progress UI driven by response status / polling
- [ ] On success → navigate to Result, passing plant data

**Result Screen (Screen 07)**
- [ ] Hero section: plant emoji, confidence badge, back + share buttons
- [ ] Plant name (common + scientific), family
- [ ] 4 TabBar tabs: Overview / Care / Uses / Facts
- [ ] Overview: region pills, 4 data cards (habitat, height, bloom, climate)
- [ ] Care: soil, sunlight, water, pH, temp chips
- [ ] Uses: medicinal, culinary, cosmetic, industrial rows; red toxicity badge if toxic
- [ ] Facts: IUCN status, cultural significance, trivia
- [ ] "Save Plant" button → inserts into `saved_plants`
- [ ] Share button → `Share.share()` with plant name + Wikipedia link

**DoD:** Full scan → result flow works on device with real plant photos.

---

### Week 5 — History + Encyclopedia + Plant Detail
**Goal:** Complete screens 08, 09, 10; browse and search all identified plants.

**History Screen (Screen 08)**
- [ ] Fetch all `scans` for current user, ordered by `scanned_at DESC`
- [ ] Group by date: Today / Yesterday / This Week / Older
- [ ] Search bar — real-time filter on `common_name`
- [ ] Filter chips: All / Medicinal / Edible / Toxic / Saved
- [ ] Each item: plant emoji, name, scan time, confidence %, category tag
- [ ] Tap → navigate to Plant Detail

**Encyclopedia Screen (Screen 09)**
- [ ] Fetch all distinct plants from `plants` table (community-wide)
- [ ] Featured Plant of Day card (large green card at top)
- [ ] Filter chips: All / Medicinal / Edible / Indoor / Rare
- [ ] 2-column grid of plant cards
- [ ] Search bar — filters grid in real time
- [ ] Tap card → navigate to Plant Detail

**Plant Detail Screen (Screen 10)**
- [ ] Large hero (200px) with gradient, plant emoji, back + favorite buttons
- [ ] 4 tabs: Overview / Care / Uses / Facts (same content as Result but with fuller Wikipedia text)
- [ ] Distribution section: countries list, climate zone, IUCN status badge
- [ ] Favorite toggle → insert/delete from `saved_plants`

**DoD:** All 3 screens load real data from Supabase; search and filters work; Plant Detail renders complete profile.

---

### Week 6 — Profile Screen + Polish
**Goal:** Complete screen 11; fix all UI rough edges; handle error states.

**Profile Screen (Screen 11)**
- [ ] Hero gradient with avatar (first letter of display name)
- [ ] Stats row: total scanned / unique species / saved plants
- [ ] "My Saved Plants" → filtered History view
- [ ] "Set My Region" → bottom sheet with country/state picker; saves to user metadata in Supabase
- [ ] "Export History" → generate CSV of all scans, share via `Share.share()`
- [ ] "Sign Out" → calls `supabase.auth.signOut()`, navigate to Splash
- [ ] "About LeafLens" → simple info bottom sheet

**Polish tasks**
- [ ] Add loading skeletons (shimmer) on all list/grid screens
- [ ] Add error states with retry buttons
- [ ] Handle no-internet gracefully (show cached data)
- [ ] Smooth screen transition animations (slide + fade)
- [ ] Haptic feedback on Scan capture button
- [ ] Empty state illustrations for History and Encyclopedia when 0 results

**DoD:** All 11 screens complete; no obvious crashes; error and loading states handled.

---

### Week 7 — Testing, Performance, Release Prep
**Goal:** App ready to demo or submit to Play Store internal testing.

- [ ] Unit tests for `IdentifyService`, `PlantRepository`, `AuthNotifier`
- [ ] Widget tests for Result screen tab switching
- [ ] Integration test: full scan flow (mock API)
- [ ] Performance: image compression before upload (max 1 MB), lazy loading in Encyclopedia grid
- [ ] Accessibility: semantic labels on all icons and buttons
- [ ] App icon (green leaf on dark background)
- [ ] Splash screen branding via `flutter_native_splash`
- [ ] `flutter build apk --release` — confirm no build errors
- [ ] Update `README.md` with setup instructions and API key guide
- [ ] Record a 60-second demo video

**DoD:** Signed APK builds cleanly; demo video recorded; README complete.

---

## Folder Structure

```
leaflens/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── theme/           # colors.dart, text_styles.dart, app_theme.dart
│   │   ├── router/          # app_router.dart (GoRouter config)
│   │   ├── constants/       # api_constants.dart, storage_keys.dart
│   │   └── utils/           # image_utils.dart, date_utils.dart
│   ├── data/
│   │   ├── models/          # plant.dart, scan.dart, user_profile.dart
│   │   ├── repositories/    # plant_repo.dart, scan_repo.dart, auth_repo.dart
│   │   └── services/        # identify_service.dart, supabase_service.dart
│   ├── providers/           # auth_provider.dart, scan_stats_provider.dart, plant_of_day_provider.dart
│   └── ui/
│       ├── screens/
│       │   ├── splash/
│       │   ├── onboarding/
│       │   ├── home/
│       │   ├── scan/
│       │   ├── analyzing/
│       │   ├── result/
│       │   ├── history/
│       │   ├── encyclopedia/
│       │   ├── plant_detail/
│       │   └── profile/
│       └── widgets/         # bottom_nav.dart, plant_card.dart, confidence_badge.dart, potd_card.dart
├── backend/
│   ├── main.py
│   ├── routers/             # identify.py, plants.py
│   ├── services/            # plantnet.py, wikipedia.py, trefle.py
│   ├── models/              # schemas.py
│   ├── requirements.txt
│   └── .env.example
└── docs/
    ├── CONTEXT.md
    ├── PLAN.md
    ├── CLAUDE.md
    └── prototype/           # leaflens_complete.html
```

---

## API Endpoints (FastAPI)

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | Health check |
| `POST` | `/identify` | Main identification pipeline |
| `GET` | `/plants/{id}` | Fetch plant by ID |
| `GET` | `/plants/search?q=` | Search plants by name |
| `GET` | `/plants/potd` | Plant of the Day |
| `GET` | `/scans/{user_id}` | User's scan history |

---

## Environment Variables

```env
# Backend (.env)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_KEY=eyJ...
PLANTNET_API_KEY=your_plantnet_key

# Flutter (lib/core/constants/api_constants.dart)
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const backendBaseUrl = 'https://leaflens-api.onrender.com';
```

---

## Risk Register

| Risk | Mitigation |
|---|---|
| Pl@ntNet 500 req/day limit hit | Cache all identifications in `plants` table; serve from cache on repeated scans |
| Pl@ntNet low confidence (<40%) | Show "Low Confidence" warning badge; prompt multi-angle scan |
| Wikipedia page not found | Fallback to GBIF species description |
| Render cold start (30s delay) | Show "Warming up..." toast on first scan; pre-warm with cron ping |
| Supabase free tier row limits | Encyclopedia deduplicates on `scientific_name`; prune old anonymous scans |
| Image too large for free API | Compress to ≤800px longest edge, ≤500KB before upload |
