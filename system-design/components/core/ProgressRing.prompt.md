The continuous progress ring — Routine's signature motif. Use it anywhere you show weekly/monthly progress at a glance.

```jsx
<ProgressRing completed={3} target={5} accent="active" />
<ProgressRing completed={5} target={5} showCheckmark accent="complete" />
<ProgressRing fillRatio={1} accent="muted" size={72} strokeWidth={7} />
```

One continuous stroke, never segmented; fill caps at a full circle. Dashboard size is 34/4.5, history summary is 72/7. Accent `active` (teal) for in-progress, `complete` (green) once the target is met or done today, `muted` when unavailable. The center checkmark appears only in the done-today state.
