import * as React from "react";

export interface UndoBannerProps {
  /** e.g. `Completed Morning yoga`. */
  message?: string;
  /** Action label. Default `Undo`. */
  actionTitle?: string;
  onUndo?: () => void;
  style?: React.CSSProperties;
}

export function UndoBanner(props: UndoBannerProps): JSX.Element;
