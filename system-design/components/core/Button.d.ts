import * as React from "react";

export interface ButtonProps {
  children?: React.ReactNode;
  /** prominent (filled CTA) · tinted (soft capsule) · bordered (outline) · plain (text). */
  variant?: "prominent" | "tinted" | "bordered" | "plain";
  /** Color role. */
  tone?: "active" | "complete" | "destructive";
  size?: "sm" | "md" | "lg";
  type?: "button" | "submit" | "reset";
  disabled?: boolean;
  onClick?: (e: React.MouseEvent<HTMLButtonElement>) => void;
  style?: React.CSSProperties;
}

export function Button(props: ButtonProps): JSX.Element;
