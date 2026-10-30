---
name: b2mu-training-plan-generation
description: "Generates and extends the B2MU training plan for Bondi to Manly Ultra (24 Oct 2026). Builds around fixed football anchors, progressive long run load, recovery weeks, and race-day taper. Sessions defined with pace ranges, effort ranges, and terrain notes."
---

# B2MU — Training Plan Generation

When generating or extending the training plan for Bondi to Manly Ultra (24 October 2026):

## 1. Understand the training objective
- The goal is to finish the ultra — not to achieve a time target
- Prioritise: completing the distance safely, arriving healthy, building trail confidence
- Sustainable progression beats aggressive load in every decision

## 2. Establish fixed weekly anchors (non-negotiable)
Before placing any run sessions, lock these anchors:

| Day | Fixed commitment | Rule |
|-----|-----------------|------|
| Tuesday | Football training | No run session; cross-training credit only |
| Thursday | Football training | No run session; cross-training credit only |
| Saturday | Football match | No long run; rest or very light recovery only |
| Friday | Pre-match day | No hard run; rest or light 20-min easy jog at most |

Football season ends **15 August 2026**. After this date, remove all football anchors and redistribute training load across 5–6 days.

Build the week around these anchors first. Runs go in the remaining slots (Mon, Wed, Sun — and occasionally Fri light).

## 3. Build the weekly structure
Standard week during football season:
```
MON — Easy Run (aerobic base)
TUE — Football Training (fixed)
WED — Gym (strength: lower or upper, alternating)
THU — Football Training (fixed)
FRI — Rest
SAT — Football Match (fixed)
SUN — Long Run (key session of the week)
```

Adjust this structure for cutback weeks and travel disruptions — but maintain the football anchors.

## 4. Apply core training principles

**Progressive overload:**
- Increase long run distance by no more than 2km per week
- Increase weekly run volume by no more than 10% week-on-week
- Do not increase both long run distance and weekly volume in the same week

**Cutback weeks:**
- Include one cutback week every 3–4 weeks
- Reduce long run by 20–25% on cutback weeks
- Reduce total weekly volume by ~20%
- Label these weeks `CUTBACK` phase

**Long run progression target:**
- Current (Apr 2026): ~16–18km
- By end of BASE (May 2026): ~24–26km
- By end of BUILD (Jul 2026): ~30–32km
- PEAK (Aug–Sep 2026): 32–36km, back-to-back long runs
- TAPER (Oct 1–24): reduce to 20km → 12km → race day

**Taper:**
- Begin 3 weeks before race day (from ~3 Oct 2026)
- Week 1: reduce long run by 25%, reduce volume 20%
- Week 2: reduce long run by 40%, reduce volume 35%
- Race week: short shakeout runs only (20–30 min easy), no long run

## 5. Support multiple session types
Include all four session types with correct load accounting:

| Type | Training load | Notes |
|------|--------------|-------|
| Run | Primary — counts toward weekly km | Must define distance + effort |
| Football | Moderate load — cross-training credit | Always fixed; label training vs match |
| Gym | Supplementary | Alternate lower / upper / full body |
| Rest | Recovery | Mandatory on Fri pre-match; use liberally in cutback weeks |

## 6. Define run sessions precisely
Never use only a generic label. Always specify:

**Distance:** exact km (e.g. `8km`, `20km`)

**Effort range (RPE 1–10):**
- Easy: RPE 4–5 (conversational pace, nose breathing possible)
- Moderate: RPE 6–7 (can speak in short sentences)
- Hard: RPE 8–9 (uncomfortable, not sustainable beyond 20–30 min)

**Pace range (min/km) — based on current easy pace ~5:45–6:00/km:**
- Easy: 5:45–6:15/km
- Moderate: 5:10–5:30/km
- Long run: 5:50–6:20/km (stay easy, especially in BASE)

**Time of day:** morning / afternoon / evening only — never a specific time

## 7. Support structured run blocks
For sessions with multiple efforts, define sub-blocks:

```
Example: Progression Run 10km
  Block 1: 4km easy warm-up — RPE 4–5, 6:00–6:20/km
  Block 2: 4km moderate — RPE 6–7, 5:15–5:30/km
  Block 3: 2km easy cooldown — RPE 4–5, 6:00–6:20/km
```

Use sub-blocks for: tempo runs, progression runs, interval sessions (BUILD phase+).
Keep long runs and easy runs as single blocks.

## 8. Consider terrain specificity
The Bondi to Manly route is coastal trail with significant elevation. Annotate sessions accordingly:

- Long runs from BUILD phase onwards: prefer coastal trails or hills where available
- Note when a run should be on trails vs road
- Include elevation notes for long runs over 20km (e.g. "include 200m+ elevation gain if possible")
- In PEAK phase: include back-to-back long runs to simulate ultra fatigue

## 9. Phase overview

| Phase | Period | Long run range | Weekly km | Focus |
|-------|--------|---------------|-----------|-------|
| BASE | Mar–May 2026 | 14–26km | 20–28km | Aerobic base, consistency |
| BUILD | Jun–Jul 2026 | 26–32km | 28–40km | Volume increase, trail specificity, back-to-backs begin |
| PEAK | Aug–Sep 2026 | 32–36km | 40–50km | Race simulation, back-to-back long runs, strength |
| TAPER | Oct 1–24 2026 | 20km → 12km | Reducing | Freshness, confidence, sharpening |
| CUTBACK | Throughout | –20–25% | –20% | Recovery, consolidation |

## 10. Validate the plan
Before outputting any plan:
- Confirm no run session conflicts with a football anchor
- Confirm no week increases both long run distance AND total volume simultaneously
- Confirm cutback weeks are placed every 3–4 weeks
- Confirm taper begins no later than 3 Oct 2026
- Confirm long run is the highest-quality session of each week

## Rules
- Do not optimise for race time — finishing is the goal
- Do not place run sessions on Tuesday, Thursday, or Saturday during football season
- Do not increase long run by more than 2km per week
- Do not increase weekly volume by more than 10% per week
- Never skip the taper
- Keep session instructions specific and practical — no generic labels only

## Output Format
- Weekly Plan Structure (table: day / type / session / distance / effort)
- Session Details (type, distance, pace range, effort range, terrain notes)
- Fixed Anchors Applied (confirmed)
- Training Logic Explanation (why this structure, this week)
- Notes on Load, Recovery, and Terrain
- Next 4 weeks if generating a block (not just 1 week)