-- B2MU data restore. Run AFTER schema.sql, from inside this folder, with psql:
--   psql "$DATABASE_URL" -f restore.sql
-- (psql is required for the \set ... `cat` lines. Rows are inserted via jsonb_populate_recordset,
--  so column order does not matter and numeric scale is re-applied by the column types.)
--
-- user_id values in the data are the ORIGINAL user: 176fbb36-f663-4510-8743-275dc706dc4d.
-- If the restored app signs in as a different user, run remap_user.sql afterwards (see RESTORE.md).

\set weeks `cat data/public_weeks.json`
\set sessions `cat data/public_sessions.json`
\set plans `cat data/b2mu_plans_live.json`
\set strava `cat data/b2mu_strava_activities.json`

begin;

insert into public.weeks
  select * from jsonb_populate_recordset(null::public.weeks, :'weeks'::jsonb);

insert into public.sessions
  select * from jsonb_populate_recordset(null::public.sessions, :'sessions'::jsonb);

insert into b2mu.plans
  select * from jsonb_populate_recordset(null::b2mu.plans, :'plans'::jsonb);

insert into b2mu.strava_activities
  select * from jsonb_populate_recordset(null::b2mu.strava_activities, :'strava'::jsonb);

-- Sanity check: expect 24, 167, 1, 42
select (select count(*) from public.weeks) as weeks,
       (select count(*) from public.sessions) as sessions,
       (select count(*) from b2mu.plans) as plans,
       (select count(*) from b2mu.strava_activities) as strava_activities;

commit;
