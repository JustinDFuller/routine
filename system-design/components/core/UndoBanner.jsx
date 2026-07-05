import React from "react";

/**
 * UndoBanner — the transient overlay shown after a completion. Native-feeling,
 * elevated surface with a hairline and the app's single real shadow. Carries a
 * plain message and a soft tinted "Undo" action. Appears near the bottom of the
 * screen; dismisses on its own if ignored. Forgiving by design, never punitive.
 */
export function UndoBanner({ message = "Completed routine", actionTitle = "Undo", onUndo, style }) {
  return (
    <div
      role="status"
      style={{
        display: "flex",
        alignItems: "center",
        gap: "12px",
        padding: "14px 16px",
        background: "var(--surface-sheet)",
        borderRadius: "var(--radius-sheet)",
        boxShadow: "var(--shadow-banner)",
        border: "1px solid var(--border-banner-accent)",
        ...style,
      }}
    >
      <span
        style={{
          flex: 1,
          minWidth: 0,
          color: "var(--text-primary)",
          font: `var(--weight-regular) var(--text-subheadline)/var(--leading-subheadline) var(--font-system)`,
        }}
      >
        {message}
      </span>
      <button
        type="button"
        onClick={onUndo}
        style={{
          appearance: "none",
          border: "none",
          cursor: "pointer",
          color: "var(--accent-active)",
          background: "var(--tint-active-soft)",
          font: `var(--weight-semibold) var(--text-subheadline)/1 var(--font-system)`,
          padding: "8px 12px",
          borderRadius: "var(--radius-pill)",
          flexShrink: 0,
          WebkitTapHighlightColor: "transparent",
        }}
      >
        {actionTitle}
      </button>
    </div>
  );
}
