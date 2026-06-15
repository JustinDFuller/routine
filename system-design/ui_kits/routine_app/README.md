# Routine — iPhone app UI kit

A high-fidelity, interactive recreation of the **Routine** iPhone app (dark-first,
warm, calm). It composes the design-system primitives — `RoutineCard`,
`ProgressRing`, `Button`, `IconButton`, `MetadataPill`, `UndoBanner` — inside an
iOS device frame.

## Run it
Open `index.html`. Toggle **dark / light** above the phone (dark is the primary
appearance). Everything below it is the real product surface.

## What's interactive
- **Today dashboard** — grouped sections of routine cards. Tap an incomplete,
  available card to **complete it**: the ring fills, a center checkmark appears,
  the count + last-done update, and a transient **Undo banner** slides in
  (auto-dismisses after a few seconds).
- **Unavailable cards** (e.g. *Wake up early*) are dimmed and not tappable, but
  still show their availability window and open history.
- **History** — tap any card's calendar button (or a completed card) to open the
  routine's history: summary ring, month calendar with completed-day marks +
  today's ring, and a removable recent-completions list.
- **Management menu** — the gear opens Add Routine, Add Group, Edit,
  Rearrange Groups, Rearrange Routines, Week Starts On.
- **Add / Edit Routine sheet** — name, target stepper, Weekly/Monthly segmented
  control, group picker, availability toggle. Saving adds a live card.
- **Add / Rename Group**, **Settings (week start)**, and **Rearrange** modes.

## Files
| File | Role |
|---|---|
| `index.html` | Loads React, the DS bundle, data + screens; mounts the app. |
| `routine-data.js` | Seed dataset (fixed "today" = Wed Jun 10, 2026). |
| `app.jsx` | Controller: state, navigation, completion/undo, sheets. |
| `Dashboard.jsx` | Today dashboard + section headers. |
| `History.jsx` | Summary, month grid, recent completions. |
| `Forms.jsx` | Management menu, routine/group forms, settings, rearrange. |
| `ios-frame.jsx` | Device bezel, status bar, home indicator (starter). |

## Fidelity notes
Recreated from the `JustinDFuller/routine` SwiftUI source (colors, card-state
logic, ring rules, copy) and the captured screenshots — not from screenshots
alone. SF Symbols are substituted with Lucide line icons. The native iOS
form/menu/sheet chrome is approximated with the brand's own tokens.
