import React from "react";

/**
 * Button — Routine's action button, mirroring the native iOS styles used
 * across the app's forms, empty states, and history.
 *
 * variants:
 *  - prominent   → filled (borderedProminent), tinted by `tone`. Primary CTA.
 *  - tinted      → soft tinted-capsule (the Undo / bordered look)
 *  - bordered    → hairline outline on transparent (history "Remove")
 *  - plain       → text-only (toolbar Cancel / Done / Save)
 *
 * tone: active (default) · complete · destructive
 */
const TONE = {
  active: "var(--accent-active)",
  complete: "var(--accent-complete)",
  destructive: "var(--accent-destructive)",
};

export function Button({
  children,
  variant = "prominent",
  tone = "active",
  size = "md",
  type = "button",
  disabled = false,
  onClick,
  style,
  ...rest
}) {
  const toneColor = TONE[tone] || TONE.active;
  const pad = size === "sm" ? "7px 12px" : size === "lg" ? "13px 22px" : "10px 18px";
  const fontSize = size === "sm" ? "var(--text-subheadline)" : "var(--text-body)";

  const base = {
    appearance: "none",
    border: "none",
    cursor: disabled ? "default" : "pointer",
    font: `var(--weight-semibold) ${fontSize}/1.1 var(--font-system)`,
    padding: pad,
    borderRadius: "var(--radius-pill)",
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    gap: "8px",
    minHeight: size === "sm" ? "auto" : "44px",
    opacity: disabled ? 0.4 : 1,
    transition: "opacity 120ms var(--ease-standard), background-color 120ms var(--ease-standard)",
    WebkitTapHighlightColor: "transparent",
  };

  const variants = {
    prominent: {
      background: toneColor,
      color: tone === "complete" ? "#16210d" : "#ffffff",
    },
    tinted: {
      background: `color-mix(in srgb, ${toneColor} 12%, transparent)`,
      color: toneColor,
    },
    bordered: {
      background: "transparent",
      color: toneColor,
      boxShadow: `inset 0 0 0 1px color-mix(in srgb, ${toneColor} 45%, transparent)`,
    },
    plain: {
      background: "transparent",
      color: toneColor,
      padding: size === "sm" ? "6px 8px" : "10px 8px",
      borderRadius: "8px",
    },
  };

  return (
    <button
      type={type}
      disabled={disabled}
      onClick={onClick}
      style={{ ...base, ...variants[variant], ...style }}
      {...rest}
    >
      {children}
    </button>
  );
}
