import * as React from "react";

export interface IconProps {
  /** Icon name from the Routine set (SF Symbols → Lucide substitutes). */
  name:
    | "settings"
    | "pencil"
    | "calendar"
    | "check"
    | "plus"
    | "minus"
    | "trash"
    | "chevron-left"
    | "chevron-updown"
    | "reorder"
    | "x";
  /** Pixel size of the square glyph. Default 22. */
  size?: number;
  /** Stroke width. Default 2 (Lucide regular). */
  strokeWidth?: number;
  /** Stroke color. Default currentColor. */
  color?: string;
  style?: React.CSSProperties;
}

export function Icon(props: IconProps): JSX.Element;
