A 44×44 secondary-action target for the trailing history (calendar) and edit (pencil) affordances, and the gear menu.

```jsx
<IconButton icon="calendar" label="History for Morning yoga" onClick={fn} />
<IconButton icon="pencil" label="Edit Morning yoga" onClick={fn} />
<IconButton icon="settings" label="Management" tone="primary" />
```

Monochrome, `secondary` tone by default. The 44pt frame stays tappable while the glyph reads ~22px. Always pass a `label` — these are icon-only controls.
