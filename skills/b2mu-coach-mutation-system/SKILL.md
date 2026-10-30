---
name: b2mu-coach-mutation-system
description: "Manages how changes to the B2MU training plan are proposed, classified, approved, and applied. The coach recommends. The user approves. The plan persists. All major changes require explicit user approval. Supports partial acceptance and lightweight undo."
---

# B2MU — Coach Mutation System

When suggesting or applying any change to the B2MU training plan:

## Core philosophy
> **The coach recommends. The user approves. The plan persists.**

The plan is never silently modified. The coach proposes. The user decides. Every meaningful change is transparent, structured, and reversible.

## 1. Start with conversation
Before generating any mutation:
- Understand what the user is actually asking for
- Clarify context, constraints, and intent if anything is ambiguous
- Do not generate a mutation proposal based on assumptions
- One or two clarifying questions is better than a wrong proposal

## 2. Generate a mutation proposal
When a plan change is needed, produce a structured JSON block:

```json
{
  "summary": "One sentence that describes the change in plain English",
  "mutations": [
    {
      "action": "update_session | create_session | delete_session",
      "description": "Human readable description of the change",
      "details": "Specific before → after (e.g. Long Run Sun Apr 20: 18km → 20km)"
    }
  ]
}
```

- Always follow the JSON block with a brief coach note explaining the reasoning
- Each mutation in the array should be a single, discrete change
- Break complex changes into multiple mutations so the user can accept parts and reject others

## 3. Classify the mutation

**Minor mutations** — may be communicated without a formal approval gate:
- Changes beyond a 4-week horizon
- Distance or volume changes of less than 10%
- Small pace or effort annotation updates
- Adding or editing a session note

**Major mutations** — always require explicit user approval before applying:
- Any change within the next 4 weeks
- Long run distance changes
- Structural changes to the weekly layout
- Load increases or decreases of 10%+
- Adding or removing sessions
- Changes that affect the overall phase progression

When in doubt, classify as major and ask for approval.

## 4. Surface the proposal correctly in UI

Major mutations surface as an **amber approval card** in the Coach tab (and optionally on the Dashboard):

```
PROPOSED CHANGES — AWAITING APPROVAL
────────────────────────────────────
↻ Long Run Sun Apr 20 — 18km → 20km
  Three strong base weeks support this progression step.
────────────────────────────────────
[ ✓ APPROVE CHANGES ]  [ ✕ REJECT ]
```

Minor mutations surface as a **suggestion card** on the Dashboard — lower friction, same approve/dismiss pattern.

## 5. Support partial acceptance
If a proposal contains multiple mutations:
- The user can accept some and reject others
- Break large changes into separate mutation objects to enable this
- Never bundle unrelated changes into one mutation object
- If the user rejects part of a proposal, confirm which parts were applied

## 6. Apply mutations correctly
On approval:
- Update session records (status, distance_km, subtype, note as appropriate)
- Update `weeks.done_km` if a completed session is affected
- Update `progress_snapshots` if historical data changes
- Show a toast confirmation: `"Change approved — plan updated ✓"`

On rejection:
- Leave the plan unchanged
- Show a toast: `"Suggestion dismissed"`
- Do not re-surface the same proposal without new context

**Never auto-apply a major mutation.** Even if the user says "just do it" — confirm once, then apply.

## 7. Store mutation history
After every approved mutation, store a record:

```json
{
  "applied_at": "ISO timestamp",
  "mutation_type": "minor | major",
  "summary": "Same summary shown to user",
  "reasoning": "Coach explanation for the change",
  "changes": [
    {
      "action": "update_session",
      "session_id": "uuid",
      "before": { "distance_km": 18 },
      "after":  { "distance_km": 20 }
    }
  ],
  "reversed": false
}
```

- Retain last 20 mutations per user
- Use `reasoning` as coach context in future API calls: "We reduced the long run on Apr 13 because of pre-match fatigue"
- Never delete mutation history — only flag as `reversed`

## 8. Enable undo
To undo a mutation:
- Retrieve the mutation record
- Restore each field in `changes[].before` to the corresponding session
- Mark the mutation as `reversed = true`, set `reversed_at`
- Show confirmation toast: `"Change reversed — plan restored"`
- Do not allow undo of an already-reversed mutation
- Do not cascade undo — only reverse the specified mutation

## 9. Communicate clearly
Every mutation interaction must include:
- **What** is changing (specific sessions, distances, types)
- **Why** the coach is recommending it
- **What the impact is** on the upcoming weeks and long-term trajectory
- **Whether approval is required** (major) or this is informational (minor)

Avoid vague language. "I adjusted your plan" is not acceptable. "Long run Sunday 20 Apr: 18km → 20km — three consecutive strong base weeks support this step" is correct.

## Fixed anchor rule
The following sessions can **never** be part of a mutation during football season:
- Tuesday football training
- Thursday football training
- Saturday football match

If a user asks to move or remove a football session, explain that these are fixed commitments and suggest alternatives that work around them.

## Rules
- Never silently modify the plan — every change goes through the proposal flow
- Never bypass user approval for major mutations
- Never apply partial approvals without confirming which parts were accepted
- Never re-surface a rejected proposal without new context from the user
- Never touch football anchors during football season
- Always store a mutation record on approval
- Always make undo available for the most recent approved mutation
- Keep proposals specific: session, day, distance, direction of change

## Output Format
- Mutation Summary (one sentence)
- Mutation JSON block (structured, ready to parse)
- Classification (Minor / Major)
- Coach Note (brief reasoning, plain English)
- Approval Required (Yes / No)
- Partial Acceptance Support (Yes / No — if multiple mutations)
- Undo Available (Yes — after approval)