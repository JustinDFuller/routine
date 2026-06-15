import React from "react";
import { ProgressRing } from "./ProgressRing.jsx";
import { MetadataPill } from "./MetadataPill.jsx";
import { IconButton } from "./IconButton.jsx";

/**
 * RoutineCard — the core dashboard row. Five pieces of info: progress ring,
 * name, count vs. target, period, last-done cue (+ an optional availability
 * line). The card body is the one-tap completion target when incomplete; a
 * trailing calendar button always opens history. State drives surface, border,
 * wash, ring accent, and the center checkmark — never color alone.
 *
 * state: "incomplete" | "complete" | "unavailable" | "target-met" | "over-target"
 */
export function RoutineCard({
  name,
  count,
  period = "week",
  lastDone,
  availability = null,
  completed = 0,
  target = 1,
  fillRatio,
  state = "incomplete",
  showEdit = false,
  showHistory = true,
  onComplete,
  onHistory,
  onEdit,
  style,
}) {
  const isUnavailable = state === "unavailable";
  const isComplete = state === "complete";
  const ringFull = state === "target-met" || state === "over-target";

  const accent = isUnavailable ? "muted" : isComplete || ringFull ? "complete" : "active";

  const surface = isComplete || isUnavailable ? "var(--surface-card)" : "var(--surface-sheet)";
  const border = isUnavailable
    ? "var(--card-border-unavailable)"
    : isComplete
      ? "var(--card-border-complete)"
      : "var(--card-border-incomplete)";
  const wash = isComplete
    ? "var(--card-wash-complete)"
    : isUnavailable
      ? "var(--card-wash-unavailable)"
      : "transparent";

  const nameColor = isUnavailable ? "var(--text-secondary)" : "var(--text-primary)";

  return (
    <div
      style={{
        position: "relative",
        display: "flex",
        alignItems: "stretch",
        background: surface,
        borderRadius: "var(--radius-card)",
        boxShadow: `inset 0 0 0 1px ${border}`,
        ...style,
      }}
    >
      {/* state wash overlay */}
      <div
        aria-hidden="true"
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: "var(--radius-card)",
          background: wash,
          pointerEvents: "none",
        }}
      />

      {/* primary completion target */}
      <button
        type="button"
        onClick={isUnavailable ? undefined : onComplete}
        disabled={isUnavailable}
        style={{
          position: "relative",
          appearance: "none",
          border: "none",
          background: "transparent",
          textAlign: "left",
          flex: 1,
          minWidth: 0,
          display: "flex",
          alignItems: "center",
          gap: "12px",
          minHeight: "72px",
          padding: "14px 8px 14px 14px",
          cursor: isUnavailable ? "default" : "pointer",
          WebkitTapHighlightColor: "transparent",
        }}
      >
        <ProgressRing
          completed={completed}
          target={target}
          fillRatio={fillRatio}
          showCheckmark={isComplete}
          accent={accent}
        />
        <span style={{ display: "flex", flexDirection: "column", gap: "8px", minWidth: 0 }}>
          <span
            style={{
              color: nameColor,
              font: `var(--weight-semibold) var(--text-headline)/var(--leading-headline) var(--font-system)`,
            }}
          >
            {name}
          </span>
          <span style={{ display: "flex", flexWrap: "wrap", alignItems: "center", gap: "8px" }}>
            <MetadataPill accent={accent} emphasized={isComplete}>
              {count}
            </MetadataPill>
            <MetadataPill accent={accent} emphasized={isComplete}>
              {period}
            </MetadataPill>
            {lastDone && (
              <span
                style={{
                  color: "var(--text-secondary)",
                  font: `var(--weight-regular) var(--text-caption)/var(--leading-caption) var(--font-system)`,
                }}
              >
                {lastDone}
              </span>
            )}
          </span>
          {availability && (
            <span
              style={{
                color: isUnavailable ? "var(--text-primary)" : "var(--text-secondary)",
                font: `var(--weight-regular) var(--text-caption)/var(--leading-caption) var(--font-system)`,
              }}
            >
              {availability}
            </span>
          )}
        </span>
      </button>

      {/* trailing secondary actions */}
      <div style={{ position: "relative", display: "flex", alignItems: "center", paddingRight: showHistory ? "8px" : 0 }}>
        {showEdit && <IconButton icon="pencil" label={`Edit ${name}`} onClick={onEdit} />}
        {showHistory && <IconButton icon="calendar" label={`History for ${name}`} onClick={onHistory} />}
      </div>
    </div>
  );
}
