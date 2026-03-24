-- ============================================================
-- LeafLens — Supabase Schema
-- Run this entire file in: Supabase Dashboard → SQL Editor
-- ============================================================

-- Enable UUID extension (already on by default in Supabase)
create extension if not exists "uuid-ossp";

-- ── plants ────────────────────────────────────────────────────────────────────
create table if not exists plants (
  id                    uuid primary key default uuid_generate_v4(),
  scientific_name       text unique not null,
  common_name           text not null,
  family                text not null default '',
  description           text not null default '',
  confidence            float not null default 0,
  image_url             text,
  emoji                 text not null default '🌿',

  -- Care data (stored as JSON object)
  care_data             jsonb not null default '{
    "soil": "Well-draining",
    "sunlight": "Full sun",
    "water": "Moderate",
    "ph": "6.0-7.0",
    "temperature": "15-30C"
  }'::jsonb,

  -- Uses data
  uses                  jsonb not null default '{"is_toxic": false}'::jsonb,

  -- Overview fields
  iucn_status           text,
  region_pills          text[] not null default '{}',
  potd_date             date,
  habitat               text,
  height                text,
  bloom_season          text,
  climate               text,
  cultural_significance text,
  fun_facts             text[] not null default '{}',
  distribution_countries text[] not null default '{}',

  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

-- ── scans ────────────────────────────────────────────────────────────────────
create table if not exists scans (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  plant_id    uuid not null references plants(id) on delete cascade,
  image_url   text,
  confidence  float not null default 0,
  scan_mode   text not null default 'leaf',
  scanned_at  timestamptz not null default now()
);

-- ── saved_plants ──────────────────────────────────────────────────────────────
create table if not exists saved_plants (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  plant_id   uuid not null references plants(id) on delete cascade,
  saved_at   timestamptz not null default now(),
  unique (user_id, plant_id)
);

-- ── Row Level Security ────────────────────────────────────────────────────────
-- plants: public read, backend (service key) writes
alter table plants enable row level security;
create policy "plants_public_read"
  on plants for select using (true);

-- scans: users see only their own rows
alter table scans enable row level security;
create policy "scans_own_read"
  on scans for select using (auth.uid() = user_id);
create policy "scans_own_insert"
  on scans for insert with check (auth.uid() = user_id);
create policy "scans_own_delete"
  on scans for delete using (auth.uid() = user_id);

-- saved_plants: users see and modify only their own rows
alter table saved_plants enable row level security;
create policy "saved_own_read"
  on saved_plants for select using (auth.uid() = user_id);
create policy "saved_own_insert"
  on saved_plants for insert with check (auth.uid() = user_id);
create policy "saved_own_delete"
  on saved_plants for delete using (auth.uid() = user_id);

-- ── Indexes ───────────────────────────────────────────────────────────────────
create index if not exists scans_user_id_idx       on scans (user_id);
create index if not exists scans_plant_id_idx      on scans (plant_id);
create index if not exists scans_scanned_at_idx    on scans (scanned_at desc);
create index if not exists saved_user_id_idx       on saved_plants (user_id);
create index if not exists plants_potd_date_idx    on plants (potd_date);
create index if not exists plants_sci_name_idx     on plants (scientific_name);

-- ── Storage bucket ────────────────────────────────────────────────────────────
-- Run this too (or create via Dashboard → Storage):
insert into storage.buckets (id, name, public)
values ('plant-images', 'plant-images', true)
on conflict do nothing;

create policy "plant_images_public_read"
  on storage.objects for select
  using (bucket_id = 'plant-images');

create policy "plant_images_service_insert"
  on storage.objects for insert
  with check (bucket_id = 'plant-images');
