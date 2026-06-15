The dashboard routine row — Routine's hero component. The card body is the one-tap completion target; a trailing calendar button opens history.

```jsx
<RoutineCard name="Morning yoga" count="2/5" period="week" lastDone="Yesterday"
             completed={2} target={5} state="incomplete" onComplete={fn} onHistory={fn} />
<RoutineCard name="Walk the dog" count="3/5" period="week" lastDone="Today"
             completed={3} target={5} state="complete" />
<RoutineCard name="Wake up early" count="1/4" period="week" lastDone="Yesterday"
             availability="Available 12:00 AM–6:45 AM" state="unavailable" completed={1} target={4} />
```

`state` drives everything: `incomplete` (elevated surface, teal ring), `complete` (softer surface + green wash + checkmark), `unavailable` (dimmed, ring muted, tap disabled, availability line shown), `target-met`/`over-target` (full green ring, still actionable). Set `showEdit` to reveal the pencil in Edit mode. Never gray a completed row into irrelevance.
