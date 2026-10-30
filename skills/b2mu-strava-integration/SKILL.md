---
name: b2mu-strava-integration
description: "Defines how the B2MU coaching app integrates with Strava. Covers OAuth authentication, activity fetching, matching Strava runs to planned sessions, extracting pace and distance data, handling conflicts, and updating session status automatically."
---

# B2MU — Strava Integration

## Purpose

Strava integration eliminates manual session logging. When the user completes a run and records it on Strava, the coaching app automatically matches it to the planned session, marks it complete, and extracts actual pace, distance, and duration data.

The integration is **read-only** — the app never writes to Strava.

---

## OAuth Authentication Flow

Strava uses OAuth 2.0. The user must authorise once; tokens are then stored and refreshed automatically.

### Scopes required
```
activity:read_all
```
Do not request write scopes — the app never needs them.

### Auth flow
```
1. User taps "Connect Strava" in app settings
2. App redirects to Strava OAuth URL:
   https://www.strava.com/oauth/authorize
     ?client_id={STRAVA_CLIENT_ID}
     &redirect_uri={REDIRECT_URI}
     &response_type=code
     &scope=activity:read_all

3. User approves → Strava redirects to redirect_uri with ?code=...

4. App exchanges code for tokens:
   POST https://www.strava.com/oauth/token
   {
     client_id, client_secret,
     code,
     grant_type: "authorization_code"
   }

5. Store in Supabase user_settings:
   - strava_access_token
   - strava_refresh_token
   - strava_token_expires_at
   - strava_athlete_id
```

### Token refresh
Access tokens expire after 6 hours. Refresh before every API call:

```javascript
async function getValidStravaToken(env, userId) {
  const settings = await getUserSettings(env, userId);

  if (Date.now() / 1000 < settings.strava_token_expires_at - 300) {
    return settings.strava_access_token; // Still valid
  }

  // Refresh
  const res = await fetch('https://www.strava.com/oauth/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      client_id: env.STRAVA_CLIENT_ID,
      client_secret: env.STRAVA_CLIENT_SECRET,
      refresh_token: settings.strava_refresh_token,
      grant_type: 'refresh_token'
    })
  });

  const data = await res.json();

  await updateUserSettings(env, userId, {
    strava_access_token: data.access_token,
    strava_refresh_token: data.refresh_token,
    strava_token_expires_at: data.expires_at
  });

  return data.access_token;
}
```

---

## Fetching Activities

### Fetch recent activities (last 14 days)
```javascript
async function fetchStravaActivities(accessToken, afterDate) {
  const afterTimestamp = Math.floor(new Date(afterDate).getTime() / 1000);

  const res = await fetch(
    `https://www.strava.com/api/v3/athlete/activities?after=${afterTimestamp}&per_page=30`,
    {
      headers: { 'Authorization': `Bearer ${accessToken}` }
    }
  );

  if (!res.ok) throw new Error(`Strava API error: ${res.status}`);

  const activities = await res.json();

  // Filter to runs only (exclude rides, swims, etc.)
  return activities.filter(a => a.type === 'Run' || a.sport_type === 'Run');
}
```

### Key fields to extract from each activity
```javascript
function extractActivityData(activity) {
  return {
    stravaId:       activity.id,
    name:           activity.name,
    date:           activity.start_date_local.split('T')[0], // YYYY-MM-DD
    distanceKm:     Math.round((activity.distance / 1000) * 100) / 100,
    durationSec:    activity.moving_time,
    avgPaceMinKm:   activity.moving_time / 60 / (activity.distance / 1000),
    avgHeartRate:   activity.average_heartrate || null,
    maxHeartRate:   activity.max_heartrate || null,
    elevationGainM: activity.total_elevation_gain || null,
    effortScore:    activity.perceived_exertion || null, // 1–10 if user logged it
  };
}
```

---

## Matching Activities to Planned Sessions

This is the most important and most complex part of the integration.

### Matching rules (in priority order)

```javascript
function matchActivityToSession(activity, plannedSessions) {
  const activityDate = activity.date;
  const activityKm = activity.distanceKm;

  // 1. Exact date match — same day
  const sameDay = plannedSessions.find(s =>
    s.sessionDate === activityDate &&
    s.type === 'run' &&
    s.status === 'planned'
  );
  if (sameDay) return { session: sameDay, confidence: 'high' };

  // 2. ±1 day match — user ran a day early or late
  const nearbyDay = plannedSessions.find(s => {
    const dayDiff = Math.abs(
      new Date(s.sessionDate) - new Date(activityDate)
    ) / 86400000;
    return dayDiff === 1 && s.type === 'run' && s.status === 'planned';
  });
  if (nearbyDay) return { session: nearbyDay, confidence: 'medium' };

  // 3. No match found
  return { session: null, confidence: 'none' };
}
```

### Distance tolerance for matching
When a match is found, check if the distance is reasonable:

| Planned distance | Acceptable actual range |
|-----------------|------------------------|
| < 10km (easy run) | 50%–150% of planned |
| 10–20km | 70%–130% of planned |
| > 20km (long run) | 80%–120% of planned |

If distance is outside tolerance: still match the session, but flag the discrepancy for the user to review.

### Conflict rules
- If a Strava activity matches a session already marked `completed`: skip — do not overwrite
- If a Strava activity matches a session marked `missed` or `skipped`: surface as a correction prompt ("Looks like you actually ran on this day — want to update?")
- If a Strava activity matches a `FIXED` football session date: do not auto-match — football and running are distinct
- If two activities match the same planned session: take the one with closer distance to planned

---

## Updating Session on Match

On a successful match with `confidence: 'high'`:

```javascript
async function applyStravaMatch(env, session, activity) {
  await updateSession(env, session.id, {
    status: 'completed',
    distanceKm: activity.distanceKm,        // Use actual distance, not planned
    note: buildStravaNote(activity),
    stravaActivityId: activity.stravaId,
    actualPaceMinKm: activity.avgPaceMinKm,
    actualHeartRate: activity.avgHeartRate,
    actualElevationM: activity.elevationGainM,
  });

  // Update week done_km
  await recalculateWeekDoneKm(env, session.weekId);

  // Update progress snapshot
  await updateProgressSnapshot(env, session.userId, session.weekStart);
}

function buildStravaNote(activity) {
  const pace = formatPace(activity.avgPaceMinKm); // e.g. "5:52/km"
  const hr = activity.avgHeartRate ? `, avg HR ${activity.avgHeartRate}bpm` : '';
  const elev = activity.elevationGainM ? `, ${Math.round(activity.elevationGainM)}m elevation` : '';
  return `Strava: ${activity.distanceKm}km @ ${pace}${hr}${elev}`;
}
```

On `confidence: 'medium'` (±1 day match): surface a confirmation prompt to the user rather than auto-applying.

---

## Sync Trigger Points

| Trigger | Action |
|---------|--------|
| User opens the app | Fetch Strava activities for last 14 days, run matching |
| User taps "Sync Strava" manually | Same as above |
| Daily background sync (Phase 3+) | Cloudflare cron, once per day |

Do not sync on every page navigation — once per app open is sufficient.

---

## Schema additions required

Add to the `sessions` table:
```sql
alter table sessions add column strava_activity_id bigint;
alter table sessions add column actual_pace_min_km numeric(5,2);
alter table sessions add column actual_heart_rate integer;
alter table sessions add column actual_elevation_m integer;
```

Add to `user_settings`:
```sql
alter table user_settings add column strava_access_token text;
alter table user_settings add column strava_refresh_token text;
alter table user_settings add column strava_token_expires_at bigint;
alter table user_settings add column strava_athlete_id bigint;
alter table user_settings add column strava_connected_at timestamptz;
```

---

## UI surface points

**Settings tab** (add in Phase 3):
- "Connect Strava" button → triggers OAuth flow
- "Strava connected ✓" state with athlete name and disconnect option
- Last sync timestamp

**Session cards** (Plan tab):
- Strava icon on sessions imported from Strava
- Actual vs planned distance if different (e.g. "18.2km / 18km planned")
- Pace and HR shown in expanded session detail

**Coach context** (auto-enriched):
- Last 3 completed run sessions include Strava pace + HR data
- Coach can reference actual pace vs target pace in feedback

---

## Error handling

| Scenario | Handling |
|----------|---------|
| Strava API rate limit (200 req/15min) | Cache results; retry after 15 min |
| Token expired (refresh fails) | Mark Strava as disconnected; prompt user to reconnect |
| No activities returned | Silently skip sync; do not surface error |
| Activity matches no session | Store in an unmatched log; surface weekly in "unmatched runs" UI |
| Strava API down | Use cached last-sync data; show "last synced X min ago" |

---

## Rules
- Read-only — never write to Strava
- Never auto-apply a match that overwrites a manually confirmed `completed` session
- Never match a Strava run to a FIXED football session
- Always use actual distance from Strava (not planned) when updating session record
- Medium-confidence matches always require user confirmation before applying
- Token refresh must happen before every API call — never use an expired token
- Strava data enriches the coach context but does not override coach logic

## Output Format
- OAuth flow implementation
- Activity fetch and extraction functions
- Matching logic with confidence levels
- Session update procedure
- Schema changes required
- UI surface points
- Error handling table