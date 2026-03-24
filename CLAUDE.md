# LeafLens — CLAUDE.md
## Master Build Guide for AI-Assisted Development

> Read this file completely before writing any code. It is the single source of truth for how this project is structured, what decisions have been made, and how to add each feature without breaking anything.

---

## 1. Project Summary

**App:** LeafLens — AI-powered plant identification Flutter app  
**Backend:** FastAPI on Render (free tier)  
**Database & Auth:** Supabase (PostgreSQL + Auth + Storage)  
**Plant ID:** Pl@ntNet REST API  
**Plant Data:** Wikipedia REST API + Trefle/GBIF  
**State:** Riverpod  
**Navigation:** GoRouter  
**Cost:** $0/month  

Refer to `CONTEXT.md` for full tech stack, screen inventory, data schema, and design tokens.  
Refer to `PLAN.md` for the 7-week roadmap and folder structure.

---

## 2. Monorepo Directory Structure

The LeafLens GitHub repo is organized as a **monorepo** with two top-level folders:

```
LeafLens/                  ← repo root
├── backend/               ← FastAPI backend (Render Root Directory = "backend")
│   ├── main.py
│   ├── requirements.txt
│   ├── render.yaml        ← optional Render config
│   └── routers/
│       ├── identify.py
│       └── plants.py
└── app/                   ← Flutter app (all Flutter code lives here)
    ├── pubspec.yaml
    ├── lib/
    ├── android/
    ├── ios/
    └── ...
```

### Render Deployment Config
- **Root Directory on Render:** `backend`
- **Build Command:** `pip install -r requirements.txt`
- **Start Command:** `uvicorn main:app --host 0.0.0.0 --port $PORT`
- **Environment Variables:** `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `PLANTNET_API_KEY`

> ⚠️ If Render shows "Root directory does not exist", verify the folder is named exactly `backend` (lowercase) in the GitHub repo.

### Flutter App Root
All Flutter commands (`flutter run`, `flutter build`, etc.) must be run from inside the `app/` folder, not the repo root.

```bash
cd app
flutter pub get
flutter run
```

---

## 3. Twenty-Step Build Sequence

Follow this sequence exactly. Never skip a step. Each step has a clear output to verify before moving on.

### STEP 1 — Create Flutter Project
```bash
# Run from repo root
flutter create app --org com.leaflens --platforms android,ios
cd app
> The Flutter app lives in the `app/` folder. All subsequent `flutter` commands run from inside `app/`.
```

**Verify:** `flutter run` launches default counter app.
```
**Verify:** `flutter run` launches default counter app.

---

### STEP 2 — Add All Dependencies
Add to `pubspec.yaml` under `dependencies`:
```yaml
flutter_riverpod: ^2.5.1
riverpod_annotation: ^2.3.5
go_router: ^13.2.0
supabase_flutter: ^2.3.4
google_sign_in: ^6.2.1
image_picker: ^1.0.7
camera: ^0.10.5+9
cached_network_image: ^3.3.1
dio: ^5.4.3
shared_preferences: ^2.2.3
flutter_animate: ^4.5.0
shimmer: ^3.0.0
share_plus: ^9.0.0
flutter_native_splash: ^2.4.0
```
Run `flutter pub get`.  
**Verify:** No version conflicts in `pubspec.lock`.

---

### STEP 3 — Set Up Folder Structure
Create all directories as specified in `PLAN.md` under "Folder Structure". Create empty placeholder `.dart` files to establish the module boundaries.  
**Verify:** `lib/` tree matches the plan exactly.

---

### STEP 4 — Design Tokens
Create `lib/core/theme/colors.dart`:
```dart
import 'package:flutter/material.dart';

class AppColors {
  // Dark backgrounds
  static const g1 = Color(0xFF0B1F12);
  static const g2 = Color(0xFF163024);
  static const g3 = Color(0xFF1F4233);
  // Accent greens
  static const ga = Color(0xFF2A7A50);
  static const gb = Color(0xFF3DA876);
  static const gc = Color(0xFF6FCF97);
  // Light surfaces
  static const cream = Color(0xFFF5F0E8);
  static const warm  = Color(0xFFFDF8F0);
  // Accent gold (Plant of Day)
  static const gold  = Color(0xFFC8951A);
  static const gold2 = Color(0xFFE8B84B);
  // Text
  static const text1 = Color(0xF2FFFFFF); // 95% white
  static const text2 = Color(0x99FFFFFF); // 60% white
  static const text3 = Color(0x4DFFFFFF); // 30% white
  // Light-screen text
  static const darkText = Color(0xFF1A1A1A);
  static const mutedText = Color(0xFFAAAAAA);
}
```
Create `lib/core/theme/text_styles.dart` importing Google Fonts (`cormorant_garamond` + `outfit`).  
Add fonts to `pubspec.yaml` assets.  
**Verify:** `AppColors.gb` resolves without error.

---

### STEP 5 — GoRouter Setup
Create `lib/core/router/app_router.dart`. Define these named routes:
```
/splash          → SplashScreen
/onboarding      → OnboardingScreen
/home            → HomeScreen
/scan            → ScanScreen
/analyzing       → AnalyzingScreen
/result          → ResultScreen        (extra: PlantModel)
/history         → HistoryScreen
/encyclopedia    → EncyclopediaScreen
/plant-detail    → PlantDetailScreen   (extra: PlantModel)
/profile         → ProfileScreen
```
Redirect logic: if `has_seen_onboarding` is false → `/onboarding`; else if no session → `/splash`; else → `/home`.  
**Verify:** `context.go('/home')` compiles without error.

---

### STEP 6 — Supabase Init + Auth
In `main.dart`:
```dart
await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
```
Create `lib/data/repositories/auth_repo.dart` with:
- `signInWithGoogle()` — uses `supabase.auth.signInWithIdToken`
- `signOut()` — calls `supabase.auth.signOut()`
- `currentUser` getter

Create `lib/providers/auth_provider.dart` as a `StateNotifierProvider`.  
**Verify:** Google Sign-In flow completes and `supabase.auth.currentUser` is non-null.

---

### STEP 7 — Splash Screen
File: `lib/ui/screens/splash/splash_screen.dart`

Key elements (match prototype exactly):
- Dark radial gradient background (`g1` → `g2`)
- Outer ring: 130×130 dashed green circle, spinning via `AnimationController` (12s, `CurvedAnimation`)
- Inner circle: 96×96 green gradient with 🌿 emoji, counter-spinning
- App name "LeafLens" in Cormorant Garamond 36px cream
- Tagline "Identify · Learn · Save" in Outfit 12px muted
- "Get Started" button → calls `signInWithGoogle()` → on success go `/home` (or `/onboarding` if first time)

**Verify:** Screen renders; animation loops; button navigates.

---

### STEP 8 — Onboarding Screen
File: `lib/ui/screens/onboarding/onboarding_screen.dart`

- `PageController` with 3 slides
- Each slide: large emoji (88px), title (Cormorant 28px), description (Outfit 13px)
  - Slide 1: 🌿 "Identify Any Plant" — "Point your camera at any leaf, flower, or bark..."
  - Slide 2: 📖 "Learn Everything" — "Discover soil requirements, medicinal uses..."
  - Slide 3: 💾 "Build Your Collection" — "Save your favourites, browse your history..."
- Progress dots below emoji area (active dot: 20px wide green, inactive: 6px grey)
- Skip button (top right) → set `has_seen_onboarding = true` → go `/home`
- "Next" button → advance page; on last page becomes "Start Exploring" → same as Skip

**Verify:** Swipe works; Skip works; flag written to SharedPreferences.

---

### STEP 9 — Home Screen (Empty + Filled States)
File: `lib/ui/screens/home/home_screen.dart`

On `initState`: watch `ScanStatsProvider`. If `totalScans == 0` → show Empty widget; else → show Filled widget.

**Empty state widgets:**
- Header: greeting ("Hello 🌿") + notification bell icon
- Center: dashed orbit circle with large plant emoji, title, body text, green "Scan a Plant" button
- Tips strip: 3 tips (light, full plant, clear background)
- Plant of Day card (gold border, `potd_date` plant)

**Filled state widgets:**
- Same header
- Stats row: 3 boxes (Scanned / Species / Saved) with Cormorant numbers
- "Scan Now" full-width green button
- "Recent Scans" section: last 3 `HistoryItem` widgets
- Plant of Day card

Bottom nav bar widget renders across all 4 main tabs.  
**Verify:** Both states render; stats come from real Supabase query.

---

### STEP 10 — Scan Screen
File: `lib/ui/screens/scan/scan_screen.dart`

- Request camera permission on mount; show permission error state if denied
- `CameraPreview` fills screen
- Animated scan line: positioned `AnimatedPositioned` moving top→bottom over 2s loop
- 4 corner guide brackets (custom paint or container trick)
- Bottom bar (dark): gallery icon | shutter button | flip camera icon
- Flash toggle icon top right
- Scan mode chips row: Leaf / Flower / Bark / Full Plant — tapping updates `selectedMode` provider; active chip highlighted green
- Multi-angle mode toggle: when active, shows counter badge "1/3", "2/3", "3/3"; on 3rd capture → auto-navigate to Analyzing

On shutter tap (single mode) → capture → navigate to `/analyzing` passing `{images: [...], mode: selectedMode}`.  
**Verify:** Camera preview works on real device; mode chip updates state.

---

### STEP 11 — FastAPI Backend Scaffold
File: `backend/main.py`

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import identify, plants

app = FastAPI(title="LeafLens API")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])
app.include_router(identify.router)
app.include_router(plants.router)

@app.get("/")
def health(): return {"status": "ok"}
```
Deploy to Render. Set env vars `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `PLANTNET_API_KEY`.  
**Verify:** `GET https://your-app.onrender.com/` returns `{"status":"ok"}`.

---

### STEP 12 — Identify Endpoint (FastAPI)
File: `backend/routers/identify.py`

`POST /identify` — multipart form: `files: List[UploadFile]`, `organ: str`

Pipeline:
1. Upload image(s) to Pl@ntNet `/v2/identify/all` with organ param
2. Extract top result: `scientific_name`, `common_name`, `family`, `score` (confidence)
3. `GET https://en.wikipedia.org/api/rest_v1/page/summary/{scientific_name}` → description, thumbnail
4. Call Trefle/GBIF for care data (soil, sunlight, water, pH, temp) — wrap in try/except with fallback defaults
5. Upload original image to Supabase Storage bucket `plant-images`
6. `upsert` into `plants` table on `scientific_name`
7. `insert` into `scans` table with `user_id` (from Bearer token header), `plant_id`, `image_url`, `confidence`, `scan_mode`
8. Return assembled JSON (see PlantModel schema in CONTEXT.md)

**Error handling:**
- Pl@ntNet confidence < 0.20 → return `{"error": "low_confidence", "message": "Could not identify — try multi-angle"}`
- Wikipedia 404 → use GBIF species description as fallback
- Any exception → return `{"error": "identify_failed", "detail": str(e)}`

**Verify:** `POST /identify` with a fern photo returns a JSON plant profile with >0.5 confidence.

---

### STEP 13 — Analyzing Screen
File: `lib/ui/screens/analyzing/analyzing_screen.dart`

Receives `{images, mode}` via GoRouter `extra`.

On mount: start API call via `IdentifyService.identify(images, mode)`.

UI:
- Dark radial gradient background
- Concentric pulsing rings (3 circles) with leaf emoji center — `pulseRing` animation
- "Analysing..." title in Cormorant 28px
- 4 step cards, each with status icon:
  - ✅ done (green bg) → `as-done`
  - ⏳ in-progress (gold bg, spinner) → `as-doing`
  - ⬜ waiting (dim) → `as-wait`
  
Update step status as API progresses (optimistic: mark step 1 done immediately, rest on response).  
On success → `context.go('/result', extra: plantModel)`.  
On error → show error dialog with "Try Again" button back to `/scan`.  
**Verify:** Steps animate correctly; successful response navigates to Result.

---

### STEP 14 — Result Screen
File: `lib/ui/screens/result/result_screen.dart`

Receives `PlantModel` via `extra`.

**Hero (180px):**
- Green gradient background
- Large plant emoji (72px) top-right
- Back button (top-left), Share button (top-right)
- Confidence badge (`gc` green, dark text): "✓ 94% Match"

**Body (scrollable):**
- Common name (Cormorant 26px dark), scientific name italic, family uppercase green
- `TabBar` with 4 tabs — Overview / Care / Uses / Facts
- Tab styles: `AppColors.ga` active color, underline indicator

**Overview tab:** Region pills row, 2×2 data card grid (Habitat / Height / Bloom / Climate)  
**Care tab:** Soil card, Sunlight card, Water card, pH card, Temp card — each with icon + label + value  
**Uses tab:** Medicinal row, Culinary row, Cosmetic row; red toxicity badge if `isToxic == true`  
**Facts tab:** IUCN status badge, Cultural significance text, Fun fact items

**Actions bar (fixed bottom):**
- "Save Plant" full-width green button → `SavedPlantsRepository.save(plantId)`
- "..." icon button → Share sheet

**Verify:** All 4 tabs render with real data from API; Save button inserts to Supabase.

---

### STEP 15 — History Screen
File: `lib/ui/screens/history/history_screen.dart`

Data: `StreamProvider` on `scans` table filtered by `auth.uid()`, ordered by `scanned_at DESC`.

**UI:**
- Cream background, Cormorant "History" title
- Search bar (rounded, grey bg) — `TextEditingController` filtering list
- Filter chips: All / Medicinal / Edible / Toxic / Saved — updates `activeFilter` in local state
- Date group headers: Today / Yesterday / This Week / Older (computed from `scanned_at`)
- `HistoryItem` widget: colored emoji box | name + time | confidence % | category tag chip
- Tap → `context.go('/plant-detail', extra: plantModel)`

Empty state: illustration + "No scans yet — go identify a plant!"  
**Verify:** Real scans appear; search filters list in real time; date groups correct.

---

### STEP 16 — Encyclopedia Screen
File: `lib/ui/screens/encyclopedia/encyclopedia_screen.dart`

Data: `FutureProvider` on `plants` table (all rows, community-wide), cached locally.

**UI:**
- Cream background, Cormorant "Encyclopedia" title
- Search bar
- Filter chips: All / Medicinal / Edible / Indoor / Rare
- Featured card (dark green gradient, 160px): Plant of the Day with large emoji + name + scientific name + "Explore →" button
- `GridView.builder` 2-column: `PlantCard` widget — colored emoji box, name, scientific name, category tag

`PlantCard` color: alternate pastel green / cream backgrounds by index.  
Tap card → Plant Detail.  
**Verify:** Grid loads; featured card shows today's POTD; filter chips narrow grid.

---

### STEP 17 — Plant Detail Screen
File: `lib/ui/screens/plant_detail/plant_detail_screen.dart`

Receives `PlantModel` via `extra`. Same 4-tab structure as Result but with more content and expanded Wikipedia description.

**Hero (200px):** Gradient, large plant emoji (80px), back button, favorite ❤️ toggle button  
`isFavorited` checked from `saved_plants` on mount.  
Favorite tap → insert/delete row in `saved_plants`.

**Tabs:** Overview / Care / Uses / Facts — same as Result with these additions:
- Overview: full Wikipedia description paragraph (not truncated)
- Facts: Distribution countries list, IUCN status badge

**Verify:** Favorite toggle persists after navigate away and back.

---

### STEP 18 — Profile Screen
File: `lib/ui/screens/profile/profile_screen.dart`

**Hero (160px):** Green gradient; circular avatar (first letter of display name, 72px, overlapping bottom edge)

**Body:**
- Display name (Cormorant 22px) + email (11px muted), centered
- Stats row: 3 equal boxes — Scanned / Species / Saved (same as Home filled)
- Menu rows (white cards):
  - 🌿 My Saved Plants → filtered list bottom sheet
  - 📍 Set My Region → bottom sheet with region picker (saves to Supabase user metadata)
  - 📥 Export History → generates CSV, calls `Share.share()`
  - 🚪 Sign Out → `AuthRepo.signOut()` → go `/splash`
  - ℹ️ About LeafLens → info bottom sheet

**Verify:** Stats are real data; Sign Out clears session and returns to Splash.

---

### STEP 19 — Shimmer Loading + Error States
Add to every screen that loads async data:

**Loading:** `Shimmer.fromColors` skeleton matching the screen layout (same height/width as real content)  
**Error:** Centered column: error icon (🌵) + "Something went wrong" + "Retry" `TextButton` that re-triggers the provider  
**Empty:** Custom illustration + descriptive message (no generic "no data" text)

Apply `AsyncValue.when(data:, loading:, error:)` pattern consistently across all Riverpod providers.  
**Verify:** Throttle network; loading state shows shimmer; kill backend; error state shows retry.

---

### STEP 20 — Release Build & Polish
Before marking the project complete:

- [ ] Compress images before upload: resize to ≤800px longest edge using `image` package
- [ ] App icon: green leaf on `#0B1F12` background — add to `flutter_launcher_icons` config
- [ ] Splash screen: `flutter_native_splash` with same dark green background
- [ ] Enable ProGuard / R8 shrinking for Android release
- [ ] `flutter build apk --release --split-per-abi`
- [ ] Test on a low-end Android (2GB RAM) — fix any jank
- [ ] Final lint: `flutter analyze` → zero errors
- [ ] `README.md`: setup guide, API key registration links, Supabase schema SQL

**Verify:** Signed APK installs on physical device; full scan flow works on mobile data.

---

## 4. Key Patterns & Conventions

### State Management (Riverpod)
- Use `@riverpod` annotation (code generation) for all providers
- Providers live in `lib/providers/` or co-located in screen folder for screen-local state
- Never call Supabase directly from a widget — always via a repository class

### Navigation (GoRouter)
- Never use `Navigator.push()` — always `context.go()` or `context.push()`
- Pass data via `extra:` not query params (except simple strings)
- All routes must be named constants in `AppRoutes` class

### Data Models
- All models are immutable Dart classes with `copyWith`
- Use `fromJson` / `toJson` for Supabase serialization
- `PlantModel` is the central domain object passed between screens

### Error Handling
- FastAPI: all endpoints wrapped in try/except, always return typed error JSON
- Flutter: use `AsyncValue.error` states, never swallow exceptions silently

### Naming Conventions
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Providers: `plantOfDayProvider`, `scanStatsProvider`
- Route constants: `AppRoutes.result = '/result'`

---

## 5. Things Claude Must Never Do

- ❌ Do NOT use `setState` inside complex widgets — use Riverpod `ConsumerWidget`
- ❌ Do NOT store API keys in Flutter source code — use `String.fromEnvironment` or `.env`
- ❌ Do NOT call Supabase from `main.dart` outside of `initialize()`
- ❌ Do NOT use `Navigator.of(context).push` — use GoRouter
- ❌ Do NOT create new color values — only use `AppColors.*` constants
- ❌ Do NOT create new text styles inline — reference `AppTextStyles.*`
- ❌ Do NOT add dependencies not in PLAN.md without asking first
- ❌ Do NOT skip shimmer/error states — every async screen must have all 3 states

---

## 6. Quick Reference: Screen → File Mapping

| Screen | File Path |
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

## 7. Design Fidelity Checklist

When building any screen, cross-check against the HTML prototype (`docs/prototype/leaflens_complete.html`):

- [ ] Background color / gradient matches prototype
- [ ] Font family correct (Cormorant for headings, Outfit for body)
- [ ] Color tokens used (no raw hex strings in widgets)
- [ ] Spacing matches (prototype uses 16–28px padding)
- [ ] Animations present where prototype shows them (splash ring, scan line, analyzing rings)
- [ ] All tab content complete (no placeholder text)
- [ ] Both Home states (empty + filled) implemented
