---
name: b2mu-product-planning
description: "Designs the full product direction for the Bondi to Manly Ultra coaching app (B2MU). Ensures a usable Phase 1 and scalable long-term vision. Treats AI coaching, adaptive planning, and the mutation workflow as first-class product systems."
---

# B2MU — Product Planning

When asked to build, improve, or extend a feature, system, or app for the B2MU coaching app:

## 1. Understand the product goal
- Identify the primary objective of the app
- Identify what makes it unique: AI coaching that proposes, the user approves, the plan persists
- Ground every decision in the core question the user asks daily: "What should I do today, and am I on track for race day?"

## 2. Define the core user journey
- Describe the end-to-end experience the user must be able to complete
- Ensure it reflects core value, not just a feature list
- The journey runs: open app → see today → check plan → talk to coach → approve changes → track progress

## 3. Design across phases (not just MVP)
Define all three phases before committing to Phase 1 scope:

**Phase 1 — Fully usable product**
- Static plan with real session data
- Dashboard: race countdown, readiness, this week
- Plan tab: week navigation, session status tracking
- Coach tab: AI chat via Anthropic API, mutation proposals, approval flow
- Progress tab: long run chart, weekly volume chart, milestones

**Phase 2 — Persistence and adaptation**
- Supabase data layer (plan stored server-side)
- Session completion persisted across sessions
- Mutation history with lightweight undo
- Adaptive plan adjustment engine (missed sessions, fatigue, travel)
- Coach-generated 4-week plan extensions

**Phase 3 — Integrations and intelligence**
- Strava auto-import for completed runs
- WHOOP / Garmin HRV and recovery data
- Pace and effort tracking per session
- Race-day readiness score (rolling)
- Weekly summary notification

Ensure each phase builds logically on the previous. Ensure Phase 3 does not require re-architecting Phase 1 systems.

## 4. Identify key product systems
Break the product into core systems and define responsibilities for each:

| System | Responsibility |
|--------|---------------|
| Training Plan | Weekly structure, sessions, fixed anchors, phase labels, volume targets |
| AI Coach | Conversational responses, structured mutation proposals, context injection |
| Mutation Workflow | Propose → approve → apply; classification (minor/major); undo support |
| Progress Tracking | Long run progression, weekly volume, completion rate, milestones |
| Frontend (UI) | Tab navigation, session interaction, approval cards, charts |

Treat the AI coach and mutation workflow as first-class systems — not secondary features.

## 5. Evaluate technical approach
Prioritise free/open-source solutions and mobile-first compatibility:

| Layer | Technology | Reason |
|-------|-----------|--------|
| Frontend | React + Recharts | Single App.jsx, mobile-first, existing pattern |
| AI | Anthropic API (claude-sonnet) | Conversational + structured JSON output |
| Database | Supabase | Free tier, RLS, existing pattern |
| Hosting | Vercel + GitHub | Free, existing pattern |
| Integrations (Phase 3) | Strava API, WHOOP API | Free tiers available |

Highlight tradeoffs: simplicity vs scalability, static data vs live persistence.

## 6. Identify risks and constraints
**Hard constraints (never override):**
- Football: Tuesday training, Thursday training, Saturday match — fixed, cannot be moved
- Football season ends 15 August 2026
- England travel 17–22 June 2026 — little/no training
- Race date fixed: 24 October 2026
- Weekly run volume capped ~23–28km during football season

**Product risks:**
- Coach hallucinating plan details — mitigate by injecting full plan context on every call
- Silent plan mutations — mitigate with mandatory approval flow for all major changes
- Over-engineering Phase 1 — mitigate by locking MVP scope before coding

**Technical risks:**
- Anthropic API latency in chat — show loading state immediately, stream if possible
- Schema too rigid for future session types — use flexible subtype text fields, not enums

## 7. Validate completeness
Before any implementation begins, confirm:
- Phase 1 delivers a real, usable product end-to-end (not a mockup)
- The coaching system and mutation workflow are both functional in Phase 1
- Future phases do not require re-architecting core systems

## Rules
- Do not write implementation code during planning
- Do not jump into low-level detail before the full picture is clear
- Always think long-term, not just MVP
- Treat the coaching system and mutation workflow as first-class product systems
- Prioritise clarity and structure over completeness

## Output Format
1. Product Summary
2. Core User Journey
3. Phase Breakdown (Phase 1 / Phase 2 / Phase 3)
4. Key Systems & Responsibilities
5. Recommended Tech Approach (with reasoning)
6. Risks & Constraints
7. Final Recommendation (what to build first and why)