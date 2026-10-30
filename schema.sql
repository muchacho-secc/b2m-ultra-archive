-- B2MU schema archive. Source: Supabase project "vdgr-plus-b2mu" (ap-southeast-2, Postgres 17), exported 2026-10-30.
-- Run this FIRST on a fresh Supabase project, then restore.sql.
-- Required extensions (already present on Supabase): pgcrypto, uuid-ossp.
--
-- Layout note: live B2MU data actually spans two places:
--   * b2mu.plans (data jsonb)  -> THE LIVE TRAINING PLAN. All plan reads/writes use this blob.
--   * public.weeks / public.sessions -> older normalised copy of the plan (kept for completeness).
--   * b2mu.strava_activities   -> synced Strava runs.
-- The b2mu.sessions / b2mu.weeks / mutations / progress_snapshots tables were empty.
-- b2mu_dev (dev copy) has the SAME structure as b2mu: to recreate it, run the b2mu section with
-- the schema name replaced by b2mu_dev. Its data was test data and is not archived.
-- Token tables (strava_tokens, whoop_tokens) are created EMPTY: re-run OAuth after restoring.

create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";

create schema if not exists b2mu;

----------------------------------------------------------------------------------------------------
-- b2mu schema
----------------------------------------------------------------------------------------------------
create table b2mu.plans (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  data jsonb,
  updated_at timestamptz default now(),
  constraint plans_pkey primary key (id),
  constraint plans_user_id_key unique (user_id)
);

create table b2mu.weeks (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  week_start date not null,
  label text not null,
  week_num integer not null,
  phase text not null,
  target_km numeric(6,1) not null default 0,
  done_km numeric(6,1) not null default 0,
  is_current boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  constraint weeks_pkey primary key (id),
  constraint weeks_phase_check check (phase = any (array['BASE','BUILD','PEAK','TAPER','CUTBACK'])),
  constraint weeks_user_id_week_start_key unique (user_id, week_start)
);

create table b2mu.sessions (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  week_id uuid not null,
  day_index integer not null,
  session_date date not null,
  type text not null,
  subtype text,
  distance_km numeric(5,1) default 0,
  is_fixed boolean default false,
  status text not null default 'planned',
  note text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  constraint sessions_pkey primary key (id),
  constraint sessions_day_index_check check (day_index >= 0 and day_index <= 6),
  constraint sessions_type_check check (type = any (array['run','football','gym','rest'])),
  constraint sessions_status_check check (status = any (array['planned','completed','missed','skipped'])),
  constraint sessions_week_id_fkey foreign key (week_id) references b2mu.weeks(id) on delete cascade,
  constraint sessions_user_id_session_date_key unique (user_id, session_date)
);
create index sessions_user_date_idx on b2mu.sessions using btree (user_id, session_date desc);
create index sessions_week_idx on b2mu.sessions using btree (week_id, day_index);

create table b2mu.mutations (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  applied_at timestamptz default now(),
  mutation_type text not null,
  summary text not null,
  reasoning text,
  changes jsonb not null,
  reversed boolean default false,
  reversed_at timestamptz,
  constraint mutations_pkey primary key (id),
  constraint mutations_mutation_type_check check (mutation_type = any (array['minor','major']))
);
create index mutations_user_idx on b2mu.mutations using btree (user_id, applied_at desc);

create table b2mu.progress_snapshots (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  week_start date not null,
  actual_km numeric(6,1) not null default 0,
  long_run_km numeric(5,1),
  sessions_done integer not null default 0,
  sessions_total integer not null default 0,
  is_partial boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  constraint progress_snapshots_pkey primary key (id),
  constraint progress_snapshots_user_id_week_start_key unique (user_id, week_start)
);

create table b2mu.strava_activities (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  strava_id bigint,
  data jsonb,
  applied boolean default false,
  synced_at timestamptz default now(),
  constraint strava_activities_pkey primary key (id),
  constraint strava_activities_strava_id_key unique (strava_id)
);

create table b2mu.strava_tokens (
  user_id uuid not null,
  athlete_id bigint,
  access_token text,
  refresh_token text,
  expires_at bigint,
  scope text,
  updated_at timestamptz default now(),
  constraint strava_tokens_pkey primary key (user_id)
);

create table b2mu.whoop_tokens (
  user_id uuid not null,
  access_token text,
  refresh_token text,
  expires_at bigint,
  updated_at timestamptz default now(),
  constraint whoop_tokens_pkey primary key (user_id)
);

----------------------------------------------------------------------------------------------------
-- public schema: legacy normalised B2MU tables (names collide with nothing else if VDGR is not present)
----------------------------------------------------------------------------------------------------
create table public.plans (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  data jsonb not null,
  updated_at timestamptz default now(),
  constraint plans_pkey primary key (id),
  constraint plans_user_id_key unique (user_id)
);

create table public.weeks (
  id text not null default gen_random_uuid(),
  user_id uuid not null,
  week_start date not null,
  label text not null,
  week_number integer not null,
  phase text not null,
  target_km numeric(6,1) not null default 0,
  is_current boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  constraint weeks_pkey primary key (id),
  constraint weeks_phase_check check (phase = any (array['BASE','BUILD','PEAK','TAPER','CUTBACK'])),
  constraint weeks_user_id_week_start_key unique (user_id, week_start)
);

create table public.sessions (
  id text not null,
  user_id uuid not null,
  week_id text not null,
  day_of_week integer not null,
  session_date date not null,
  type text not null,
  subtype text,
  distance_km numeric(5,1),
  is_fixed boolean default false,
  status text not null default 'planned',
  effort_rpe integer,
  note text,
  plan_id text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  constraint sessions_pkey primary key (id),
  constraint sessions_day_of_week_check check (day_of_week >= 0 and day_of_week <= 6),
  constraint sessions_week_id_fkey foreign key (week_id) references public.weeks(id) on delete cascade,
  constraint sessions_user_id_session_date_key unique (user_id, session_date)
);
create index sessions_user_date_idx on public.sessions using btree (user_id, session_date desc);
create index sessions_week_idx on public.sessions using btree (week_id, day_of_week);

create table public.mutations (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  applied_at timestamptz default now(),
  mutation_type text not null,
  summary text not null,
  reasoning text,
  changes jsonb not null,
  reversed boolean default false,
  reversed_at timestamptz,
  constraint mutations_pkey primary key (id)
);
create index mutations_user_idx on public.mutations using btree (user_id, applied_at desc);

create table public.progress_snapshots (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  week_start date not null,
  actual_km numeric(6,1) not null default 0,
  long_run_km numeric(5,1),
  sessions_done integer not null default 0,
  sessions_total integer not null default 0,
  is_partial boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  constraint progress_snapshots_pkey primary key (id),
  constraint progress_snapshots_user_id_week_start_key unique (user_id, week_start)
);

----------------------------------------------------------------------------------------------------
-- Row level security (matches the original, except where marked HARDENING)
----------------------------------------------------------------------------------------------------
alter table b2mu.weeks enable row level security;
alter table b2mu.sessions enable row level security;
alter table b2mu.mutations enable row level security;
alter table b2mu.progress_snapshots enable row level security;
alter table b2mu.strava_activities enable row level security;
alter table b2mu.strava_tokens enable row level security;
alter table b2mu.whoop_tokens enable row level security;
alter table public.weeks enable row level security;
alter table public.sessions enable row level security;
alter table public.mutations enable row level security;
alter table public.progress_snapshots enable row level security;

create policy "user owns weeks" on b2mu.weeks for all using (auth.uid() = user_id);
create policy "user owns sessions" on b2mu.sessions for all using (auth.uid() = user_id);
create policy "user owns mutations" on b2mu.mutations for all using (auth.uid() = user_id);
create policy "user owns progress" on b2mu.progress_snapshots for all using (auth.uid() = user_id);
create policy "user owns strava_activities" on b2mu.strava_activities for all using (auth.uid() = user_id);
create policy "user owns strava_tokens" on b2mu.strava_tokens for all using (auth.uid() = user_id);
create policy "user owns whoop_tokens" on b2mu.whoop_tokens for all using (auth.uid() = user_id);
create policy "user owns weeks" on public.weeks for all using (auth.uid() = user_id);
create policy "user owns sessions" on public.sessions for all using (auth.uid() = user_id);
create policy "user owns mutations" on public.mutations for all using (auth.uid() = user_id);
create policy "user owns progress" on public.progress_snapshots for all using (auth.uid() = user_id);
create policy "Users can manage their own plan" on public.plans for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- NOTE on the two plans tables: in the live project RLS was OFF on b2mu.plans and public.plans
-- (public.plans even has a policy that never took effect). This is reproduced faithfully on purpose:
-- the browser app talks to Supabase with the anon key and no user JWT, and the Cloudflare Workers use
-- SUPABASE_SERVICE_KEY if set, otherwise SUPABASE_ANON_KEY. Turning RLS on would block the anon-key
-- path and break the app. The downside is that anyone holding the anon key can read or edit the plan.
-- If you restore this and want it locked down, FIRST move the app to a server-side service key, THEN:
--   alter table b2mu.plans enable row level security;
--   alter table public.plans enable row level security;
-- (no extra policy is needed for the service role, which bypasses RLS).

----------------------------------------------------------------------------------------------------
-- Schema access for the API roles (best-effort reconstruction of the original grants)
----------------------------------------------------------------------------------------------------
grant usage on schema b2mu to anon, authenticated, service_role;
grant all on all tables in schema b2mu to anon, authenticated, service_role;
-- Also add b2mu to "Exposed schemas" in Supabase Dashboard > Settings > API if the app calls it via REST.
