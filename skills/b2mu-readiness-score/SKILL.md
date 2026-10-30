---
name: b2mu-readiness-score
description: "Defines the B2MU race-day readiness score. A rolling calculation that combines long run progression, weekly volume trend, session completion rate, recovery data, and weeks remaining. Powers the coach readiness assessment on the Dashboard."
---

# B2MU — Race-Day Readiness Score

## Purpose

The readiness score answers the question the athlete doesn't always know to ask:
> "Am I actually on track to finish this race, or am I falling behind?"

It is a rolling, calculated score that powers the **Coach Readiness** card on the Dashboard. It is not a fitness test — it is a training adherence and progression assessment relative to the race date.

---

## Score components

The readiness score is composed of 5 weighted components:

| Component | Weight | What it measures |
|-----------|--------|-----------------|
| Long run progression | 35% | Is the long run growing on schedule toward peak? |
| Weekly volume trend | 25% | Is overall weekly km trending upward appropriately? |
| Session completion rate | 20% | Is the athlete actually doing the sessions? |
| Recovery (if available) | 10% | Is the athlete absorbing the training load? |
| Phase alignment | 10% | Is the current training matching the expected phase? |

Total: 100 points → mapped to a readiness tier.

---

## Component calculations

### 1. Long run progression score (35 points)

Define the expected long run at each week of the plan:

```javascript
function getLongRunTarget(weeksToRace, currentPhase) {
  // Work backward from race day (24 Oct 2026)
  if (weeksToRace <= 1)  return 12;  // Race week shakeout
  if (weeksToRace <= 2)  return 16;  // Taper week 2
  if (weeksToRace <= 3)  return 20;  // Taper week 1 (start of taper)
  if (weeksToRace <= 6)  return 32;  // Peak phase
  if (weeksToRace <= 10) return 28;  // Build phase (late)
  if (weeksToRace <= 16) return 22;  // Build phase (early)
  if (weeksToRace <= 22) return 18;  // Base phase (late)
  if (weeksToRace <= 27) return 16;  // Base phase (mid) — current position ~Apr 2026
  return 14;                          // Base phase (early) — pre-Apr 2026
}

// NOTE: At ~27 weeks out the target is 16km. The athlete is already at
// 16–18km so the score reflects accurately from the start. Always use
// the highest long run in the last 4 weeks as the actual value — not
// just the most recent — so cutback weeks don't drag the score down.

function scoreLongRunProgression(actualLongRunKm, weeksToRace, currentPhase) {
  const target = getLongRunTarget(weeksToRace, currentPhase);
  const ratio = actualLongRunKm / target;

  if (ratio >= 0.95) return 35;       // On track or ahead
  if (ratio >= 0.85) return 28;       // Slightly behind
  if (ratio >= 0.70) return 18;       // Meaningfully behind
  if (ratio >= 0.55) return 10;       // Significantly behind
  return 0;                            // Far behind
}
```

Use the highest long run completed in the last 4 weeks as the actual value — not just the most recent. This accounts for cutback weeks and prevents the score from underrating a strong athlete on a recovery week.

### 2. Weekly volume trend score (25 points)

```javascript
function scoreVolumeTrend(weeklyHistory) {
  // weeklyHistory: array of last 6 weeks { actualKm, targetKm }
  if (weeklyHistory.length < 3) return 15; // Insufficient data — neutral score

  // Calculate completion ratio for each week
  const ratios = weeklyHistory.map(w => Math.min(1, w.actualKm / w.targetKm));

  // Weighted average (more recent weeks weighted higher)
  const weights = [3, 3, 2, 2, 1, 1]; // most recent first
  const weightedSum = ratios.reduce((sum, r, i) => sum + r * (weights[i] || 1), 0);
  const totalWeight = weights.slice(0, ratios.length).reduce((a, b) => a + b, 0);
  const weightedAvg = weightedSum / totalWeight;

  if (weightedAvg >= 0.90) return 25;
  if (weightedAvg >= 0.75) return 20;
  if (weightedAvg >= 0.60) return 13;
  if (weightedAvg >= 0.45) return 7;
  return 0;
}
```

### 3. Session completion rate score (20 points)

```javascript
function scoreCompletionRate(progressSnapshots) {
  // Last 6 weeks of progress_snapshots
  const recentWeeks = progressSnapshots.slice(0, 6);
  if (recentWeeks.length === 0) return 10; // No data — neutral

  const totalDone  = recentWeeks.reduce((sum, w) => sum + w.sessionsDone, 0);
  const totalPlan  = recentWeeks.reduce((sum, w) => sum + w.sessionsTotal, 0);

  // Exclude fixed football sessions from denominator
  // (they are always 'done' — don't inflate the completion rate)
  const adjustedTotal = totalPlan - (recentWeeks.length * 3); // 3 fixed sessions/week
  const adjustedDone  = totalDone  - (recentWeeks.length * 3);

  const rate = adjustedDone / adjustedTotal;

  if (rate >= 0.90) return 20;
  if (rate >= 0.75) return 16;
  if (rate >= 0.60) return 10;
  if (rate >= 0.45) return 5;
  return 0;
}
```

### 4. Recovery score (10 points — only when wearable connected)

```javascript
function scoreRecovery(recentRecoveryReadings) {
  if (!recentRecoveryReadings || recentRecoveryReadings.length === 0) {
    return 5; // No data — neutral mid-score (not penalised for not having a wearable)
  }

  // Last 7 days of recovery tiers
  const tierValues = { green: 3, yellow: 2, red: 1 };
  const scores = recentRecoveryReadings
    .slice(0, 7)
    .map(r => tierValues[r.readinessTier] || 2);

  const avg = scores.reduce((a, b) => a + b, 0) / scores.length;

  if (avg >= 2.5) return 10;  // Mostly green
  if (avg >= 2.0) return 8;   // Mixed green/yellow
  if (avg >= 1.5) return 5;   // Mostly yellow
  return 2;                    // Predominantly red
}
```

### 5. Phase alignment score (10 points)

```javascript
function scorePhaseAlignment(currentPhase, weeksToRace, longRunKm) {
  // Is the training type matching where we should be in the plan?

  const phaseExpectations = {
    BASE:    { minLongRun: 12, maxLongRun: 26, weeksRange: [16, 40] },
    BUILD:   { minLongRun: 22, maxLongRun: 32, weeksRange: [8, 16] },
    PEAK:    { minLongRun: 28, maxLongRun: 36, weeksRange: [3, 8] },
    TAPER:   { minLongRun: 10, maxLongRun: 22, weeksRange: [0, 3] },
    CUTBACK: { minLongRun: 10, maxLongRun: 24, weeksRange: [0, 40] },
  };

  const expectation = phaseExpectations[currentPhase];
  if (!expectation) return 5;

  const [minWeeks, maxWeeks] = expectation.weeksRange;
  const weeksInRange = weeksToRace >= minWeeks && weeksToRace <= maxWeeks;
  const longRunInRange = longRunKm >= expectation.minLongRun && longRunKm <= expectation.maxLongRun;

  if (weeksInRange && longRunInRange) return 10;
  if (weeksInRange || longRunInRange) return 6;
  return 2;
}
```

---

## Total score → readiness tier

```javascript
function calculateReadinessScore(components) {
  const total = (
    components.longRun +
    components.volume +
    components.completion +
    components.recovery +
    components.phaseAlignment
  );

  let tier, label, direction;

  if (total >= 85)      { tier = 'excellent'; label = 'EXCELLENT';  direction = '▲'; }
  else if (total >= 70) { tier = 'on_track';  label = 'ON TRACK';   direction = '▲'; }
  else if (total >= 50) { tier = 'at_risk';   label = 'AT RISK';    direction = '→'; }
  else if (total >= 30) { tier = 'behind';    label = 'BEHIND';     direction = '↓'; }
  else                  { tier = 'critical';  label = 'NEEDS ATTENTION'; direction = '↓'; }

  return { total, tier, label, direction };
}
```

---

## Dashboard display

The readiness score powers the **Coach Readiness card**:

```
COACH READINESS                    ON TRACK ▲
────────────────────────────────────────────
Long run progression is strong — 18km this week is right on schedule.
Weekly volume consistent at 82% over 6 weeks. Minor dip 2 weeks ago
but recovered well. 27 weeks to race day.
```

The coach note is generated by the AI coach using the score components as context — not hardcoded text.

**Coach context addition when readiness score is available:**
```
--- READINESS SCORE ---
Overall: 78 / 100 (ON TRACK ▲)
Long run: 32/35 — on schedule
Volume: 20/25 — consistent
Completion: 16/20 — 80% of non-fixed sessions done
Recovery: 8/10 — mostly green (WHOOP connected)
Phase alignment: 10/10 — BASE phase, long run on track
```

---

## When to calculate

| Trigger | Frequency |
|---------|-----------|
| App open (Dashboard tab) | Every time — recalculate from current data |
| Session status change | Recalculate immediately |
| New Strava import | Recalculate after sync |
| New recovery reading | Recalculate after sync |

Do not cache the readiness score — always calculate fresh from current data. It is cheap to calculate and must reflect the latest session completions.

---

## Score history (optional, Phase 3+)

Store weekly readiness snapshots for a trend chart:

```sql
alter table progress_snapshots add column readiness_score integer;
alter table progress_snapshots add column readiness_tier text;
```

This enables a "readiness trend" chart in the Progress tab showing whether the athlete is improving or declining over time.

---

## Rules
- Long run progression is the most important component (35%) — never let other components mask a significant long run gap
- Always exclude fixed football sessions from the completion rate denominator
- Never penalise the athlete for not having a wearable — recovery defaults to neutral (5/10)
- The score is informational — it does not automatically trigger plan changes
- A low score surfaces in the coach readiness card and in coach context, which may prompt the coach to suggest adaptations
- Never show the raw numbers to the user — show only the tier label and direction
- The coach note explaining the score is always AI-generated from the components, never hardcoded

## Output Format
- Component calculation functions (with weighting)
- Score → tier mapping
- Coach context addition
- Dashboard display spec
- Calculation trigger points
- Schema additions for score history