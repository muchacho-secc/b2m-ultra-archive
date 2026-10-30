---
name: b2mu-schema-design
description: "Designs the Supabase data model for the B2MU coaching app. Covers training weeks, sessions (with fixed anchor support), mutation history for undo, and progress snapshots. Single evolving plan per user — no full versioning."
---

# B2MU — Schema Design

When designing data structures for the B2MU coaching app:

## 1. Identify core entities
Define all entities required to support the full product — not just Phase 1:

| Entity | Purpose |
|--------|---------|
| `weeks` | One record per training week; phase label, volume targets, current flag |
| `sessions` | One record per day per week; type, status, distance, fixed anchor flag |
| `mutations` | Lightweight log of approved plan changes; before/after state for undo |
| `progress_snapshots` | Weekly actual performance data for Progress tab charts |

## 2. Define the schema

### `weeks`
```sql
create table weeks (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null,
  week_start   date not null,           -- always Monday
  label        text not null,           -- e.g. "Apr 13–19"
  week_num     integer not null,        -- relative: 0=current, -1=last, 1=next
  phase        text not null check (phase in ('BASE','BUILD','PEAK','TAPER','CUTBACK')),
  target_km    numeric(6,1) not null default 0,
  done_km      numeric(6,1) not null default 0,  -- denormalised; updated on session completion
  is_current   boolean default false,
  created_at   timestamptz default now(),
  updated_at   timestamptz default now(),
  unique (user_id, week_start)
);
```

### `sessions`
```sql
create table sessions (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null,
  week_id      uuid not null references weeks(id) on delete cascade,
  day_index    integer not null check (day_index between 0 and 6),  -- 0=Mon, 6=Sun
  session_date date not null,
  type         text not null check (type in ('run','football','gym','rest')),
  subtype      text,                    -- "Easy Run", "Long Run", "Training", "Match", "Lower", etc.
  distance_km  numeric(5,1) default 0, -- 0 for non-run sessions
  is_fixed     boolean default false,  -- true for all football sessions; cannot be moved by coach
  status       text not null default 'planned'
                 check (status in ('planned','completed','missed','skipped')),
  note         text,                   -- post-session note or coach annotation
  created_at   timestamptz default now(),
  updated_at   timestamptz default now(),
  unique (user_id, session_date)       -- one session per calendar day
);

create index sessions_week_idx on sessions(week_id, day_index);
create index sessions_user_date_idx on sessions(user_id, session_date desc);
```

### `mutations`
```sql
create table mutations (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null,
  applied_at     timestamptz default now(),
  mutation_type  text not null check (mutation_type in ('minor','major')),
  summary        text not null,         -- one-sentence description shown to user
  reasoning      text,                  -- coach explanation; injected as context in future calls
  changes        jsonb not null,        -- array of change objects (see structure below)
  reversed       boolean default false,
  reversed_at    timestamptz
);

create index mutations_user_idx on mutations(user_id, applied_at desc);
```

**`changes` JSON structure:**
```json
[
  {
    "action": "update_session",
    "session_id": "uuid",
    "before": { "distance_km": 18, "subtype": "Long Run", "status": "planned" },
    "after":  { "distance_km": 20, "subtype": "Long Run", "status": "planned" }
  }
]
```
- Supported actions: `update_session | create_session | delete_session`
- Store only the last 20 mutations per user (enforced at application layer)
- `reversed = true` prevents double-undo

### `progress_snapshots`
```sql
create table progress_snapshots (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null,
  week_start      date not null,
  actual_km       numeric(6,1) not null default 0,
  long_run_km     numeric(5,1),          -- max distance of completed run sessions that week
  sessions_done   integer not null default 0,
  sessions_total  integer not null default 0,
  is_partial      boolean default false, -- true if week is still in progress
  created_at      timestamptz default now(),
  updated_at      timestamptz default now(),
  unique (user_id, week_start)
);
```

## 3. Relationships
```
weeks (1) ──── (7) sessions
  sessions.week_id → weeks.id

sessions (many) ──── mutations (many)
  mutations.changes[].session_id → sessions.id

weeks (1) ──── (1) progress_snapshots
  both keyed by (user_id, week_start)
```

## 4. Row Level Security (RLS)
```sql
alter table weeks enable row level security;
alter table sessions enable row level security;
alter table mutations enable row level security;
alter table progress_snapshots enable row level security;

create policy "user owns weeks"     on weeks     for all using (auth.uid() = user_id);
create policy "user owns sessions"  on sessions  for all using (auth.uid() = user_id);
create policy "user owns mutations" on mutations for all using (auth.uid() = user_id);
create policy "user owns progress"  on progress_snapshots for all using (auth.uid() = user_id);
```

## 5. Key design decisions

| Decision | Reason |
|---------|--------|
| Single evolving plan — no full versioning | Mutation history provides lightweight undo without the cost of versioning |
| `is_fixed = true` on football sessions | Prevents coach from ever scheduling over fixed commitments |
| `unique (user_id, session_date)` on sessions | Enforces one session per calendar day |
| `subtype` is free text, not enum | Allows "Easy Run", "Tempo", "Long Run", "Trail Run" without schema changes |
| `done_km` denormalised on `weeks` | Avoids expensive sum queries on every dashboard load |
| `is_partial` on progress_snapshots | Signals to charts that the current week bar is incomplete |
| `reasoning` stored on mutations | Used as coach context on future API calls — "last time we adjusted X because Y" |

## 6. Calculated values (never stored)
| Value | Calculation |
|-------|-------------|
| Week completion % | `done_km / target_km × 100` |
| Session completion rate | Sum `sessions_done` / sum `sessions_total` over last 6 weeks from `progress_snapshots` |
| Days to race | `date('2026-10-24') - today` |

## 7. Session type reference
| type | is_fixed | subtype examples | distance_km |
|------|----------|-----------------|-------------|
| run | false | Easy Run, Long Run, Tempo, Trail Run | > 0 |
| football | true | Training, Match | 0 |
| gym | false | Lower, Upper, Full Body | 0 |
| rest | false | — | 0 |

## 8. Future extension considerations
- Add `blocks jsonb` to `sessions` for structured sub-blocks (warm-up / tempo / cooldown)
- Add `pace_min_km`, `pace_max_km`, `effort_min`, `effort_max` for pace/effort tracking
- Add `strava_activity_id` to `sessions` for Strava sync
- Add `user_settings` table for configurable race date, football schedule, weekly targets
- Add `hrv_score`, `recovery_score` to `progress_snapshots` for WHOOP/Garmin integration

## Rules
- Do not introduce full plan versioning — mutations handle undo
- Do not use enums for session subtype — use free text
- Do not store calculated values that can be derived cheaply at read time
- Always enforce `is_fixed` at the application layer before generating mutations
- One plan per user — no multi-race or multi-user support in Phase 1

## Output Format
- Entity List
- Table Definitions (with SQL)
- Relationships (described)
- Key Design Decisions
- Future Extension Considerations