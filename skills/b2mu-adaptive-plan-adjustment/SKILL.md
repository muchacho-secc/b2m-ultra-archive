---
name: b2mu-adaptive-plan-adjustment
description: "Adjusts the B2MU training plan dynamically based on missed sessions, fatigue, travel, and changing constraints. Focuses on short-term (1–4 week) adaptation while protecting long-run progression and race-day readiness. All adjustments flow through the mutation workflow."
---

# B2MU — Adaptive Plan Adjustment

When the user's situation changes or a plan adjustment is needed:

## 1. Assess recent context first
Before proposing anything, understand what has actually happened:

- What sessions were completed in the last 1–4 weeks?
- What was missed, skipped, or modified?
- What did the user report? (fatigue, soreness, motivation, illness, travel)
- What is coming up in the next 1–4 weeks that could affect training?
- Is the user mid-week or at the start of a new week?

Do not propose adjustments based on assumptions. Ask if context is missing.

## 2. Identify the issue clearly
Name the specific problem before proposing a solution:

| Situation | Impact | Response type |
|-----------|--------|--------------|
| Missed long run | Loss of key weekly stimulus | Reschedule or absorb depending on timing |
| Missed easy run | Minor volume loss | Usually absorb — do not chase it |
| Fatigue / soreness | Recovery deficit | Reduce upcoming load; do not add |
| Illness (2+ days) | Significant disruption | Treat like cutback week; ease back in |
| Travel (no running) | Volume gap | Absorb if ≤5 days; adjust upcoming week if longer |
| Consecutive missed sessions | Risk of detraining | Reassess next 2 weeks; adjust progression |
| Upcoming busy period | Constrained availability | Pre-emptively restructure affected weeks |

## 3. Apply the right adjustment principle

**Never chase missed sessions** — do not add extra km to "make up" for a missed run. This increases injury risk with no training benefit.

**Never increase load after a miss** — if a long run was missed, the next long run should be the same distance (or less), not longer.

**Absorb minor misses** — a missed easy run with no other issues: simply move on. Do not restructure the plan.

**Protect the long run** — it is the most important session of the week. If one session must be dropped due to fatigue, drop the easy run, not the long run.

**Protect recovery** — rest days and cutback weeks are not optional. If the user is fatigued, the answer is less, not more.

**Honour fixed anchors** — football sessions (Tue/Thu training, Sat match) are never touched, even during adaptation.

## 4. Generate adjustment options
For significant adjustments, provide 2–3 options where possible. Do not force a single outcome:

```
Option A (conservative): Drop next week's easy run, hold long run at 18km
Option B (moderate): Reduce long run to 16km, keep easy run
Option C (aggressive): Proceed as planned — the miss was isolated
```

Label each option with its tradeoff. Let the user choose. The coach recommends one, but the user decides.

## 5. Focus adjustments on the right window
- **This week / next week:** direct session changes (reschedule, reduce, drop)
- **2–4 weeks out:** volume or progression rate changes
- **Beyond 4 weeks:** do not adjust unless disruption is very significant (e.g. 2-week illness)

Avoid cascading adjustments that ripple through the entire plan from a single missed session.

## 6. Maintain long-term progression
Every short-term adjustment must be checked against the long-term trajectory:

- Is the long run still on track to reach 32–36km by PEAK phase?
- Is overall weekly volume still trending upward (within constraints)?
- Is the taper still starting by 3 Oct 2026?

If a short-term adjustment threatens these, flag it explicitly and suggest a recovery path.

## 7. Known disruption windows
Always account for these when adjusting:

| Period | Impact |
|--------|--------|
| Football season (until 15 Aug 2026) | Weekly km capped ~23–28km; Tue/Thu/Sat fixed |
| England travel 17–22 Jun 2026 | ~5 days of little/no training; absorb or restructure surrounding week |
| Football season end (15 Aug 2026) | Volume can increase; remove football anchors; restructure week |
| Taper window (from 3 Oct 2026) | Do not increase load; any adjustment must reduce, not add |

## 8. Prepare the mutation proposal
Do not modify the plan directly. Convert the recommended adjustment into a mutation proposal following the coach mutation system:

```json
{
  "summary": "One sentence description of the adjustment",
  "mutations": [
    {
      "action": "update_session",
      "description": "Human readable description",
      "details": "Specific change (e.g. Long Run Sun Apr 20: 20km → 18km)"
    }
  ]
}
```

Classify the mutation:
- **Minor:** small volume changes (<10%), sessions beyond 4 weeks, note updates
- **Major:** changes within 4 weeks, long run adjustments, structural week changes → always requires user approval

## 9. Explain the reasoning clearly
After any proposal, explain in plain coach language:
- What happened (the issue)
- What the adjustment does
- Why this approach (not another)
- What the expected impact is on the next 2–4 weeks
- Whether long-term race readiness is affected

## Rules
- Never apply adjustments without going through the mutation workflow
- Never increase load after a missed session
- Never touch football anchors during football season
- Never chase missed sessions — absorb and move forward
- Always protect the long run over the easy run
- Always protect recovery over volume
- Keep the primary goal in frame: finish Bondi to Manly on 24 October 2026

## Output Format
- Situation Summary (what happened, what's the impact)
- Identified Issue (specific, named)
- Adjustment Options (2–3 where appropriate, with tradeoffs)
- Recommended Approach (with reasoning)
- Impact on Next 2–4 Weeks
- Long-Term Trajectory Check (is race readiness still intact?)
- Mutation Proposal (JSON, ready for approval flow)