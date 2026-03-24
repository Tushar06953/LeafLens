# LeafLens — Project Context

## What Is LeafLens?

LeafLens (also called **Flora** internally) is an AI-powered plant identification mobile app built with Flutter. A user photographs a plant — or uploads from gallery — and within seconds receives the species name, confidence score, care guide, medicinal/culinary uses, conservation status, and fun facts. The app is designed to work globally, covering 30,000+ species, with zero monthly infrastructure cost.

---

## Problem It Solves

People encounter plants they cannot identify — in forests, gardens, markets, or roadsides — with no quick, reliable tool to answer "what is this?" Existing solutions are either paywalled, English-only, or return sparse data. LeafLens provides a complete botanical profile, not just a name.

---

## Target Users

| Segment | Use Case |
|---|---|
| Students & nature enthusiasts | Quick identification on hikes / campus |
| Gardeners | Care guidance for soil, water, sunlight |
| Ayurveda / herbal practitioners | Medicinal and culinary use reference |
| Educators | Build in-class plant encyclopedias |
| Rural / grassroots users | Offline-tolerant identification |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter (Dart) — cross-platform iOS + Android |
| State Management | Riverpod |
| Navigation | GoRouter |
| Backend API | FastAPI (Python) on any free-tier host (Render / Railway) |
| Database & Auth | Supabase (PostgreSQL + Auth + Storage) |
| Plant ID API | Pl@ntNet REST API (free tier, 500 req/day) |
| Plant Data | Wikipedia REST API (free, unlimited) |
| Additional Data | Trefle API / GBIF (care data, taxonomy) |
| Image Storage | Supabase Storage buckets |
| Auth Method | Google Sign-In via Supabase OAuth |

**Cost model: $0/month** — all APIs are free tier, Supabase free tier handles early-stage traffic.

---

## 11 Screens (Complete Inventory)

| # | Screen | Key Purpose |
|---|---|---|
| 01 | Splash | Branding, animated logo ring, "Get Started" CTA |
| 02 | Onboarding | 3-slide first-launch walkthrough (shown once via SharedPreferences flag) |
| 03 | Home — Empty State | First-time user; pulsing illustration, scan CTA, tips, Plant of the Day |
| 04 | Home — With Data | Returning user; stats row, recent scans list, Plant of the Day |
| 05 | Scan | Camera with animated scan line, 4 scan modes (Leaf/Flower/Bark/Full Plant), gallery upload, flash, flip, multi-angle (3 photos) |
| 06 | Analyzing | Real-time 4-step progress — Upload → Identify → Fetch Care Data → Build Profile |
| 07 | Result | Identified species; 4 tabs: Overview / Care / Uses / Facts; confidence badge; Save & Share |
| 08 | History | All past scans; search + filter (All/Medicinal/Edible/Toxic/Saved); grouped by date |
| 09 | Encyclopedia | Auto-populated from Supabase; Plant of Day featured; 2-column grid; filter by type |
| 10 | Plant Detail | Deep-dive (accessed from History, Encyclopedia, or Result); 4 tabs; IUCN status; Wikipedia description |
| 11 | Profile | User stats, saved plants list, region setting, CSV export, Google Sign-In |

---

## Core User Flow

```
Splash → Onboarding (first time) → Home
  └── Tap "Scan" → Scan Screen → Analyzing → Result
        ├── Save → History / Profile Favorites
        └── Tap plant in History/Encyclopedia → Plant Detail
```

---

## Data Architecture (Supabase)

### `plants` table
Populated automatically when any user scans. Powers the Encyclopedia.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | PK |
| `scientific_name` | text | From Pl@ntNet |
| `common_name` | text | Localized |
| `family` | text | Botanical family |
| `description` | text | From Wikipedia REST |
| `care_data` | jsonb | Soil, water, sunlight, pH, temp |
| `uses` | jsonb | Medicinal, culinary, cosmetic, toxic flag |
| `iucn_status` | text | Conservation status |
| `region_pills` | text[] | Native regions |
| `potd_date` | date | Plant of the Day rotation |

### `scans` table
Per-user scan history.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | FK → auth.users |
| `plant_id` | uuid | FK → plants |
| `image_url` | text | Supabase Storage |
| `confidence` | float | 0.0–1.0 from Pl@ntNet |
| `scan_mode` | text | leaf / flower / bark / full |
| `scanned_at` | timestamptz | |

### `saved_plants` table
User's favorites/bookmarks.

---

## API Integration Details

### Pl@ntNet
- Endpoint: `POST https://my-api.plantnet.org/v2/identify/all`
- Input: image file + organ type (leaf / flower / bark / auto)
- Output: ranked species list with confidence scores
- Free tier: 500 identifications/day

### Wikipedia REST API
- Endpoint: `GET https://en.wikipedia.org/api/rest_v1/page/summary/{scientific_name}`
- Returns: description paragraph, thumbnail
- Free, no key required

### Trefle / GBIF (Care Data)
- Used as fallback for soil, sunlight, water requirements
- Trefle: `https://trefle.io/api/v1/plants/search`
- GBIF: `https://api.gbif.org/v1/species/match`

---

## Result Screen — 4 Tabs Detail

| Tab | Content |
|---|---|
| **Overview** | Common name, scientific name, family, confidence badge, region pills (native areas), 4 data cards (habitat, height, bloom season, climate) |
| **Care** | Soil type, sunlight requirement, watering frequency, soil pH, temperature range |
| **Uses** | Medicinal properties, culinary uses, cosmetic uses, industrial uses, toxicity warning (red badge if toxic) |
| **Facts** | Cultural significance, IUCN conservation status, 2–3 fun trivia facts |

---

## Design System

| Token | Value |
|---|---|
| Primary Dark | `#0b1f12` (deep forest) |
| Primary Mid | `#1f4233` |
| Accent Green | `#3da876` |
| Highlight Green | `#6fcf97` |
| Gold | `#c8951a` (Plant of Day accents) |
| Cream | `#f5f0e8` (light screen backgrounds) |
| Font — Display | Cormorant Garamond (serif, headings) |
| Font — Body | Outfit (sans-serif, UI text) |

Light screens (Result, History, Encyclopedia, Plant Detail, Profile) use `#fdf8f0` cream background. Dark screens (Splash, Onboarding, Home, Scan, Analyzing) use the green-black gradient system.

---

## What Makes LeafLens Different

1. **Zero cost** — fully built on free tiers
2. **Complete profile** — not just species name; soil, uses, IUCN, trivia
3. **Multi-angle scan** — submit 3 photos for hard-to-identify plants
4. **Auto-growing Encyclopedia** — every scan enriches the shared plant database
5. **Offline-tolerant** — cached plant data from Supabase available without network
6. **India-aware** — region pills include Indian sub-regions; local common names planned
