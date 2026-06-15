import React from "react";

/**
 * MetadataPill — the soft capsule used for count (`3/5`) and period (`week`)
 * on routine cards. Fill is a faint tint of the card's ring accent; text is
 * label-primary, caption semibold. Not for status badges that need color —
 * Routine keeps decorative color low and never relies on color alone.
 */
export function MetadataPill({ children, accent = "active", emphasized = false, style }) {
  const accentVar =
    accent === "complete"
      ? "var(--accent-complete)"
      : accent === "muted"
        ? "var(--text-secondary)"
        : "var(--accent-active)";

  return (
    <span
      style={{
        // currentColor drives the tinted fill via color-mix
        color: accentVar,
        display: "inline-flex",
        alignItems: "center",
        font: `var(--weight-semibold) var(--text-caption)/1 var(--font-system)`,
        padding: "4px 8px",
        borderRadius: "var(--radius-pill)",
        background: emphasized ? "var(--pill-fill-complete)" : "var(--pill-fill-incomplete)",
        ...style,
      }}
    >
      <span style={{ color: "var(--text-primary)", letterSpacing: "0.01em" }}>{children}</span>
    </span>
  );
}
