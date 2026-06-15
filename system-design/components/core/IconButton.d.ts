import * as React from "react";
import { IconProps } from "./Icon";

export interface IconButtonProps {
  /** Icon name from the Routine set. */
  icon: IconProps["name"];
  /** Accessible label (required — icon-only control). */
  label: string;
  /** Glyph size in px (frame stays 44×44). Default 22. */
  size?: number;
  tone?: "secondary" | "primary" | "active" | "destructive";
  onClick?: (e: React.MouseEvent<HTMLButtonElement>) => void;
  disabled?: boolean;
  style?: React.CSSProperties;
}

export function IconButton(props: IconButtonProps): JSX.Element;
