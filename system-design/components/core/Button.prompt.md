Routine's action button, mirroring the native iOS styles used in forms, empty states, and history.

```jsx
<Button variant="prominent" tone="active">Add Routine</Button>
<Button variant="tinted" tone="active">Undo</Button>
<Button variant="bordered" tone="destructive" size="sm">Remove</Button>
<Button variant="plain" tone="active">Cancel</Button>
```

`prominent` is the filled CTA (empty-state, sheet actions), `tinted` is the soft capsule, `bordered` is the hairline outline (history Remove), `plain` is text-only (toolbar Cancel/Save/Done). Tone `active` (teal) by default, `complete` (green) for completion, `destructive` (red) for delete/remove.
