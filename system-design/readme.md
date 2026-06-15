# Routine — Design System

A design system for **Routine**, a personal iPhone app for tracking recurring
habits on a flexible weekly or monthly cadence. _No gamification, no gimmicks —
just utility._ The app answers four questions fast: what have I done today, what
haven't I, how am I tracking this week/month, and when did I last do this.

This system captures Routine's visual language so you can build new screens,
prototypes, marketing pieces, and decks that look and feel like the product.

> **Mood, in five words:** dark · grounded · warm · tactile · quietly precise.
> **Not:** bright, gamified, corporate, clinical, or data-heavy.

---

## Sources

Everything here was derived from the product's own repository and design specs —
not from screenshots alone. If you have access, read them for deeper context:

- **GitHub — [`JustinDFuller/routine`](https://github.com/JustinDFuller/routine)** (private)
  - `VISUAL_DESIGN.md` — design language, flows, interaction behavior (primary reference)
  - `PRODUCT_BRIEF.md` — scope, principles, starter dataset
  - `RoutineApp/RoutineColors.xcassets/` — the exact sRGB color roles (light/dark/high-contrast)
  - `RoutineApp/Components/` — `ProgressRingView`, `RoutineCardView`, `UndoBannerView` (SwiftUI source for the defining components)
  - `RoutineApp/RoutineHistoryView.swift`, `AddEditRoutineView.swift`, `SettingsView.swift`, `TodayDashboardView+Content.swift`
- **Screenshots** — 18 flows × light/dark, plus the three app-icon variants (in `uploads/`, copied to `assets/`).

Explore the repository further to build with higher fidelity — the SwiftUI views
are the source of truth for state logic, ring rules, and copy.

---

## Content fundamentals

Routine's voice is **practical, never motivational**. It sounds like a calm tool,
not a coach.

- **Person & address.** Second person, lightly. "Add your first routine to start
  tracking." "Controls when your weekly routine progress resets." The app talks
  about *your* routines; it never says "we", never cheerleads.
- **Casing.** **Sentence case everywhere** — titles, buttons, menus. "Add routine",
  "Done today", "Week starts on". Avoid ALL-CAPS; the only near-exception is small
  section labels, kept subtle. Section headers on the dashboard are short and
  Title Case as the user named them ("Today Focus", "Monthly Maintenance").
- **Brevity.** Labels are terse and functional: `Today`, `Undo`, `5 per week`,
  `Last done yesterday`, `Available 11:00 PM–3:00 AM`, `No completions yet`.
  Helper text appears only when it earns its place ("This deletes the routine and
  its completion history.").
- **Tone is forgiving, not punitive.** Incomplete items are never framed as
  failures. Completion is quietly satisfying, never celebrated.
- **Words we use:** Today · Done today · Undo · View history · Remove · Rearrange ·
  Available · Target · Weekly / Monthly · Last done…
- **Words we never use:** Streak · Score · Fail · Perfect · Crush your goals ·
  Stay on track — and anything achievement- or urgency-flavored.
- **Numbers & dates.** Counts read `3/5`; over-target shows the real overage
  (`6/5`), never a badge. Relative time is plain: `Today`, `Yesterday`, `3d ago`,
  `Jun 2`, `Never`. Dates spell the month: `Jun 10, 2026`.
- **Emoji:** none. **Unicode:** an en-dash in time ranges (`11:00 PM–3:00 AM`); a
  checkmark only as a visual mark inside the ring, never in prose.

---

## Visual foundations

### Color
A **role-based** system (not a numbered scale), authored dark-first with matching
light values and high-contrast variants. Decorative color is kept low — the
interface should feel *edited, not rainbow-coded*. **Completion is never signalled
by color alone** (ring fill + checkmark + count text always co-signal).

| Role | Light | Dark | Use |
|---|---|---|---|
| Canvas | `#F6F3EC` | `#141412` | App background — a warm base plane, never pure black/white |
| Surface | `#FFFCF5` | `#20201D` | Routine cards, grouped content |
| Surface Elevated | `#FFFFFF` | `#2B2A26` | Sheets, overlays, active/incomplete cards |
| Label Primary | `#24231F` | `#F3F0E8` | Names, high-importance text |
| Label Secondary | `#6D675E` | `#B7B0A4` | Counts, metadata, helper text |
| Accent Complete | `#4F7A34` | `#A7C77D` | Completion & progress — a mature warm green |
| Accent Active | `#2F6472` | `#8EA7B8` | Selection, focus, nav — a cool teal, used sparingly |
| Accent Destructive | `#C9342D` | `#FF6B6B` | Delete / remove |
| Divider | `#D8D2C7` | `#3A3832` | Hairlines — never high-contrast rules |

Contrast comes from **value shifts, fill state, and surface layering**, not from
saturation. Surfaces follow Apple's layered dark model: dim canvas → soft card →
brighter elevated sheet. Exact tints (card washes, pill fills, ring track) are
encoded as derived tokens in `tokens/colors.css`.

### Typography
**San Francisco via the system stack** + Dynamic Type — no custom typeface.
Sentence case, short and functional; no heavy tracking or oversized numerals.
Roles map to iOS text styles: Large Title / Title (the `Today` header, 28–34),
Title 3 (history name, empty states), Headline 17/600 (routine names, history
section titles), Body 17, Subheadline 15/600 (section headers, date line),
Footnote 13, Caption 12 (metadata pills, last-done, weekday labels).

### Shape, spacing & layout
Soft and consistent. Cards and surfaces are continuous rounded rectangles (radius
**16**); sheets/banner **18**; rows **14**; controls **12**; metadata as
**capsules**. Page padding **16**, section gap **24**, card padding **14**, card
gap **12**, pill gap **8**. Progress rings: dashboard **34/4.5**, history summary
**72/7**. Minimum tap target **44×44**. Comfortable for one-handed thumb use —
never compressed for density. The dashboard is a single vertical scroll, grouped
into user-named sections; completed and monthly items stay visible (never hidden
or collapsed).

### Backgrounds, borders & elevation
Flat, **border-defined** surfaces — a 1px hairline divider at varied opacity
defines cards by state (incomplete 0.6, completed 0.35, unavailable 0.45). No
gradients, textures, or imagery behind content; the canvas is a single calm plane.
The **only real shadow** in the app is the transient undo banner
(`0 4px 10px rgba(0,0,0,.12)`). The management menu uses a soft popover shadow +
blur. Cards never cast shadows.

### Card states (the heart of the system)
- **Incomplete** — elevated surface, strongest border, teal (active) ring, no check.
- **Completed today** — softer surface + faint green wash, green ring **with center
  checkmark**, `Today` last-done; contrast softens but the row stays fully readable
  (never grayed into irrelevance).
- **Unavailable now** — dimmed surface + secondary wash, **muted** ring, name and
  labels in secondary tone, completion disabled, explicit availability text shown.
  History stays reachable. No strikethrough.
- **Target met / exceeded** — full green ring; exceeded shows real overage (`6/5`),
  never a trophy.

### Motion & interaction
Motion **confirms state, never entertains**. Completion fill/check ≈ **160ms**;
undo banner slide/fade ≈ **200ms**; standard iOS sheet presentation. No bounces,
confetti, reward bursts, urgency pulses, or constantly-animating surfaces. Respect
reduced motion. Haptics (in-app) are light: selection feedback on completion/undo,
never celebratory. Press/hover states are quiet — opacity/tint shifts, not scale
bounces. Completion is **one tap** with immediate, instant-feeling state updates;
tapping an already-complete row opens history rather than double-completing.

### Accessibility
Designed in, not bolted on: Dynamic Type, VoiceOver combined labels, sufficient
contrast in both appearances + high-contrast variants, never color-alone signalling,
44pt minimum targets, reachable history even when completion is disabled.

---

## Iconography

The app uses **Apple SF Symbols** exclusively, monochrome or hierarchical, weight
matched to adjacent text — `gearshape` (management), `pencil` (edit), `calendar`
(history), `checkmark` (completion, inside the ring), `plus` (add), `trash`
(delete), `chevron.left` (back), reorder handles, segmented `chevron.up.chevron.down`.
No custom icon packs, no multicolor symbols, no emoji, no decorative glyphs.

**On the web, SF Symbols can't be redistributed**, so this system substitutes
**[Lucide](https://lucide.dev)** (MIT) — the closest clean, rounded line set
(stroke 2, round caps). The `Icon` component carries the curated set
(`settings, pencil, calendar, check, plus, minus, trash, chevron-left,
chevron-updown, reorder, x`); `IconButton` wraps it in a 44×44 target. ⚠️ This is a
**substitution** — if you need pixel-exact SF Symbols for a real iOS surface, use
the system symbols directly.

**Brand imagery** is just the **app icon** (`assets/app-icon-*.png`, three iOS
variants): the product's own motif — a partial sage-green progress ring with a
warm-cream checkmark on charcoal. No mascots, badges, flames, or streak art.

---

## Index / manifest

```
styles.css              ← global entry point (consumers link this). @import-only.
tokens/
  colors.css            ← color roles (light + dark) + derived tints
  typography.css        ← system-font stack + iOS type roles
  spacing.css           ← spacing scale, radii, rings, elevation, motion
components/core/         ← React primitives (PascalCase .jsx + .d.ts + .prompt.md)
  Icon · ProgressRing · MetadataPill · RoutineCard · Button · IconButton · UndoBanner
  core.card.html        ← Design System tab specimen for the component group
guidelines/              ← foundation specimen cards (Colors · Type · Spacing · Brand)
ui_kits/routine_app/     ← interactive iPhone recreation of the Routine app
  index.html, app.jsx, Dashboard.jsx, History.jsx, Forms.jsx, routine-data.js, ios-frame.jsx
templates/today-dashboard/ ← editable starting-point screen (Today dashboard) for consumers
assets/                  ← app-icon-{default,dark,tinted}.png · screens/ reference captures
SKILL.md                ← agent-skill entry point
readme.md                ← this file
```

### Components
`RoutineCard` (the hero — one-tap completion row), `ProgressRing` (the signature
motif), `MetadataPill`, `Button`, `IconButton`, `UndoBanner`, `Icon`. Each has a
`.d.ts` contract and a `.prompt.md` with usage. `RoutineCard` is also a Starting
Point.

### UI kit
`ui_kits/routine_app` — an interactive Today dashboard with completion + undo,
routine history, the management menu, and add/edit sheets, in dark and light.

### Template
`templates/today-dashboard` — an editable **Today Dashboard** starting point that
composes `RoutineCard` from real seed data; consuming projects can copy it and edit
the data in its logic class.

### Foundations (Design System tab)
~16 specimen cards across **Colors**, **Type**, **Spacing**, and **Brand**.

---

*Fonts: Routine ships no custom typeface — it relies on San Francisco / the system
font stack, so no font files are bundled. The compiler may flag `SF Pro Text` as
having no `@font-face`; that's expected and needs no upload.*
