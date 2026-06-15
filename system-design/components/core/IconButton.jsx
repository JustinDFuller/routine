import React from "react";
import { Icon } from "./Icon.jsx";

/**
 * IconButton — a 44×44 secondary-action target. Used for the trailing
 * history (calendar) and edit (pencil) affordances on routine cards and
 * the gear management menu. Monochrome, label-secondary by default; the
 * full 44pt frame stays tappable while the glyph reads ~22px.
 */
export function IconButton({
  icon,
  label,
  size = 22,
  tone = "secondary",
  onClick,
  disabled = false,
  style,
  ...rest
}) {
  const color =
    tone === "primary"
      ? "var(--text-primary)"
      : tone === "active"
        ? "var(--accent-active)"
        : tone === "destructive"
          ? "var(--accent-destructive)"
          : "var(--text-secondary)";

  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      aria-label={label}
      style={{
        appearance: "none",
        border: "none",
        background: "transparent",
        width: "var(--tap-min)",
        height: "var(--tap-min)",
        display: "grid",
        placeItems: "center",
        color,
        cursor: disabled ? "default" : "pointer",
        opacity: disabled ? 0.4 : 1,
        flexShrink: 0,
        borderRadius: "10px",
        WebkitTapHighlightColor: "transparent",
        ...style,
      }}
      {...rest}
    >
      <Icon name={icon} size={size} />
    </button>
  );
}
