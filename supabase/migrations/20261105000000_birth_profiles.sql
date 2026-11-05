-- Saved birth charts. Each user can only see and change their own rows.
-- Run in Supabase Dashboard -> SQL Editor (or `supabase db push`).

create table public.birth_profiles (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null default auth.uid()
                       references auth.users (id) on delete cascade,
  name               text not null check (char_length(name) between 1 and 100),
  birth_local        timestamp not null,          -- clock time at birth place
  city_name          text not null,
  state              text not null,
  latitude           double precision not null check (latitude between -90 and 90),
  longitude          double precision not null check (longitude between -180 and 180),
  utc_offset_minutes integer not null default 330,
  created_at         timestamptz not null default now()
);

create index birth_profiles_user_id_idx on public.birth_profiles (user_id);

alter table public.birth_profiles enable row level security;

create policy "Users read own profiles"
  on public.birth_profiles for select
  using ((select auth.uid()) = user_id);

create policy "Users insert own profiles"
  on public.birth_profiles for insert
  with check ((select auth.uid()) = user_id);

create policy "Users update own profiles"
  on public.birth_profiles for update
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users delete own profiles"
  on public.birth_profiles for delete
  using ((select auth.uid()) = user_id);
