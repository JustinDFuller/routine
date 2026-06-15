import * as React from "react";

export interface MetadataPillProps {
  /** Pill content — typically a count (`3/5`) or period (`week`). */
  children?: React.ReactNode;
  /** Accent that tints the fill; pair with the card's ring accent. */
  accent?: "complete" | "active" | "muted";
  /** Use the slightly stronger completed-card tint (0.14 vs 0.10). */
  emphasized?: boolean;
  style?: React.CSSProperties;
}

export function MetadataPill(props: MetadataPillProps): JSX.Element;
