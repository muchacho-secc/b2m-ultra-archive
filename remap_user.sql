-- Re-point restored B2MU rows at a new user (e.g. after signing in on a fresh Supabase project).
--   psql "$DATABASE_URL" -v new_uid='<new auth.users id>' -f remap_user.sql
-- The app also hard-codes the user id in its shared config.js and uses it as the LangGraph thread_id:
-- update those too (see RESTORE.md).
\set old_uid '176fbb36-f663-4510-8743-275dc706dc4d'

begin;
update public.weeks             set user_id = :'new_uid' where user_id = :'old_uid';
update public.sessions          set user_id = :'new_uid' where user_id = :'old_uid';
update b2mu.plans               set user_id = :'new_uid' where user_id = :'old_uid';
update b2mu.strava_activities   set user_id = :'new_uid' where user_id = :'old_uid';
commit;
