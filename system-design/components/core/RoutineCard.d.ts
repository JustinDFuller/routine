import * as React from "react";

/**
 * The dashboard routine row — Routine's hero component.
 */
export interface RoutineCardProps {
  /** Routine name. */
  name: string;
  /** Count text, e.g. `3/5` or `6/5` (over target). */
  count: string;
  /** Period label: `week` or `month`. */
  period?: string;
  /** Last-done cue: `Today`, `Yesterday`, `3d ago`, `Jun 2`, `Never`. */
  lastDone?: string;
  /** Optional availability line, e.g. `Available 11:00 PM–3:00 AM`. */
  availability?: string | null;
  /** Completions this period (drives ring fill). */
  completed?: number;
  /** Target this period. */
  target?: number;
  /** Explicit 0–1 ring fill; overrides completed/target. */
  fillRatio?: number;
  /** Visual state. */
  state?: "incomplete" | "complete" | "unavailable" | "target-met" | "over-target";
  /** Show the trailing edit (pencil) affordance (Edit mode). */
  showEdit?: boolean;
  /** Show the trailing history (calendar) affordance. Default true. */
  showHistory?: boolean;
  /** Tapping the card body — marks complete when incomplete. */
  onComplete?: () => void;
  /** Trailing history button. */
  onHistory?: () => void;
  /** Trailing edit button. */
  onEdit?: () => void;
  style?: React.CSSProperties;
}

export function RoutineCard(props: RoutineCardProps): JSX.Element;
