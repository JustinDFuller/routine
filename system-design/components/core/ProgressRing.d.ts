import * as React from "react";

/**
 * The continuous progress ring — Routine's primary visual motif.
 */
export interface ProgressRingProps {
  /** Completions in the current period. */
  completed?: number;
  /** Target count for the period. */
  target?: number;
  /** Explicit 0–1 fill; overrides completed/target when provided. Capped at 1. */
  fillRatio?: number;
  /** Show the center checkmark (done-today state only). */
  showCheckmark?: boolean;
  /** Accent role for the filled stroke. */
  accent?: "complete" | "active" | "muted";
  /** Outer diameter in px. Dashboard uses 34, history summary 72. */
  size?: number;
  /** Stroke width in px. Dashboard 4.5, summary 7. */
  strokeWidth?: number;
  style?: React.CSSProperties;
}

export function ProgressRing(props: ProgressRingProps): JSX.Element;
