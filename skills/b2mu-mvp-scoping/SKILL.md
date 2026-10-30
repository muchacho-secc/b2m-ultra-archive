---
name: b2mu-mvp-scoping
description: "Defines the minimum viable version of the B2MU coaching app that delivers a complete, usable end-to-end experience. Prioritises AI coaching, adaptive planning, and the mutation workflow while deferring integrations and non-essential features."
---

# B2MU — MVP Scoping

When defining scope for a feature, system, or app in the B2MU coaching project:

## 1. Identify the core user journey
- The single most important end-to-end flow is: open app → see today's session → check the week → talk to coach → approve a plan change
- Every feature included in MVP must serve this journey
- If a feature does not directly support this journey, it is deferred

## 2. Define the MVP boundary
Include only what is required to make the core journey fully functional in real conditions — not a prototype, not a demo.

**Included in MVP:**
- Dashboard: race countdown, readiness note, this week's sessions, pending suggestion
- Plan tab: week navigation, session cards, status tracking (planned / done / missed / skipped)
- Coach tab: AI chat (Anthropic API), mutation proposals surfaced as approval cards
- Progress tab: long run progression chart, weekly volume chart, milestones list
- Mutation approval flow: propose → approve / reject → toast confirmation
- Fixed anchor enforcement: football sessions marked fixed, never overrideable

**Excluded from MVP (defer to Phase 2+):**
- Supabase persistence (Phase 1 uses local state or hardcoded data)
- Strava or WHOOP integration
- Mutation history and undo
- Coach-generated multi-week plan extensions
- Pace/effort tracking per session
- Push notifications or Telegram alerts
- PWA / home screen install

## 3. Prioritise core systems
Ensure these four systems all work end-to-end in MVP — not partially:

1. **Training plan** — sessions exist, have status, can be updated
2. **AI coach** — sends messages, receives structured mutation proposals
3. **Mutation workflow** — proposals surface, user approves or rejects, plan reflects change
4. **Progress tracking** — charts render real data, milestones are accurate

If any of these four are incomplete, the MVP is not done.

## 4. Simplify deliberately
- Phase 1 plan data can be hardcoded or local state — no database required
- Coach context can be injected as a static system prompt — no dynamic data fetching required
- Progress charts use the same hardcoded data as the plan — no separate data layer needed
- Approval flow stores state in React — no persistence required

Document every simplification explicitly so Phase 2 knows what to replace.

## 5. Validate scope before building
Before writing any code, confirm:
- The core journey works end-to-end with the defined feature set
- No included feature requires a Phase 2 dependency to function
- No excluded feature is actually required for the core journey

## Rules
- Do not expand scope based on "it would be nice to have"
- Do not include features that depend on Phase 2 infrastructure
- Do not build placeholder or mocked interactions — if it's in MVP, it must work
- The coach and mutation workflow must both be functional — they are not optional
- Every simplification must be documented so it can be properly built in Phase 2

## Output Format
- Core User Journey (step by step)
- MVP Feature List (included)
- Deferred Features (Phase 2+) with reason for deferral
- Simplifications Made (and what replaces them in Phase 2)
- System Completeness Check (all 4 core systems accounted for)
- Rationale for Scope Decisions