---
name: b2mu-ui-component-design
description: "Designs the frontend structure of the B2MU Ultra Coach app. Mobile-first React app, 4 tabs: Dashboard, Plan, Coach, Progress. Dark theme. Single App.jsx pattern. Defines design tokens, component responsibilities, data flow, and the mutation approval UI."
---

# B2MU — UI Component Design

When designing the UI or frontend structure for the B2MU coaching app:

## 1. Core design principles
- **Session first** — today's session visible within 1 second of opening
- **Mobile first** — max-width 480px, designed for phone
- **Coach-like** — direct, no clutter; the UI reflects the coach's voice
- **Single file** — all components in one `App.jsx`, no routing library
- **Approve before apply** — plan changes never happen without user confirmation

## 2. Design tokens

```javascript
const C = {
  bg:           "#070707",
  surface:      "#0d0d0d",
  card:         "#141414",
  cardHover:    "#1a1a1a",
  dim:          "#1c1c1c",
  border:       "#1e1e1e",
  borderBright: "#2e2e2e",

  // Primary brand
  accent:       "#f05a28",
  accentFade:   "rgba(240,90,40,0.14)",
  accentBright: "#ff6b38",

  // Semantic
  green:        "#22c55e",   greenFade:  "rgba(34,197,94,0.14)",
  amber:        "#f59e0b",   amberFade:  "rgba(245,158,11,0.14)",
  blue:         "#60a5fa",   blueFade:   "rgba(96,165,250,0.14)",
  purple:       "#c084fc",   purpleFade: "rgba(192,132,252,0.14)",
  red:          "#f87171",   redFade:    "rgba(248,113,113,0.14)",

  // Text
  text:         "#f0f0f0",
  textDim:      "#999",
  muted:        "#444",
};

const FONTS = {
  display: "'Barlow Condensed', sans-serif",  // headers, labels, tab bar, stat values
  body:    "'DM Sans', sans-serif",           // all readable text, coach messages
  mono:    "'JetBrains Mono', monospace",     // km values, pace, data points
};

const FONT_IMPORT = `@import url('https://fonts.googleapis.com/css2?family=Barlow+Condensed:wght@600;700;900&family=DM+Sans:wght@300;400;500;600&family=JetBrains+Mono:wght@400;500&display=swap');`;
```

## 3. Session and status type maps

```javascript
const SESSION = {
  run:      { color: C.accent,  fade: C.accentFade,  label: "RUN",   icon: "⟳" },
  football: { color: C.blue,    fade: C.blueFade,    label: "FOOTY", icon: "◈" },
  gym:      { color: C.purple,  fade: C.purpleFade,  label: "GYM",   icon: "◉" },
  rest:     { color: C.muted,   fade: "transparent", label: "REST",  icon: "–" },
};

const STATUS = {
  completed: { dot: C.green },
  planned:   { dot: C.muted },
  missed:    { dot: C.red },
  skipped:   { dot: C.muted },
};
```

## 4. Navigation

Bottom tab bar, always visible, 4 tabs:
```
[ ◈ HOME ]  [ ◻ PLAN ]  [ ⟳ COACH ]  [ ▲ STATS ]
```
- Active: accent colour + 16px underline bar
- Font: Barlow Condensed 700, 9px, `letterSpacing: "0.1em"`
- Background: `C.surface`, `borderTop: 1px solid C.border`

## 5. Shared components

**`pill(text, color, bg)`** — used throughout for status labels
```javascript
// fontSize 10, Barlow Condensed 700, padding "2px 7px", borderRadius 3
// Examples: FIXED (blue), ✓ DONE (green), MISSED (red), BASE PHASE (accent)
```

**`statBox(label, value, sub, accent)`** — reusable stat display block
```javascript
// label: 10px Barlow muted, letterSpacing 0.1em
// value: 26px Barlow 900, coloured by accent param
// sub: 11px DM Sans muted
// background: C.card, border: C.border, borderRadius 8
```

**Custom chart tooltip**
```javascript
// background: C.surface, border: C.borderBright, borderRadius 7
// label: Barlow 10px muted
// value: Barlow 900 16px accent, "Xkm" format
```

## 6. Tab: Dashboard

Purpose: Orient the user — where am I, what's next, is there anything to act on?

**Race Countdown Hero**
- Gradient: `C.accentFade → transparent`
- Ghost number (days) at 120px opacity 0.04 behind layout
- `daysLeft` in 52px Barlow 900
- Pills: `[BASE PHASE]` `[WEEK 8]` `[⚽ SEASON ACTIVE]`

**Coach Readiness Card**
- Status options: `ON TRACK ▲` (amber) / `AT RISK ⚠` (red) / `BEHIND ↓` (red)
- 2–3 sentence assessment, DM Sans 13px

**Stat Row** — 3 `statBox` side by side
- WEEK KM (`done / target`), LONG RUN (distance + status), DONE (`n / 7 sessions`)

**Suggestion Card** (conditional, amber — only when a pending suggestion exists)
- Header: `COACH SUGGESTION` in amber
- One-sentence change description
- Affected session detail (muted, 11px)
- `✓ APPROVE` (green fill, black text) + `✕ DISMISS` (ghost)
- On approve/dismiss: dismissed from view, toast shown

**This Week Session List**
- Compact rows: day label | status dot | type label | session name + km | tags
- `FIXED` badge (blue) on football sessions
- `DONE` badge (green) on completed
- Today: accent dot below day abbreviation
- Completed rows: `opacity: 0.65`
- Row dividers: `C.dim`

## 7. Tab: Plan

Purpose: Navigate any week, see sessions, manage individual session status.

**Week Navigator**
- `‹` / `›` arrow buttons, centre shows `week.label`
- Current week: accent text + `· NOW` suffix
- Cutback weeks: amber `CUTBACK` label
- Disabled arrows: `C.dim` background

**Volume Bar**
- `done_km / target_km` right-aligned
- 4px track (`C.dim`), accent fill, `width` animated `0.4s ease`

**Session Cards** (expandable on tap)
- Collapsed: day | dot | type | name + km | pills
- Border: accent tint on today, `C.borderBright` when selected
- Expanded:
  - Note in italics if present
  - Planned non-fixed: `MARK DONE` (green) / `MARK MISSED` (red) / `SKIP` (ghost)
  - Fixed sessions: blue text "Football commitment — fixed in schedule"
  - Completed: "Session complete ✓" in green

**Phase Overview** (bottom of tab)
- 4 rows: BASE / BUILD / PEAK / TAPER
- Active: accent dot + label; inactive: `C.muted`

## 8. Tab: Coach

Purpose: Talk to the coach — ask questions, report issues, get plan adjustments approved.

**Message Bubbles**
- User: right-aligned, `C.accentFade` bg, accent border, `borderRadius: "14px 14px 4px 14px"`
- Assistant: left-aligned, `C.card` bg, `C.border`, `borderRadius: "4px 14px 14px 14px"`
- `COACH` label (accent, 9px, Barlow 700) above first assistant message

**Loading indicator**
- 3 dots, 5px circles, accent colour
- `pulse` animation: opacity `0.3 → 1 → 0.3`, scale `0.8 → 1 → 0.8`
- Delays: `0s, 0.2s, 0.4s`

**Mutation Approval Card** (amber, appears below assistant message when mutations present)
- Header: `PROPOSED CHANGES — AWAITING APPROVAL`
- Per-mutation rows: `＋` / `−` / `↻` prefix (amber) + description + details
- `✓ APPROVE CHANGES` (green fill) + `✕ REJECT` (ghost)
- Classification displayed: MINOR (auto-approvable) or MAJOR (always requires user approval)

**Mutation JSON format the coach must produce:**
```json
{
  "summary": "One sentence summary of change",
  "mutations": [
    {
      "action": "update_session | create_session | delete_session",
      "description": "Human readable description",
      "details": "Specific change detail (e.g. 18km → 20km)"
    }
  ]
}
```

**Quick Prompt Chips** (horizontal scroll, `scrollbar-width: none`)
- Tap sets input, does not auto-send
- Defaults: "I missed my long run this week", "Build my next 4 weeks", "I'm away the weekend of May 17", "Reduce next week slightly"

**Input Row**
- Text input: `C.card`, `C.borderBright`, 10px radius
- Send button: accent when active, `C.dim` when disabled, `↑` icon
- `Enter` triggers send

**Coach system prompt must always include:**
- Race: Bondi to Manly Ultra, 24 Oct 2026, and days remaining
- Fixed commitments: Tue/Thu football training, Sat match
- Known travel/disruption windows
- Current phase and week label
- Recent long run progression (last 6 weeks)
- Weekly volume constraints during football season
- Product philosophy: "The coach recommends. The user approves. The plan persists."

## 9. Tab: Progress

Purpose: Show training trends — long run progression, weekly volume, consistency.

**Headline Stat Row** — 3 `statBox`
- COMPLETION (%, green), TOTAL RUNS (count, accent), PEAK LR (max long run km, white)

**Long Run Line Chart** (`LineChart`, Recharts)
- Accent line, 2.5px stroke
- Actual dots: filled accent; projected dots: `C.accentFade` fill + accent stroke
- Y-axis domain `[8, 24]`, custom tooltip
- Projected label below chart: small pill `PROJECTED` in accent

**Weekly KM Bar Chart** (`BarChart`, Recharts)
- Completed weeks: accent fill
- Current partial week: `C.accentFade` fill + accent stroke, `radius: [4,4,0,0]`

**Milestone List**
- Colour dot | label | date right-aligned
- Colours: accent (run), blue (football season end), purple (peak), green (race day)

## 10. Header
```
ULTRA COACH              [ PHASE ]
B2M · {daysLeft} DAYS   [  BASE ]
```
- Left: `ULTRA` (white) + `COACH` (accent), Barlow 900 18px
- Sub: JetBrains Mono 10px muted
- Right: phase badge, `C.accentFade` bg, accent border

## 11. Toast notifications
- Fixed, top 70px, centred, `translateX(-50%)`
- Green fill (black text) for approvals; `C.muted` text for dismissals
- Barlow 700 13px, 20px radius
- Auto-dismiss after 2500ms

## 12. Global CSS
```css
* { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
body { background: #070707; margin: 0; }
::-webkit-scrollbar { width: 4px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: #1e1e1e; border-radius: 2px; }
@keyframes pulse {
  0%, 100% { opacity: 0.3; transform: scale(0.8); }
  50%       { opacity: 1;   transform: scale(1); }
}
input::placeholder { color: #444; }
```

## Rules
- No routing library — tabs only, everything in `App.jsx`
- No external component libraries — inline styles + Recharts only
- Dark theme only — no light mode
- Max-width 480px, centred, `min-height: 100vh`
- All km values: `{n}km` (no space, lowercase)
- All section labels: Barlow Condensed 700, uppercase, `letterSpacing: "0.08–0.15em"`
- Fixed sessions never show action buttons (mark done / missed / skip)
- Tab content: `flex: 1, overflowY: auto, paddingTop: 16px`
- Bottom tab bar: `flexShrink: 0` — always anchored to bottom

## Output Format
- Navigation Structure
- Screen/Tab List (with purpose)
- Component Hierarchy per tab
- Key Component Specs (props, layout, behaviour)
- Data Flow Overview
- Mutation Approval UI spec
- Notes on real-time state behaviour