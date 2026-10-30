---
name: b2mu-coach-context
description: "Defines exactly what context is injected into every B2MU AI coach API call. Covers plan state, current week, recent sessions, mutation history, phase context, hard constraints, and formatting. The coach is only as good as the context it receives."
---

# B2MU — Coach Context

The AI coach has no memory between calls. Every request must include the full context required to respond accurately. This skill defines what that context is, how it is structured, and what must never be omitted.

## Core principle
> A coach who doesn't know what happened last week can't give good advice this week.

Every Anthropic API call for the B2MU coach must inject structured context before the user's message. This context is assembled server-side (or from app state in Phase 1) and prepended to the conversation.

---

## Context block structure

```javascript
function buildCoachContext(state) {
  return `
--- ATHLETE PROFILE ---
Race: Bondi to Manly Ultra
Race Date: 24 October 2026
Days to Race: ${state.daysToRace}
Current Phase: ${state.currentPhase}
Current Week: ${state.currentWeekLabel} (Week ${state.weekNum})

--- HARD CONSTRAINTS ---
Football season active until: 15 August 2026
Fixed sessions: Tuesday training, Thursday training, Saturday match
These sessions CANNOT be moved, replaced, or overridden.
England travel: 17–22 June 2026 (little or no training)
Weekly run volume cap during football season: ~23–28km

--- THIS WEEK ---
Week: ${state.currentWeekLabel}
Target km: ${state.targetKm}km
Done km: ${state.doneKm}km
Sessions:
${state.thisWeekSessions.map(s =>
  `  ${s.day}: ${s.type.toUpperCase()} — ${s.subtype || 'Rest'}${s.distanceKm ? ` (${s.distanceKm}km)` : ''} [${s.status}]${s.isFixed ? ' [FIXED]' : ''}`
).join('\n')}

--- RECENT LONG RUN PROGRESSION (last 6 weeks) ---
${state.longRunHistory.map(w =>
  `  ${w.weekLabel}: ${w.longRunKm ? `${w.longRunKm}km` : 'no long run'}`
).join('\n')}

--- RECENT WEEKLY VOLUME (last 6 weeks) ---
${state.weeklyVolumeHistory.map(w =>
  `  ${w.weekLabel}: ${w.actualKm}km of ${w.targetKm}km target`
).join('\n')}

--- RECENT MUTATIONS (last 3 approved changes) ---
${state.recentMutations.length > 0
  ? state.recentMutations.map(m =>
      `  ${m.appliedAt}: ${m.summary} (${m.mutationType})`
    ).join('\n')
  : '  No recent changes'}

--- UPCOMING KNOWN DISRUPTIONS ---
${state.upcomingDisruptions.length > 0
  ? state.upcomingDisruptions.map(d => `  ${d.date}: ${d.description}`).join('\n')
  : '  None logged'}
`;
}
```

---

## Required context fields

### Athlete profile
| Field | Type | Example |
|-------|------|---------|
| `daysToRace` | integer | `189` |
| `currentPhase` | string | `BASE` / `BUILD` / `PEAK` / `TAPER` / `CUTBACK` |
| `currentWeekLabel` | string | `"Apr 13–19"` |
| `weekNum` | integer | `0` (current), `-1` (last week), `1` (next week) |

### This week sessions
An array of all 7 days, even rest days. Each session must include:
| Field | Type |
|-------|------|
| `day` | `"MON"` through `"SUN"` |
| `type` | `"run"` / `"football"` / `"gym"` / `"rest"` |
| `subtype` | `"Easy Run"` / `"Long Run"` / `"Training"` / `"Match"` etc. |
| `distanceKm` | number or null |
| `status` | `"planned"` / `"completed"` / `"missed"` / `"skipped"` |
| `isFixed` | boolean |
| `note` | string or null |

### Long run history
Last 6 weeks. The coach uses this to assess progression rate and identify if a cutback is due.

### Weekly volume history
Last 6 weeks. The coach uses this to detect consistency, trend, and whether volume is sustainable.

### Recent mutations
Last 3 approved changes. The coach uses this to avoid contradicting recent decisions and to understand why the plan looks the way it does.
- Include: `appliedAt`, `summary`, `mutationType`, `reasoning`
- Omit full `changes` JSON — summary only is sufficient for context

### Upcoming disruptions
Any known future constraints the user has logged:
- Travel dates
- Races or events
- Busy periods
- Football bye weeks

---

## System prompt

The system prompt is fixed and injected on every call. It does not change based on context — context is injected separately into the user message.

```
You are an expert ultra running coach helping a single athlete prepare for the Bondi to Manly Ultra on 24 October 2026.

Your coaching style:
- Direct, specific, and practical — never vague
- Reference actual km numbers, days, and session types in every response
- Short sentences. No filler.
- Coach-like confidence — you have a view, you share it clearly

Your two response modes:

MODE 1 — Conversational (for questions, advice, reassurance):
Respond in plain English. 2–5 sentences for simple questions. Longer only if the user asks for detail. Never use bullet points unless listing sessions in a plan.

MODE 2 — Plan change (when a session, week, or load needs to change):
Respond with a JSON mutation block in this exact format, followed by a brief coach note:

\`\`\`json
{
  "summary": "One sentence description of the change",
  "mutations": [
    {
      "action": "update_session | create_session | delete_session",
      "description": "Human readable description",
      "details": "Specific change e.g. Long Run Sun Apr 20: 18km → 20km"
    }
  ]
}
\`\`\`

Rules you must never break:
- Never move or remove a FIXED session (football Tuesday, Thursday, Saturday)
- Never increase load after a missed session
- Never propose a change that skips the user's approval — always use the JSON format for plan changes
- Never give generic advice — always reference the athlete's actual data from the context provided
- The goal is finishing the ultra, not racing it
```

---

## Context injection point

The context block is injected as a prefix to the **first user message** in each conversation, not as a system message. This ensures it is always present regardless of conversation length.

```javascript
function buildApiMessages(conversationHistory, newUserMessage, contextBlock) {
  const messages = conversationHistory.map(m => ({
    role: m.role,
    content: m.content
  }));

  // Inject context into the new user message
  const enrichedMessage = {
    role: 'user',
    content: `${contextBlock}\n\n--- ATHLETE QUESTION ---\n${newUserMessage}`
  };

  return [...messages, enrichedMessage];
}
```

In Phase 1 (static data), context is assembled from hardcoded app state.
In Phase 2+, context is assembled from Supabase at request time.

---

## What to omit from context

Do not include:
- Full mutation `changes` JSON arrays — too verbose; use summary only
- Session data older than 6 weeks — not relevant to current coaching decisions
- Performance snapshot raw data — summarise as volume history instead
- User personal details beyond training constraints
- Any data not directly relevant to training decisions

---

## Context freshness rules

| Data | How often to refresh |
|------|---------------------|
| This week's sessions | On every coach call — status changes frequently |
| Long run history | On every coach call |
| Weekly volume history | On every coach call |
| Recent mutations | On every coach call |
| Upcoming disruptions | On every coach call |
| Days to race | On every coach call (calculated from today) |

Never cache context between coach calls. Stale context leads to bad coaching advice.

---

## Phase 2+ additions to context

When Supabase is live, add:

```
--- SESSION NOTES (last 3 completed runs) ---
  Sun Apr 13: Long Run 16km — "Felt strong, held easy pace throughout"
  Mon Apr 7: Easy Run 8km — "Heavy legs from Saturday match"
  Sun Apr 6: Long Run 16km — "Good session, strong finish"
```

When Strava is integrated, add:

```
--- STRAVA (last activity) ---
  Sun Apr 13: 16.2km, 1:37:42, avg pace 6:03/km, avg HR 142bpm
```

When WHOOP/Garmin is integrated, add:

```
--- RECOVERY (today) ---
  HRV: 68ms (above baseline)
  Recovery score: 74%
  Sleep: 7h 22m
  Recommendation: Green — full training load appropriate
```

---

## Rules
- Never call the Anthropic API without the full context block
- Never omit the hard constraints section — it prevents the coach from breaking fixed anchors
- Never omit recent mutations — the coach must know what has already been changed and why
- Always inject context into the user message, not the system prompt
- System prompt is fixed — do not modify it per-call
- In Phase 1, assemble context from local app state; in Phase 2+, from Supabase

## Output format
This skill has no standalone output — it defines the input structure for every coach API call. When implementing the coach system, validate that every API call includes all required context fields before sending.