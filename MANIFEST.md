# Manifest

Taken 2026-10-30 from Supabase project `vdgr-plus-b2mu` (ap-southeast-2) for user `176fbb36-f663-4510-8743-275dc706dc4d`.

## Data files, verified

Each file was checked against the live database with an md5 over the per-row `to_jsonb` text (numeric scale and timezone normalised), then **re-checked after a full restore into a fresh Postgres 16 using `schema.sql` + `restore.sql`**. All four matched on both checks.

| File | Rows | Row-set checksum (live = restored = file) |
|---|---|---|
| `data/public_weeks.json` | 24 | `e70f7f8eb8b426405b085120d8df7a0a` |
| `data/public_sessions.json` | 167 | `38456c6e9e5007fe26b4a3f10c0c483e` |
| `data/b2mu_plans_live.json` | 1 | `7ffb7ebd618f281f04362f17ff2f1a2c` |
| `data/b2mu_strava_activities.json` | 42 | `90c474d459974019c5070b3f79b770eb` |

## Deliberately excluded

`b2mu.strava_tokens` and `b2mu.whoop_tokens` rows (credentials); 15 stale test plans in `b2mu.plans` (May 2026) and 2 old rows in `public.plans`; `b2mu_dev` data; empty tables (`mutations`, `progress_snapshots`, `b2mu.weeks`, `b2mu.sessions`).

## File hashes (sha256)

4ce34cca69c5c196b7673157698f5992987fddb7358526cfc3026894268cbcb0  schema.sql
a635cf807496ff98e6f1a5b934853b33e7683ba2ed3e8d55a1ff2e14d8ad52a5  restore.sql
1164c060510946dd7cd059517ac8b5873975286eb3685960e7fa5b71b6f0e5d3  remap_user.sql
4c8c6838b09a83cf8e192b6e6e7c0d0f180c68c1087f4dfbace8fa464abbd7ab  data/b2mu_plans_live.json
ac0bb48622fbfffef4776ed7b7c31b80b1cc5941a23e8c9c5a3b9d31ceefda39  data/b2mu_strava_activities.json
36cdb3092d0c6f118e38dcefded8c404aeab3cfa1e442bd037c7280bb8b68f26  data/public_sessions.json
9be73d98303154fff3e8d90959ce01227ee27a9004ed0720c3cd8f32c1cff942  data/public_weeks.json
dec4917da12ccdc23c47d410dcfffc97b803b2e6136e995e6b135d0f693e4ae1  knowledge/project-notes.md
2dfac95723fcd385b67d6986bb376757d8c6d4ac8f59f650396eb47a69551540  RESTORE.md

Skill files under `skills/` are unmodified copies of the 13 `b2mu-*` skills.
