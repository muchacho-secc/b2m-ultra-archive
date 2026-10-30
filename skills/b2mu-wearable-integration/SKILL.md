---
name: b2mu-wearable-integration
description: "Defines how the B2MU coaching app integrates with WHOOP and Garmin to receive HRV and recovery data. Covers data fetching, recovery score interpretation, how recovery signals influence the adaptive plan engine, and what the coach can and cannot say based on wearable data."
---

# B2MU — Wearable Integration (WHOOP / Garmin)

## Purpose

Wearable integration feeds objective recovery data into the coaching app. The coach uses HRV and recovery scores to adapt session recommendations — suggesting load reduction when recovery is poor, or confirming a hard session is appropriate when recovery is strong.

This is about **readiness signals**, not activity records. Strava handles what happened. Wearables tell us how recovered the athlete is.

---

## Supported devices

### WHOOP
- Provides: daily recovery score (%), HRV (ms), resting HR, sleep duration and quality, strain score
- API: WHOOP Developer API (OAuth 2.0)
- Data availability: daily, updated after morning sync
- Free tier: available for existing WHOOP members

### Garmin Connect
- Provides: daily HRV status, body battery, resting HR, sleep score, stress level
- API: Garmin Health API (OAuth 1.0a)
- Data availability: daily, synced via device
- Free tier: available for existing Garmin device owners

Build for WHOOP first — cleaner API, more relevant recovery data for endurance athletes.

---

## WHOOP Integration

### OAuth Flow
```
Scopes required: read:recovery, read:sleep, read:body_measurement

Auth URL: https://api.prod.whoop.com/oauth/oauth2/auth
Token URL: https://api.prod.whoop.com/oauth/oauth2/token
```

```javascript
async function fetchWHOOPRecovery(accessToken, date) {
  // date format: YYYY-MM-DD
  const start = `${date}T00:00:00.000Z`;
  const end   = `${date}T23:59:59.000Z`;

  const res = await fetch(
    `https://api.prod.whoop.com/developer/v1/recovery?start=${start}&end=${end}`,
    { headers: { 'Authorization': `Bearer ${accessToken}` } }
  );

  const data = await res.json();
  const record = data.records?.[0];
  if (!record) return null;

  return {
    date,
    recoveryScore:  record.score.recovery_score,     // 0–100
    hrv:            record.score.hrv_rmssd_milli,    // ms
    restingHR:      record.score.resting_heart_rate, // bpm
    sleepDuration:  record.score.sleep_need?.need_from_sleep_debt || null,
    source:         'whoop'
  };
}
```

---

## Garmin Integration

### OAuth 1.0a (more complex than WHOOP)
```javascript
async function fetchGarminHRV(accessToken, accessSecret, date) {
  // Garmin uses OAuth 1.0a — requires signed requests
  // Use a library like 'oauth-1.0a' for signing
  const endpoint = `https://apis.garmin.com/wellness-api/rest/hrv?uploadStartTimeInSeconds=${toUnixTimestamp(date)}`;

  const signedHeaders = signOAuth1Request(endpoint, accessToken, accessSecret, env);

  const res = await fetch(endpoint, { headers: signedHeaders });
  const data = await res.json();

  return {
    date,
    hrv:          data[0]?.hrvValues?.[0] || null,  // ms
    hrvStatus:    data[0]?.hrvStatus || null,         // 'BALANCED', 'LOW', 'UNBALANCED', 'POOR'
    bodyBattery:  null, // fetched separately from wellness endpoint
    source:       'garmin'
  };
}
```

---

## Recovery data model

Store daily recovery readings in a new table:

```sql
create table recovery_readings (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null,
  date           date not null,
  source         text not null check (source in ('whoop', 'garmin', 'manual')),

  -- Core metrics
  recovery_score integer,       -- 0–100 (WHOOP) or derived equivalent
  hrv_ms         numeric(6,1),  -- HRV in milliseconds
  resting_hr     integer,       -- bpm
  sleep_hours    numeric(4,1),  -- hours

  -- Derived
  readiness_tier text check (readiness_tier in ('green', 'yellow', 'red')),

  -- Raw (optional, for debugging)
  raw_data       jsonb,

  created_at     timestamptz default now(),

  unique (user_id, date, source)
);

create index recovery_user_date_idx on recovery_readings(user_id, date desc);
```

---

## Recovery tier classification

Translate raw scores into a simple 3-tier system the coach and UI can use consistently:

```javascript
function classifyReadiness(reading) {
  if (reading.source === 'whoop') {
    if (reading.recoveryScore >= 67) return 'green';
    if (reading.recoveryScore >= 34) return 'yellow';
    return 'red';
  }

  if (reading.source === 'garmin') {
    const statusMap = {
      'BALANCED':   'green',
      'LOW':        'yellow',
      'UNBALANCED': 'yellow',
      'POOR':       'red'
    };
    return statusMap[reading.hrvStatus] || 'yellow';
  }

  // Manual or unknown: derive from HRV if available
  // Use athlete's personal baseline (stored in user_settings)
  if (reading.hrv_ms) {
    const baseline = reading.userHrvBaseline || 50; // fallback baseline
    if (reading.hrv_ms >= baseline * 1.05) return 'green';
    if (reading.hrv_ms >= baseline * 0.85) return 'yellow';
    return 'red';
  }

  return 'yellow'; // Default if insufficient data
}
```

---

## How recovery influences the coaching app

Recovery data feeds into two places: the **coach context** and the **adaptive plan engine**.

### In coach context
Add to the context block when recovery data is available:

```
--- RECOVERY (today) ---
Source: WHOOP
Recovery score: 74% (Green)
HRV: 68ms (baseline: 62ms — above baseline)
Resting HR: 51bpm
Sleep: 7h 22m
Readiness tier: GREEN — full training load appropriate
```

### In adaptive plan engine
Recovery tier modifies session recommendations:

| Readiness tier | Planned session | Coach action |
|---------------|----------------|-------------|
| 🟢 Green | Any session | Confirm as planned — no change needed |
| 🟡 Yellow | Easy run | Confirm, but suggest keeping effort at low end of range |
| 🟡 Yellow | Long run | Confirm, but suggest no progression — hold current distance |
| 🟡 Yellow | Tempo / hard session | Suggest converting to easy run — surface as minor mutation |
| 🔴 Red | Easy run | Suggest converting to rest or very easy 20–30 min — major mutation |
| 🔴 Red | Long run | Strongly suggest postponing 1 day if possible — major mutation |
| 🔴 Red | Gym | Suggest skipping or reducing to mobility only |
| 🔴 Red | Rest | Confirm — rest was the right call |

**Important:** Recovery data informs but does not override. The coach presents a suggestion — the user approves. A red day does not automatically cancel a session.

---

## What the coach CAN say based on wearable data

✅ "Your HRV is above baseline today — your body is well recovered. The 18km long run is a good call."

✅ "Recovery is in the yellow today — you ran a solid match yesterday. I'd keep today's easy run at the low end of the effort range, around 6:10–6:20/km."

✅ "Red recovery this morning — HRV is 15% below your baseline. I'd suggest converting today's tempo to an easy 30 minutes, or taking an extra rest day. Up to you."

## What the coach CANNOT say based on wearable data

❌ Never diagnose illness or injury from wearable data
❌ Never tell the user they must rest — always frame as a suggestion
❌ Never override a user's decision to train on a red day (note it, respect it)
❌ Never reference recovery data if the user hasn't connected a wearable
❌ Never claim HRV data is a precise measurement — it's a trend indicator

---

## UI surface points

**Dashboard tab:**
- Recovery badge next to today's session: 🟢 / 🟡 / 🔴
- Tap to expand: shows score, HRV, sleep duration

**Settings tab:**
- "Connect WHOOP" / "Connect Garmin" buttons
- Connected state with last sync timestamp
- Option to set manual HRV baseline if no wearable

**Progress tab (Phase 3+):**
- Recovery trend chart (7-day rolling)
- Correlation between recovery tier and session completion

**Coach context:**
- Recovery section always present when data is available
- Absent when no wearable connected (coach does not reference it)

---

## HRV baseline calculation

The readiness tier is only meaningful relative to the athlete's personal baseline. Store and update the baseline:

```javascript
// Calculate rolling 30-day HRV baseline
async function updateHRVBaseline(env, userId) {
  const readings = await getRecentRecoveryReadings(env, userId, 30);
  const hrvValues = readings
    .filter(r => r.hrv_ms !== null)
    .map(r => r.hrv_ms);

  if (hrvValues.length < 7) return; // Not enough data yet

  const baseline = hrvValues.reduce((a, b) => a + b, 0) / hrvValues.length;

  await updateUserSettings(env, userId, {
    hrv_baseline_ms: Math.round(baseline * 10) / 10
  });
}
```

Update baseline weekly, not daily — it should be stable.

---

## Error handling

| Scenario | Handling |
|----------|---------|
| Wearable not synced yet (morning) | Show "Recovery data pending" — check again in 1 hour |
| API unavailable | Use yesterday's reading with "using yesterday's data" label |
| No wearable connected | Remove recovery section from coach context entirely |
| HRV below 20ms (likely noise) | Flag as invalid; do not classify; request user check device |
| Token expired | Same refresh pattern as Strava — refresh before every call |

---

## Rules
- Never use recovery data to override user decisions — only to inform suggestions
- Never reference recovery data in coach responses if no wearable is connected
- Always classify into green / yellow / red before surfacing — never show raw scores to coach
- HRV baseline must be personalised — do not use a population average as the baseline
- Recovery suggestions always flow through the mutation workflow (yellow/red → suggest → approve)
- Wearable data is supplementary — the plan is still the source of truth

## Output Format
- OAuth implementation for chosen device (WHOOP first)
- Activity/recovery fetch functions
- Recovery tier classification logic
- Schema additions
- Coach context additions
- Adaptive plan influence table
- UI surface points
- Baseline calculation approach