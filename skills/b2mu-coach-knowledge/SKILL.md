---
name: b2mu-coach-knowledge
description: "Defines the complete athlete profile, race course knowledge, and enhanced context system for the B2MU AI coach. Covers the B2M Ultra course breakdown by leg, athlete benchmarks derived from Strava data, easy pace enforcement (83% failure rate confirmed by data), long run base status, trail experience gaps, coach memory field, football RPE logging, weekly check-in, all-run data injection, and week intent field. Use this skill when building or extending the coach system in the B2MU app — it supersedes and extends b2mu-coach-context for all coach quality improvements."
---

# B2MU — Coach Knowledge & Enhanced Context

This skill defines everything the B2MU AI coach needs to know and receive on every API call. It extends the existing `b2mu-coach-context` skill with real athlete data, full race course intelligence, and new data inputs that make coaching specific rather than generic.

## Core principle
> The coach is only as good as what it knows. Generic coaching advice is useless. Every response must reference actual data about this athlete on this course.

---

## PART 1: HARDCODED ATHLETE PROFILE

Inject this as a fixed section in `buildCoachSystemPrompt`. It never changes.

```
═══════════════════════════════════════
ATHLETE PROFILE — DATA-DRIVEN
═══════════════════════════════════════
Race: Bondi to Manly Ultra 2026
Race Date: Saturday 24 October 2026
Goal Finish Time: Sub-9 hours (~6:50/km adjusted pace across 79km terrain)
This is a PERFORMANCE goal, not a survival goal.

RACE RESULTS:
  5km: 19:30 | 10km: 42:03 | Half Marathon: 1:34:27 | Marathon: 3:18:12
  Sydney Marathon 2023: 5:15/km avg, HR:170 — first marathon
  Melbourne Marathon 2024: 4:42/km avg, HR:166 — 33min improvement
  2 marathons completed. Knows how to suffer. Understands race execution.

STRAVA-CONFIRMED TRAINING HISTORY (254 runs, Apr 2020 – May 2026):
  2024: 62 runs, 630km — marathon training year, highest volume
  2025: 34 runs, 249km — post-marathon drop, football dominant
  2026 to date: 14 runs, 95km — plan just started Apr 6

MARATHON TRAINING PEAK LONG RUNS (Aug–Oct 2024):
  23.62km @ 4:58/km HR:154
  30.00km @ 4:58/km HR:151
  30.00km @ 4:58/km HR:159
  34.09km @ 4:48/km HR:160  ← longest run ever
  These are the benchmark. The athlete CAN run long — but hasn't since.

POST-MARATHON LONG RUN GAP:
  Longest run in 12 months after Melbourne (Oct 2024 – Oct 2025): 16.17km
  The long run base must be rebuilt from ~13–16km, not from marathon peak.
  Progress carefully. The engine is there — the specific endurance is not.

CRITICAL — EASY PACE FAILURE (DATA-CONFIRMED, NOT SELF-REPORTED):
  Of 55 runs between 5–15km with HR data across 2024–2026:
  → 46 runs (83%) were faster than 5:30/km
  → Average pace of those "easy" runs: 5:06/km @ HR:157bpm
  → HR:157 is THRESHOLD effort. Not easy. Not zone 2.
  → Only 4 runs in 2+ years were genuinely run at easy pace (6:00+/km)
  → The athlete KNOWS this — one run is literally named "Trying to find zone 2, failing"

  EASY PACE RULE — NON-NEGOTIABLE:
  Easy/recovery runs: 6:00–6:30/km on flat road. Full stop.
  If Strava shows any easy run faster than 5:50/km on flat terrain → flag it immediately.
  Use: "Your [day] easy run came in at [pace] — that's too fast again. 
  Easy = RPE 3 = conversational = 6:00–6:30 for you. Your data shows you've run 
  83% of your easy runs too fast over the past 2 years. This is the habit to break."

TRAIL EXPERIENCE (data-confirmed, minimal):
  Identifiable trail sessions in 2+ years of Strava data: ~5
  - Coogee Stairmaster x2 (Jan 2025): 3km, ~195m elev — good stair awareness
  - Lane Cove National Park (Jun 2025): 12.64km @ 8:25/km, 220m elev — appropriate pacing
  - Blue Mountains (Aug 2023): 13km @ 6:19/km, 398m elev
  Trail experience is minimal. Stair tolerance exists but is limited.
  This is the single biggest physical gap vs the B2M course demands.

MONTHLY RUN FREQUENCY:
  Typical outside marathon blocks: 1–4 runs/month, 8–40km
  Football dominates the training week — running sessions must be valued and protected
  Volume consistency is more important than any single session

PRIMARY LIMITERS (confirmed by data, ranked by race risk):
  1. Trail technique and stair tolerance — minimal trail background
  2. Long run base — needs rebuilding from 13–16km after 12-month gap
  3. Easy pace discipline — 83% failure rate confirmed by Strava
  4. Fuelling — drinks but historically doesn't eat on runs (no ultra race experience)
  5. Back-half fatigue management — 9 hours means the first 40km determines the last 40km

STRENGTHS (confirmed by data):
  Strong aerobic engine — HR 151–160 on marathon long runs shows genuine fitness
  Responds well to training — 33-minute marathon improvement in one cycle
  Football fitness — real cardio base, high-RPE effort tolerance
  Stair awareness exists — Coogee Stairmaster sessions show the right instinct
  Self-aware — named a run "trying to find zone 2, failing" — knows what's needed
```

---

## PART 2: HARDCODED RACE COURSE KNOWLEDGE

Inject this as a fixed section in `buildCoachSystemPrompt`. It never changes.

```
═══════════════════════════════════════
RACE COURSE — B2M ULTRA
═══════════════════════════════════════
Distance: 79km | Elevation: 1,648m (official)
Terrain: cliff trails, urban paths, harbourside, bush tracks, stairs, sand
Character: constantly undulating — no flat sections, no single steady rhythm

LEG 1 — Bondi to Rose Bay: 19km | 329m
  Cliff tops Dover Heights → Watsons Bay → South Head → Hermitage Foreshore
  Technical coastal trail from the start. Checkpoint at ~20km.
  COACHING NOTE: Most runners go too hard here. Scenery creates excitement-pacing.
  Start at race pace minus 10–15 seconds. This is where the race is most often lost.

LEG 2 — Rose Bay to Milson Park: 20km | 360m
  Rushcutters Bay → Opera House → Harbour Bridge → Milson Park North Sydney
  HIGHEST elevation gain of any leg despite being urban. Massively underestimated.
  Drop bag available HERE at ~40km checkpoint — the only drop bag on course.
  COACHING NOTE: Don't linger at 40km. Reload quickly, keep moving.
  The iconic sections (Opera House, Harbour Bridge) lift mood — don't let that
  inflate effort. Body is still being asked to climb 360m of elevation.

LEG 3 — Milson Park to Clontarf: 23km | 326m
  Cremorne Point → red gum forests → Bradleys Head → Gubbah Gubbah → Clontarf
  Longest leg. Technical bush trail. Fatigue compounds here.
  More stairs, beach segments, technical trail. Sand is energy-sapping.
  Checkpoint at ~60km.
  COACHING NOTE: Fuelling discipline wins or loses the race on this leg.
  Eat every 30–40 min from km 10 onwards. Load up fully at 60km checkpoint.

LEG 4 — Clontarf to Manly via North Head: 18km | 256m
  Spit to Manly (rolling bushland, heavy stairs) → past Manly Wharf
  (200m from finish line) → UP and around North Head → back to Manly Beach
  Shortest leg, one of the toughest. Deliberate psychological cruelty.
  COACHING NOTE: Train this section in PEAK phase. Running North Head on tired
  legs in training removes the psychological shock on race day.

AID STATIONS: 4 stations + 3 water points
DROP BAG: Milson Park (~40km) only

COURSE RULES:
  1. Start conservative — scenery and excitement kill back-half performance
  2. Leg 2 is deceptive — most elevation despite looking urban and flat
  3. Sand sections in Leg 3 — shorten stride, stay patient, don't fight it
  4. North Head at km 75 is the decisive moment — train it specifically
  5. October Sydney can be warm from km 40 onwards — hydrate from km 1
  6. Stairs are the biggest physical gap for this athlete — train them specifically

TRAINING REQUIREMENT — ALL FOUR LEGS MUST BE RUN BEFORE RACE DAY:
  Leg 1 (19km, 329m): BASE phase — schedule as long run
  Leg 2 (20km, 360m): BUILD phase — midweek long or weekend effort
  Leg 3 (23km, 326m): PEAK phase — Saturday of back-to-back weekend
  Leg 4 (18km, 256m): PEAK phase — Sunday of same back-to-back weekend
  Ideal PEAK back-to-back: Leg 3 Sat + Leg 4 Sun = 41km race terrain with fatigue carryover
  Coach tracks completion and flags overdue legs proactively.
```

---

## PART 3: ENHANCED DYNAMIC CONTEXT

Extends what `buildCoachSystemPrompt` injects on every call.

### New sections to add to the dynamic context

**All-run completion data (last 5 runs, all types):**
```
═══════════════════════════════════════
RECENT RUN DATA (last 5 completed)
═══════════════════════════════════════
[DATE] [subtype] [distance]km
  Pace: [actual]/km (target: [target]/km) | HR: [N]bpm | Elev: [N]m | [Strava/manual]
  [⚠ PACE FLAG if easy/recovery run < 5:50/km: "Easy pace too fast — target 6:00–6:30"]
```
Previously only long runs had Strava data injected. Inject pace + HR for ALL run types.
This enables catching the easy-too-fast pattern, assessing interval quality, detecting fatigue from HR drift.

**Upcoming 4 weeks with intent:**
```
═══════════════════════════════════════
UPCOMING 4 WEEKS
═══════════════════════════════════════
  [week label]: [total km] | LR: [N]km | Intent: [build/consolidate/cutback/peak/taper]
  [CUTBACK WEEK — do not increase load] if applicable
  [LEG N course section due this phase] if applicable
```

**Course section completion status:**
```
═══════════════════════════════════════
COURSE SECTION COMPLETION
═══════════════════════════════════════
  Leg 1 Bondi–Rose Bay (19km, 329m):    [DONE date | NOT YET — due BASE]
  Leg 2 Rose Bay–Milson (20km, 360m):   [DONE date | NOT YET — due BUILD]
  Leg 3 Milson–Clontarf (23km, 326m):   [DONE date | NOT YET — due PEAK]
  Leg 4 Clontarf–Manly (18km, 256m):    [DONE date | NOT YET — due PEAK]
```

**Football RPE (if logged this week):**
```
Football RPE this week:
  TUE: RPE [N] | THU: RPE [N] | SAT: RPE [N]
  [High-load flag if any session RPE 8+]
  [If not logged: "Football RPE not logged"]
```

**Weekly check-in (if submitted):**
```
Weekly check-in:
  Sleep: [1–5] | Stress: [1 High / 2 Moderate / 3 Low]
  [Flag if sleep ≤ 2 or stress = 1]
  [If not submitted: "Check-in not logged this week"]
```

**Coach memory:**
```
═══════════════════════════════════════
COACH MEMORY
═══════════════════════════════════════
Form narrative: [value or "No notes yet"]
Injury notes: [value or "None flagged"]
Fuelling progress: [value or "Not assessed — gel testing begins BUILD phase"]
Athlete patterns: [value or "83% of easy runs run too fast — confirmed by Strava data"]
Athlete intel: [value or "Nothing specific noted yet"]
Last updated: [date or "Never"]
```

---

## PART 4: COACH MEMORY FIELD

### Plan schema addition
```javascript
coach_memory: {
  form_narrative: null,   // Current form and momentum
  injury_notes: null,     // Flagged niggles or resolved issues
  fuelling_progress: null,// What's been tested, what works
  athlete_patterns: null, // Observed tendencies (pre-populate from Strava analysis)
  athlete_intel: null,    // Things user has explicitly told the coach
  last_updated: null,
}
```

### Pre-populate on first load
When the plan is first created, pre-populate `athlete_patterns` with:
```
"83% of easy runs over the last 2 years were faster than 5:30/km at avg HR:157 (threshold effort). 
Athlete is self-aware about this — named a run 'Trying to find zone 2, failing'. 
Long run base gap: 12 months without a run >16km after Melbourne Marathon Oct 2024."
```

### How memory updates work
- Coach proposes updates using `MEMORY_UPDATE:` suffix
- User approves via same tap-to-approve UI as plan mutations
- Each field: 2–4 sentence string, coach overwrites whole field
- Visible and manually editable in Settings

### Memory update format
```
MEMORY_UPDATE:{"field":"form_narrative","value":"Strong 4-week build to 22km. Cutback due. Easy pace has improved — last 3 easy runs all within 6:00–6:20 range. Progress."}
```

---

## PART 5: FOOTBALL RPE LOGGING

### UI
Post-session prompt card on Plan tab after each football session.

Training (Tue/Thu):
```
How was [Tuesday / Thursday] training?
[ Light  RPE 5 ]  [ Normal  RPE 7 ]  [ Hard  RPE 8 ]
```
Match (Sat):
```
How was the match?
[ Good game  RPE 8 ]  [ Hard match  RPE 9 ]  [ Gruelling  RPE 10 ]
```

### Storage: `football_rpe: 8` on session completion object

### Coach use
- RPE 8+ Saturday → flag conservative Sunday long run start
- High RPE all three sessions → high-load football week, reduce run load expectations
- Low RPE → normal, proceed with plan

---

## PART 6: WEEKLY CHECK-IN

### Sunday prompt (two questions, dismissible):
```
Sleep this week:  [ Poor 1 ] [ Patchy 2 ] [ OK 3 ] [ Good 4 ] [ Great 5 ]
Life stress:      [ High ] [ Moderate ] [ Low ]
```

### Storage: `check_in: { sleep: 4, stress: 2, logged_at: "2026-05-18" }` on week object
Stress maps: High=1, Moderate=2, Low=3

### Coach use
- Sleep ≤ 2 → dial back hard sessions
- Stress = 1 → recovery slower than plan assumes
- Both poor → conservative week regardless of intent
- WHOOP active → sleep auto-populated, only stress question needed

---

## PART 7: WEEK INTENT FIELD

Add `intent` to each week in plan schema.
Values: `build` | `consolidate` | `cutback` | `peak` | `race-prep` | `taper`

**Coach rule:** Before any "should I push?" answer, check intent.
Cutback = no. Always. Even if athlete feels great.
Peak = yes, but with precision on target sessions.
Taper = protect, don't add.

---

## PART 8: UPDATED COACHING PRINCIPLES FOR SYSTEM PROMPT

Add these to the COACHING PRINCIPLES section:

```
10. EASY PACE — DATA-CONFIRMED PROBLEM, ENFORCE EVERY TIME:
    83% of this athlete's easy runs over 2 years were run at threshold effort (avg 5:06/km @ HR:157).
    Easy = 6:00–6:30/km flat = RPE 3 = fully conversational.
    If Strava shows any easy run faster than 5:50/km → flag it in the next response.
    Reference the data: "Your Strava history shows this is a persistent pattern.
    It's the most important habit to change for ultra success."

11. LONG RUN BASE — REBUILD WITH CARE:
    After a 12-month gap in runs >16km, the long run base starts at ~13–16km.
    Do not project marathon-block fitness onto current capability.
    Progression: max +2km per non-cutback week. Protect it.

12. COURSE SECTIONS — TRACK AND FLAG:
    All 4 B2M legs must be run before race day. Check completion status.
    Proactively flag overdue sections: "You're in BUILD and Leg 2 hasn't been run.
    Rose Bay to Milson is 20km with 360m — deceptively hard. Schedule it soon."

13. ALL-RUN DATA — COACH FROM IT:
    Strava data now available for all run types.
    Easy run too fast → flag it. Interval quality below target → note it.
    HR elevated on easy run → flag potential fatigue. Don't just confirm. Coach.

14. WEEK INTENT — ALWAYS CHECK FIRST:
    Cutback week → no increase, regardless of how athlete feels.
    "That's a cutback week. Don't chase volume. Arrive at the next build week fresh."

15. FUELLING IS A DISCIPLINE — BUILD THE HABIT NOW:
    Every long run 16km+: "What are you eating on this? Fuel every 30–40 min from km 10."
    From BUILD phase: name specific gels, plan the 40km drop bag content, train the gut.
    At 9 hours, bonking is a DNF. No exceptions to the fuelling rule.
```

---

## PART 9: SCHEMA CHANGES SUMMARY

| Field | Location | Type | Purpose |
|---|---|---|---|
| `intent` | week object | string | Load decision reference |
| `coach_memory` | plan object | object | Persistent coach notes |
| `football_rpe` | session completion | number | Football intensity signal |
| `check_in` | week object | object | Sleep + stress signal |
| `course_legs_completed` | plan object | array | B2M leg completion tracking |

### course_legs_completed schema
```javascript
course_legs_completed: [
  { leg: 1, date: "2026-05-11", distance_km: 19, notes: "Bondi to Rose Bay" },
]
```

---

## PART 10: MOBILE SAVE BUTTON BUG

**Bug:** Save button in session edit sheet not visible on mobile. Visible on laptop.
**Likely cause:** Button is below viewport fold on small screens.
**Fix:** Apply `position: sticky; bottom: 0; background: [bg color]; padding-bottom: env(safe-area-inset-bottom)` to the action buttons container in the sheet. Pins Save/Cancel to bottom of sheet on all screen sizes.

Always apply this fix when modifying the session edit sheet component.

---

## Rules
- Always read alongside `b2mu-coach-context` when working on coach improvements
- Athlete profile and course knowledge = FIXED — never make them dynamic
- Dynamic context sections = rebuilt on EVERY API call — never cache
- Coach memory requires user approval before writing — never auto-update silently
- Football RPE and weekly check-in = optional — coach degrades gracefully if missing
- All-run Strava data: last 5 completed runs of any type, pace + HR where available
- The 83% easy pace failure rate is from real data — coach should reference this specifically
