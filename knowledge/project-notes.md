# B2MU project notes (copied from Claude memory, 2026-10-30)

Verbatim copy of the notes Claude kept for the LangB2MU project. Body-weight / fuelling notes
(`topics/fitness.md`) were intentionally NOT copied here; they remain in Claude memory.

---

## Purpose & context

- Jack built the B2MU Ultra Coach app: a personal AI coaching platform to support his training for the Bondi to Manly Ultra (~80km, 24 October 2026)
- Jack is both the developer and the athlete using the app
- Trains with running and football (soccer) only: no gym or weights sessions
- Football runs on a Saturday match schedule with Tuesday/Thursday training through the season
- GPS tracking is via phone only (no Garmin)
- Sub-9 hour B2M Ultra target; marathon PR 3:25 (Melbourne 2024, 4:42/km)
- Training plan reset: Week 1 = Monday July 20 2026 (Mon-Sun weeks); a "Week 0" run completed Saturday July 18 2026 before official start
- WHOOP wearable used for recovery/strain tracking; recovery scores weighted less than strain due to lifestyle variable noise
- Permanent user ID (Supabase + LangGraph thread_id): `176fbb36-f663-4510-8743-275dc706dc4d`

## State at wind-down (30 Oct 2026)

- The B2M Ultra run is complete; the app is no longer needed. Archived so it can be restored quickly.
- Strava integration worked in production after resolving the `--env=""` deployment issue and an OAuth `redirect_uri` bug (fixed via `new URL(request.url)`)
- Dev/prod split fully built: dev work targets the `dev` branch and `b2mu_dev` schema
- Known open bug at one point: stale-closure/race condition: `matchGPSToLegs` and `autoUpdateCoachMemory` both captured `store.plan` at async start, then overwrote the Strava-enriched plan with stale state. Fix strategy: scope each async function to merge only its own field slice
- Weekly Autonomous Review agent: Cloudflare Cron Sundays 8pm AEST on the LangGraph worker; analyses the previous week, sends a Telegram notification with proposed changes, writes pending mutations to Supabase, updates coach memory. Initial version built; known issues: analysing current vs previous week, missing structured formatting
- Route Creator feature was designed but not built: OpenRouteService API (foot-hiking profile), default start at 10 Cutler Street Bondi, hardcoded B2M leg waypoints, Strava GPS trace auto-matching (60% waypoint overlap within 100m = completed recce), Mapbox display with elevation profile and GPX download
- Race-day fuelling rule used: take on fuel every 4km, first at 4km

## Architecture learnings

- Stale closure / optimistic UI race condition is the recurring architectural weakness: any async function that captures React state at start and calls `setPlanDirectly` after awaiting will overwrite concurrent state updates. Fix pattern: merge only the specific field slice each function owns, never reconstruct the full plan object
- Supabase-first mutations: coach suggestions and plan mutations must be applied server-side (fetch fresh from Supabase, mutate, save back), not via React state
- All live plan data lives in the `b2mu.plans.data` JSONB blob. The `sessions` table exists but is empty and unused. Reads/writes use `jsonb_array_elements` traversal
- Schema must always be specified explicitly (`b2mu` prod, `b2mu_dev` dev)
- Wrangler deployment quirk (Windows/PowerShell): run `$env:NODE_OPTIONS="--use-system-ca"` before `wrangler deploy` to avoid TLS errors. Run directly in a terminal, not through Claude Code. Each worker directory must be deployed separately
- LLM date injection: inject only plain `TODAY: YYYY-MM-DD` into system prompts; custom day-of-week index notation confuses the LLM
- Vercel bundle hash: the JS bundle filename hash is the most reliable indicator that a new build is live
- Claude Code must be opened from the project root; running from the wrong directory causes edits to miss source files while still committing

## Workflow & patterns

- Dev-first: changes land on `dev` branch / `b2mu_dev` schema / Vercel Preview URL / `b2mu-coach-dev` LangSmith project first. Never commit directly to `main`
- Dev cron triggers disabled to prevent duplicate Telegram messages
- Build start checklist: verify user_id first: check Supabase auth for duplicate users, ensure the single permanent UUID is migrated across all tables and hardcoded in shared `config.js` for both builds, and used as the LangGraph `thread_id`
- Coach system prompt stored in LangSmith Context Hub (`b2mu-coach-system-prompt`) for live updates without redeployment; skills pulled via the `client.pullAgent()` pattern in the LangGraph worker
- Claude Code prompt discipline: directive prompts (state the goal, not the implementation). End with `git add -A && git commit -m "..." && git push`, targeting `dev` unless merging to production
- Debugging: inspect the Vercel bundle hash and `updated_at` on the Supabase plans row to confirm writes occurred; use Supabase MCP to verify session data before and after mutations
- Prefers Claude Code to handle file edits and commits while he runs `wrangler deploy` manually

## Stack & resources

- React/Vite on Vercel; Cloudflare Workers (`b2m-ultra-coach-api`, `b2m-ultra-coach-lg-api`); Supabase (shared with VDGR); LangGraph; LangSmith (APAC endpoint); Anthropic API
- Supabase schemas: `b2mu` (prod), `b2mu_dev` (dev)
- Key query pattern: `from b2mu.plans p, jsonb_array_elements(p.data->'weeks') as w, jsonb_array_elements(w->'sessions') as s where p.user_id = '176fbb36-f663-4510-8743-275dc706dc4d'`
- Vercel: projectId `prj_mW6QCtZp0yq2IOA8dCJHteW7eQ4G`, teamId `team_ikB80XSwAZ2livySTFdZIkjM`
- LangSmith Context Hub skills in prod: `b2mu-coach-system-prompt`, `b2mu-ultra-running-science`, `b2mu-course-detail`, `b2mu-athlete-whoop-profile`, `b2mu-athlete-crash-history` (these live in LangSmith, NOT in this archive)
- Telegram: separate bot per product area; LangGraph worker was at `b2m-ultra-coach-lg-api.b2mucoach.workers.dev`
- WHOOP: 1,086-day data export analysed; physiological profile and crash history stored as LangSmith Context Hub skills
- OpenRouteService API keys were set as Cloudflare Worker secrets in both worker environments
