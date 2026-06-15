import React from "react";
import { Icon } from "./Icon.jsx";

/**
 * ProgressRing — the primary visual motif of Routine.
 *
 * One continuous stroke (never segmented) showing current-period progress.
 * Fill is capped at a full circle even when completions exceed target.
 * A center checkmark appears only when the routine is completed today.
 * Communicates without color alone: track vs. fill + checkmark + count text.
 */
const ACCENTS = {
  complete: "var(--accent-complete)",
  active: "var(--accent-active)",
  muted: "var(--text-secondary)",
};

export function ProgressRing({
  completed = 0,
  target = 1,
  fillRatio,
  showCheckmark = false,
  accent = "active",
  size = 34,
  strokeWidth = 4.5,
  style,
}) {
  const ratio =
    typeof fillRatio === "number"
      ? Math.min(Math.max(fillRatio, 0), 1)
      : Math.min(Math.max(completed / Math.max(target, 1), 0), 1);

  const stroke = ACCENTS[accent] || ACCENTS.active;
  const r = (size - strokeWidth) / 2;
  const c = 2 * Math.PI * r;
  const dash = c * ratio;

  return (
    <div
      style={{
        position: "relative",
        width: size,
        height: size,
        flexShrink: 0,
        display: "grid",
        placeItems: "center",
        ...style,
      }}
    >
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} style={{ display: "block" }}>
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke="var(--ring-track)"
          strokeWidth={strokeWidth}
        />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke={stroke}
          strokeWidth={strokeWidth}
          strokeLinecap="round"
          strokeDasharray={`${dash} ${c - dash}`}
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
          style={{ transition: "stroke-dasharray var(--motion-complete) var(--ease-standard)" }}
        />
      </svg>
      {showCheckmark && (
        <span
          style={{
            position: "absolute",
            inset: 0,
            display: "grid",
            placeItems: "center",
            color: "var(--text-primary)",
          }}
        >
          <Icon name="check" size={size * 0.46} strokeWidth={3} />
        </span>
      )}
    </div>
  );
}
