# Restoring B2MU Ultra Coach

Archive taken **2026-10-30**, after the Bondi to Manly Ultra. Goal: bring the app back from scratch in well under an hour.

## What this archive contains

| Path | What it is |
|---|---|
| `schema.sql` | Tables, constraints, indexes, RLS and grants for the `b2mu` and legacy `public` B2MU tables |
| `restore.sql` | Loads the data (psql). Run after `schema.sql` |
| `remap_user.sql` | Re-points restored rows at a new Supabase user id |
| `data/*.json` | Live data: plan (`b2mu.plans`), weeks, sessions, Strava activities |
| `skills/` | The 13 B2MU Claude skills (design/knowledge for schema, coach context, mutations, readiness score, Strava/WHOOP integration, plan generation, UI) |
| `knowledge/project-notes.md` | Project memory: context, architecture lessons, workflow, stack and IDs |
| `MANIFEST.md` | Checksums for every data file and what was verified |

**Code is not in this repo.** It lives in GitHub: `muchacho-secc/b2m-ultra-coach` (private).
Production was deployed from `master` at commit `e17ea6fe15168d8a440d0bacb89939e4effaebb3`
("fix TDZ error in phase calculation causing white screen"), which was also the latest commit on GitHub on
2026-10-30. **Do not delete that repo.** The two Cloudflare Workers (`worker/index.js`, `worker/langgraph/`) are inside it.

## What is NOT in this archive (and why)

- **Secrets / env var values.** Re-create them (names below).
- **Strava and WHOOP tokens.** Credentials, left out on purpose; they would be expired anyway. Re-run OAuth.
- **LangSmith Context Hub prompts** (`b2mu-coach-system-prompt`, `b2mu-ultra-running-science`, `b2mu-course-detail`, `b2mu-athlete-whoop-profile`, `b2mu-athlete-crash-history`). They live in LangSmith. Export them there if you want them preserved.
- **Old plan rows**: 15 test plans from May 2026 in `b2mu.plans` and the older May snapshot in `public.plans`. Only the latest live plan (27 Oct 2026) is kept.
- **`b2mu_dev` data** (1 test plan, 6 Strava rows). Structure is identical to `b2mu`; see the note at the top of `schema.sql`.

## Restore steps

1. **New Supabase project** (any region; original was ap-southeast-2, Postgres 17). Get the Postgres connection string from Dashboard > Connect.
2. **Schema:** `psql "$DATABASE_URL" -f schema.sql`
3. **Data:** `psql "$DATABASE_URL" -f restore.sql` (run from this folder). It prints counts; expect 24 weeks, 167 sessions, 1 plan, 42 Strava activities.
4. **API settings:** Dashboard > Settings > API > add `b2mu` (and `b2mu_dev` if you recreate it) to *Exposed schemas*.
5. **User id:** the data belongs to user `176fbb36-f663-4510-8743-275dc706dc4d`. The app hard-codes this id in its shared `config.js` and uses it as the LangGraph `thread_id`. Easiest path: keep that id in `config.js` and skip remapping. If you sign in as a different user instead, run
   `psql "$DATABASE_URL" -v new_uid='<new id>' -f remap_user.sql` and update `config.js`.
6. **Code:** `git clone https://github.com/muchacho-secc/b2m-ultra-coach` and check out `e17ea6fe15168d8a440d0bacb89939e4effaebb3` (or `master`).
7. **Frontend on Vercel:** new project from that repo. Framework Vite, Node 24.x. Set these environment variables (names from `.env.local.example`):
   `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, `VITE_SUPABASE_SCHEMA` (`b2mu`), `VITE_API_URL`, `VITE_DIRECT_API`, `VITE_ANTHROPIC_KEY`, `VITE_ORS_API_KEY`, `VITE_MAPBOX_TOKEN`.
   The old production domain was `b2m-ultra-coach.vercel.app`. `vercel.json` only sets headers for the PWA manifest and icon caching.
8. **Workers on Cloudflare** (deploy each directory separately; on Windows set `$env:NODE_OPTIONS="--use-system-ca"` first):
   - root `wrangler.toml`: worker `b2m-ultra-coach-api` (+ `-dev`)
   - `worker/langgraph/wrangler.toml`: worker `b2m-ultra-coach-lg-api` (+ `-dev`), with a weekly cron `0 10 * * SUN` (Sunday 8pm AEST)
   - Secrets to set with `wrangler secret put`: `ANTHROPIC_API_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY` (and/or `SUPABASE_SERVICE_KEY`; the worker prefers the service key if present), `B2MU_TELEGRAM_BOT_TOKEN`, `B2MU_TELEGRAM_CHAT_ID`, plus the OpenRouteService key if you build Route Creator.
9. **Reconnect integrations:** redo the Strava OAuth and WHOOP OAuth flows in the app (this repopulates `b2mu.strava_tokens` / `b2mu.whoop_tokens`). Recreate the Telegram bot token if the old bot was removed.
10. **Optional migration:** `supabase/migrations/003_add_mutation_status.sql` in the code repo adds `status` / `proposed_at` columns to `b2mu.mutations` (pending-mutation workflow). It was **never applied** to the live database, so the archived schema does not include it. Apply it if you restore the weekly review agent's pending-mutation feature.

## Things to know before you rely on this

- **Row-level security on the plans tables is OFF**, exactly as in the original, because the browser uses the anon key with no user login. That means anyone holding the anon key can read or edit the plan. `schema.sql` explains how to lock it down safely.
- The restore was **tested end to end** on a throwaway Postgres 16: `schema.sql` then `restore.sql` reproduced all four tables with checksums identical to the live database (see `MANIFEST.md`). It was not tested against a real Supabase project, so steps 4 and the grants in `schema.sql` are best-effort.
- Dates and phases are tied to the 2026 race. A fresh plan for a new event would be generated with the `b2mu-training-plan-generation` skill and `scripts/regenerate-plan-jul26.js` in the repo.
