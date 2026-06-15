/* @ds-bundle: {"format":3,"namespace":"RoutineDesignSystem_14e910","components":[{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"Icon","sourcePath":"components/core/Icon.jsx"},{"name":"IconButton","sourcePath":"components/core/IconButton.jsx"},{"name":"MetadataPill","sourcePath":"components/core/MetadataPill.jsx"},{"name":"ProgressRing","sourcePath":"components/core/ProgressRing.jsx"},{"name":"RoutineCard","sourcePath":"components/core/RoutineCard.jsx"},{"name":"UndoBanner","sourcePath":"components/core/UndoBanner.jsx"}],"sourceHashes":{"components/core/Button.jsx":"23c68b51b8c4","components/core/Icon.jsx":"6c9bae0bf7f7","components/core/IconButton.jsx":"eebc69342135","components/core/MetadataPill.jsx":"77dc39154896","components/core/ProgressRing.jsx":"0408af64f70d","components/core/RoutineCard.jsx":"29be57ccdf9a","components/core/UndoBanner.jsx":"646d1b63735a","ui_kits/routine_app/Dashboard.jsx":"03a394305442","ui_kits/routine_app/Forms.jsx":"75d703464d5a","ui_kits/routine_app/History.jsx":"3b08a6486964","ui_kits/routine_app/app.jsx":"48cebb8742bf","ui_kits/routine_app/ios-frame.jsx":"be3343be4b51","ui_kits/routine_app/routine-data.js":"a14bccec19d1"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.RoutineDesignSystem_14e910 = window.RoutineDesignSystem_14e910 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/core/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
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
  destructive: "var(--accent-destructive)"
};
function Button({
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
    WebkitTapHighlightColor: "transparent"
  };
  const variants = {
    prominent: {
      background: toneColor,
      color: tone === "complete" ? "#16210d" : "#ffffff"
    },
    tinted: {
      background: `color-mix(in srgb, ${toneColor} 12%, transparent)`,
      color: toneColor
    },
    bordered: {
      background: "transparent",
      color: toneColor,
      boxShadow: `inset 0 0 0 1px color-mix(in srgb, ${toneColor} 45%, transparent)`
    },
    plain: {
      background: "transparent",
      color: toneColor,
      padding: size === "sm" ? "6px 8px" : "10px 8px",
      borderRadius: "8px"
    }
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    type: type,
    disabled: disabled,
    onClick: onClick,
    style: {
      ...base,
      ...variants[variant],
      ...style
    }
  }, rest), children);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/Icon.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Routine interface icons.
 *
 * The app uses Apple SF Symbols, which are proprietary and cannot be
 * redistributed on the web. We substitute Lucide (MIT) path data — a clean,
 * rounded line set that reads closest to SF Symbols' default weight.
 * Stroke 2, round caps/joins, 24×24 grid, currentColor.
 */
const PATHS = {
  // gearshape
  settings: /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("path", {
    d: "M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "12",
    cy: "12",
    r: "3"
  })),
  // pencil.circle → pencil
  pencil: /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("path", {
    d: "M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"
  }), /*#__PURE__*/React.createElement("path", {
    d: "m15 5 4 4"
  })),
  // calendar (history affordance)
  calendar: /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("path", {
    d: "M8 2v4"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M16 2v4"
  }), /*#__PURE__*/React.createElement("rect", {
    width: "18",
    height: "18",
    x: "3",
    y: "4",
    rx: "2"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M3 10h18"
  })),
  // checkmark
  check: /*#__PURE__*/React.createElement("path", {
    d: "M20 6 9 17l-5-5"
  }),
  // plus
  plus: /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("path", {
    d: "M5 12h14"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M12 5v14"
  })),
  // minus
  minus: /*#__PURE__*/React.createElement("path", {
    d: "M5 12h14"
  }),
  // trash
  trash: /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("path", {
    d: "M3 6h18"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M10 11v6"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M14 11v6"
  })),
  // chevron.left (back)
  "chevron-left": /*#__PURE__*/React.createElement("path", {
    d: "m15 18-6-6 6-6"
  }),
  // chevron.up.chevron.down (inline picker)
  "chevron-updown": /*#__PURE__*/React.createElement("path", {
    d: "m7 15 5 5 5-5M7 9l5-5 5 5"
  }),
  // line.3.horizontal (reorder handle)
  reorder: /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("path", {
    d: "M4 8h16"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M4 16h16"
  })),
  // xmark
  x: /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("path", {
    d: "M18 6 6 18"
  }), /*#__PURE__*/React.createElement("path", {
    d: "m6 6 12 12"
  }))
};
function Icon({
  name,
  size = 22,
  strokeWidth = 2,
  color = "currentColor",
  style,
  ...rest
}) {
  const content = PATHS[name];
  return /*#__PURE__*/React.createElement("svg", _extends({
    width: size,
    height: size,
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: color,
    strokeWidth: strokeWidth,
    strokeLinecap: "round",
    strokeLinejoin: "round",
    "aria-hidden": "true",
    style: {
      display: "block",
      flexShrink: 0,
      ...style
    }
  }, rest), content);
}
Object.assign(__ds_scope, { Icon });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Icon.jsx", error: String((e && e.message) || e) }); }

// components/core/IconButton.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * IconButton — a 44×44 secondary-action target. Used for the trailing
 * history (calendar) and edit (pencil) affordances on routine cards and
 * the gear management menu. Monochrome, label-secondary by default; the
 * full 44pt frame stays tappable while the glyph reads ~22px.
 */
function IconButton({
  icon,
  label,
  size = 22,
  tone = "secondary",
  onClick,
  disabled = false,
  style,
  ...rest
}) {
  const color = tone === "primary" ? "var(--text-primary)" : tone === "active" ? "var(--accent-active)" : tone === "destructive" ? "var(--accent-destructive)" : "var(--text-secondary)";
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    onClick: onClick,
    disabled: disabled,
    "aria-label": label,
    style: {
      appearance: "none",
      border: "none",
      background: "transparent",
      width: "var(--tap-min)",
      height: "var(--tap-min)",
      display: "grid",
      placeItems: "center",
      color,
      cursor: disabled ? "default" : "pointer",
      opacity: disabled ? 0.4 : 1,
      flexShrink: 0,
      borderRadius: "10px",
      WebkitTapHighlightColor: "transparent",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: size
  }));
}
Object.assign(__ds_scope, { IconButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/IconButton.jsx", error: String((e && e.message) || e) }); }

// components/core/MetadataPill.jsx
try { (() => {
/**
 * MetadataPill — the soft capsule used for count (`3/5`) and period (`week`)
 * on routine cards. Fill is a faint tint of the card's ring accent; text is
 * label-primary, caption semibold. Not for status badges that need color —
 * Routine keeps decorative color low and never relies on color alone.
 */
function MetadataPill({
  children,
  accent = "active",
  emphasized = false,
  style
}) {
  const accentVar = accent === "complete" ? "var(--accent-complete)" : accent === "muted" ? "var(--text-secondary)" : "var(--accent-active)";
  return /*#__PURE__*/React.createElement("span", {
    style: {
      // currentColor drives the tinted fill via color-mix
      color: accentVar,
      display: "inline-flex",
      alignItems: "center",
      font: `var(--weight-semibold) var(--text-caption)/1 var(--font-system)`,
      padding: "4px 8px",
      borderRadius: "var(--radius-pill)",
      background: emphasized ? "var(--pill-fill-complete)" : "var(--pill-fill-incomplete)",
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      color: "var(--text-primary)",
      letterSpacing: "0.01em"
    }
  }, children));
}
Object.assign(__ds_scope, { MetadataPill });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/MetadataPill.jsx", error: String((e && e.message) || e) }); }

// components/core/ProgressRing.jsx
try { (() => {
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
  muted: "var(--text-secondary)"
};
function ProgressRing({
  completed = 0,
  target = 1,
  fillRatio,
  showCheckmark = false,
  accent = "active",
  size = 34,
  strokeWidth = 4.5,
  style
}) {
  const ratio = typeof fillRatio === "number" ? Math.min(Math.max(fillRatio, 0), 1) : Math.min(Math.max(completed / Math.max(target, 1), 0), 1);
  const stroke = ACCENTS[accent] || ACCENTS.active;
  const r = (size - strokeWidth) / 2;
  const c = 2 * Math.PI * r;
  const dash = c * ratio;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      width: size,
      height: size,
      flexShrink: 0,
      display: "grid",
      placeItems: "center",
      ...style
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: size,
    height: size,
    viewBox: `0 0 ${size} ${size}`,
    style: {
      display: "block"
    }
  }, /*#__PURE__*/React.createElement("circle", {
    cx: size / 2,
    cy: size / 2,
    r: r,
    fill: "none",
    stroke: "var(--ring-track)",
    strokeWidth: strokeWidth
  }), /*#__PURE__*/React.createElement("circle", {
    cx: size / 2,
    cy: size / 2,
    r: r,
    fill: "none",
    stroke: stroke,
    strokeWidth: strokeWidth,
    strokeLinecap: "round",
    strokeDasharray: `${dash} ${c - dash}`,
    transform: `rotate(-90 ${size / 2} ${size / 2})`,
    style: {
      transition: "stroke-dasharray var(--motion-complete) var(--ease-standard)"
    }
  })), showCheckmark && /*#__PURE__*/React.createElement("span", {
    style: {
      position: "absolute",
      inset: 0,
      display: "grid",
      placeItems: "center",
      color: "var(--text-primary)"
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "check",
    size: size * 0.46,
    strokeWidth: 3
  })));
}
Object.assign(__ds_scope, { ProgressRing });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/ProgressRing.jsx", error: String((e && e.message) || e) }); }

// components/core/RoutineCard.jsx
try { (() => {
/**
 * RoutineCard — the core dashboard row. Five pieces of info: progress ring,
 * name, count vs. target, period, last-done cue (+ an optional availability
 * line). The card body is the one-tap completion target when incomplete; a
 * trailing calendar button always opens history. State drives surface, border,
 * wash, ring accent, and the center checkmark — never color alone.
 *
 * state: "incomplete" | "complete" | "unavailable" | "target-met" | "over-target"
 */
function RoutineCard({
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
  style
}) {
  const isUnavailable = state === "unavailable";
  const isComplete = state === "complete";
  const ringFull = state === "target-met" || state === "over-target";
  const accent = isUnavailable ? "muted" : isComplete || ringFull ? "complete" : "active";
  const surface = isComplete || isUnavailable ? "var(--surface-card)" : "var(--surface-sheet)";
  const border = isUnavailable ? "var(--card-border-unavailable)" : isComplete ? "var(--card-border-complete)" : "var(--card-border-incomplete)";
  const wash = isComplete ? "var(--card-wash-complete)" : isUnavailable ? "var(--card-wash-unavailable)" : "transparent";
  const nameColor = isUnavailable ? "var(--text-secondary)" : "var(--text-primary)";
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      display: "flex",
      alignItems: "stretch",
      background: surface,
      borderRadius: "var(--radius-card)",
      boxShadow: `inset 0 0 0 1px ${border}`,
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    "aria-hidden": "true",
    style: {
      position: "absolute",
      inset: 0,
      borderRadius: "var(--radius-card)",
      background: wash,
      pointerEvents: "none"
    }
  }), /*#__PURE__*/React.createElement("button", {
    type: "button",
    onClick: isUnavailable ? undefined : onComplete,
    disabled: isUnavailable,
    style: {
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
      WebkitTapHighlightColor: "transparent"
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.ProgressRing, {
    completed: completed,
    target: target,
    fillRatio: fillRatio,
    showCheckmark: isComplete,
    accent: accent
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      display: "flex",
      flexDirection: "column",
      gap: "8px",
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      color: nameColor,
      font: `var(--weight-semibold) var(--text-headline)/var(--leading-headline) var(--font-system)`
    }
  }, name), /*#__PURE__*/React.createElement("span", {
    style: {
      display: "flex",
      flexWrap: "wrap",
      alignItems: "center",
      gap: "8px"
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.MetadataPill, {
    accent: accent,
    emphasized: isComplete
  }, count), /*#__PURE__*/React.createElement(__ds_scope.MetadataPill, {
    accent: accent,
    emphasized: isComplete
  }, period), lastDone && /*#__PURE__*/React.createElement("span", {
    style: {
      color: "var(--text-secondary)",
      font: `var(--weight-regular) var(--text-caption)/var(--leading-caption) var(--font-system)`
    }
  }, lastDone)), availability && /*#__PURE__*/React.createElement("span", {
    style: {
      color: isUnavailable ? "var(--text-primary)" : "var(--text-secondary)",
      font: `var(--weight-regular) var(--text-caption)/var(--leading-caption) var(--font-system)`
    }
  }, availability))), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      display: "flex",
      alignItems: "center",
      paddingRight: showHistory ? "8px" : 0
    }
  }, showEdit && /*#__PURE__*/React.createElement(__ds_scope.IconButton, {
    icon: "pencil",
    label: `Edit ${name}`,
    onClick: onEdit
  }), showHistory && /*#__PURE__*/React.createElement(__ds_scope.IconButton, {
    icon: "calendar",
    label: `History for ${name}`,
    onClick: onHistory
  })));
}
Object.assign(__ds_scope, { RoutineCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/RoutineCard.jsx", error: String((e && e.message) || e) }); }

// components/core/UndoBanner.jsx
try { (() => {
/**
 * UndoBanner — the transient overlay shown after a completion. Native-feeling,
 * elevated surface with a hairline and the app's single real shadow. Carries a
 * plain message and a soft tinted "Undo" action. Appears near the bottom of the
 * screen; dismisses on its own if ignored. Forgiving by design, never punitive.
 */
function UndoBanner({
  message = "Completed routine",
  actionTitle = "Undo",
  onUndo,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    role: "status",
    style: {
      display: "flex",
      alignItems: "center",
      gap: "12px",
      padding: "14px 16px",
      background: "var(--surface-sheet)",
      borderRadius: "var(--radius-sheet)",
      boxShadow: "var(--shadow-banner)",
      border: "1px solid var(--border-hairline-soft)",
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      minWidth: 0,
      color: "var(--text-primary)",
      font: `var(--weight-regular) var(--text-subheadline)/var(--leading-subheadline) var(--font-system)`
    }
  }, message), /*#__PURE__*/React.createElement("button", {
    type: "button",
    onClick: onUndo,
    style: {
      appearance: "none",
      border: "none",
      cursor: "pointer",
      color: "var(--accent-active)",
      background: "var(--tint-active-soft)",
      font: `var(--weight-semibold) var(--text-subheadline)/1 var(--font-system)`,
      padding: "8px 12px",
      borderRadius: "var(--radius-pill)",
      flexShrink: 0,
      WebkitTapHighlightColor: "transparent"
    }
  }, actionTitle));
}
Object.assign(__ds_scope, { UndoBanner });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/UndoBanner.jsx", error: String((e && e.message) || e) }); }

// ui_kits/routine_app/Dashboard.jsx
try { (() => {
/* Routine UI kit — Today Dashboard */
(function () {
  const NS = window.RoutineDesignSystem_14e910;
  const {
    RoutineCard,
    IconButton
  } = NS;
  function SectionHeader({
    name,
    editable,
    onEdit
  }) {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        gap: 12,
        minHeight: editable ? 28 : "auto"
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--text-secondary)",
        font: "var(--weight-semibold) var(--text-subheadline)/var(--leading-subheadline) var(--font-system)"
      }
    }, name), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1
      }
    }), editable && /*#__PURE__*/React.createElement(IconButton, {
      icon: "pencil",
      label: `Edit ${name}`,
      size: 20,
      onClick: onEdit
    }));
  }
  function Dashboard({
    data,
    mode,
    onComplete,
    onHistory,
    onEditRoutine,
    onEditGroup,
    onGear,
    onDoneEditing
  }) {
    const byId = React.useMemo(() => {
      const m = {};
      data.routines.forEach(r => m[r.id] = r);
      return m;
    }, [data.routines]);
    const editing = mode === "edit";
    return /*#__PURE__*/React.createElement("div", {
      style: {
        minHeight: "100%",
        background: "var(--bg-canvas)",
        paddingBottom: 28
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "8px 16px 0",
        display: "flex",
        flexDirection: "column",
        gap: 24
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        gap: 12,
        paddingTop: 6
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--text-primary)",
        font: "var(--weight-semibold) var(--text-title)/var(--leading-title) var(--font-system)"
      }
    }, "Today"), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1
      }
    }), editing ? /*#__PURE__*/React.createElement("button", {
      type: "button",
      onClick: onDoneEditing,
      style: {
        appearance: "none",
        border: "none",
        background: "transparent",
        color: "var(--accent-active)",
        font: "var(--weight-semibold) var(--text-body)/1 var(--font-system)",
        cursor: "pointer",
        minHeight: 44,
        padding: "0 4px"
      }
    }, "Done") : /*#__PURE__*/React.createElement(IconButton, {
      icon: "settings",
      label: "Management",
      tone: "primary",
      onClick: onGear
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        marginTop: -12,
        color: "var(--text-secondary)",
        font: "var(--weight-regular) var(--text-subheadline)/var(--leading-subheadline) var(--font-system)"
      }
    }, data.today.label), data.groups.map(group => /*#__PURE__*/React.createElement("div", {
      key: group.id,
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 10
      }
    }, /*#__PURE__*/React.createElement(SectionHeader, {
      name: group.name,
      editable: editing,
      onEdit: () => onEditGroup(group.id)
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 12
      }
    }, group.routineIds.map(rid => {
      const r = byId[rid];
      if (!r) return null;
      return /*#__PURE__*/React.createElement(RoutineCard, {
        key: r.id,
        name: r.name,
        count: `${r.completed}/${r.target}`,
        period: r.period,
        lastDone: r.lastDone,
        availability: r.availability,
        completed: r.completed,
        target: r.target,
        state: r.state,
        showEdit: editing,
        showHistory: !editing,
        onComplete: () => onComplete(r.id),
        onHistory: () => onHistory(r.id),
        onEdit: () => onEditRoutine(r.id)
      });
    }))))));
  }
  window.Dashboard = Dashboard;
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/routine_app/Dashboard.jsx", error: String((e && e.message) || e) }); }

// ui_kits/routine_app/Forms.jsx
try { (() => {
/* Routine UI kit — management menu, forms, settings, rearrange */
(function () {
  const NS = window.RoutineDesignSystem_14e910;
  const {
    Button,
    IconButton,
    Icon
  } = NS;

  /* ---------- shared form primitives ---------- */
  function FormGroup({
    children
  }) {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        background: "var(--surface-sheet)",
        borderRadius: "var(--radius-control)",
        overflow: "hidden",
        boxShadow: "inset 0 0 0 1px var(--border-hairline-soft)"
      }
    }, children);
  }
  function FormRow({
    children,
    last,
    style
  }) {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        minHeight: 52,
        padding: "10px 14px",
        boxShadow: last ? "none" : "inset 0 -1px 0 var(--border-hairline-soft)",
        ...style
      }
    }, children);
  }
  const labelStyle = {
    color: "var(--text-primary)",
    font: "var(--weight-regular) var(--text-body)/1 var(--font-system)"
  };
  function Stepper({
    value,
    onDec,
    onInc
  }) {
    const btn = (child, onClick, disabled) => /*#__PURE__*/React.createElement("button", {
      type: "button",
      onClick: onClick,
      disabled: disabled,
      style: {
        appearance: "none",
        border: "none",
        background: "transparent",
        color: disabled ? "var(--text-secondary)" : "var(--text-primary)",
        width: 48,
        height: 36,
        display: "grid",
        placeItems: "center",
        cursor: disabled ? "default" : "pointer",
        opacity: disabled ? 0.4 : 1
      }
    }, child);
    return /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        gap: 14
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--text-secondary)",
        font: "var(--weight-regular) var(--text-body)/1 var(--font-system)",
        fontVariantNumeric: "tabular-nums"
      }
    }, value), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        background: "color-mix(in srgb, var(--border-hairline) 50%, transparent)",
        borderRadius: "var(--radius-pill)"
      }
    }, btn(/*#__PURE__*/React.createElement(Icon, {
      name: "minus",
      size: 20
    }), onDec, value <= 1), /*#__PURE__*/React.createElement("span", {
      style: {
        width: 1,
        height: 22,
        background: "var(--border-hairline)"
      }
    }), btn(/*#__PURE__*/React.createElement(Icon, {
      name: "plus",
      size: 20
    }), onInc)));
  }
  function Segmented({
    value,
    options,
    onChange
  }) {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        padding: 2,
        gap: 2,
        background: "color-mix(in srgb, var(--border-hairline) 50%, transparent)",
        borderRadius: "var(--radius-pill)",
        width: "100%"
      }
    }, options.map(opt => {
      const active = opt.value === value;
      return /*#__PURE__*/React.createElement("button", {
        key: opt.value,
        type: "button",
        onClick: () => onChange(opt.value),
        style: {
          flex: 1,
          appearance: "none",
          border: "none",
          cursor: "pointer",
          borderRadius: "var(--radius-pill)",
          padding: "8px 0",
          background: active ? "var(--surface-sheet)" : "transparent",
          boxShadow: active ? "0 1px 3px rgba(0,0,0,.25)" : "none",
          color: active ? "var(--text-primary)" : "var(--text-secondary)",
          font: "var(--weight-semibold) var(--text-subheadline)/1 var(--font-system)"
        }
      }, opt.label);
    }));
  }
  function Switch({
    on,
    onToggle
  }) {
    return /*#__PURE__*/React.createElement("button", {
      type: "button",
      onClick: onToggle,
      "aria-pressed": on,
      style: {
        appearance: "none",
        border: "none",
        cursor: "pointer",
        width: 51,
        height: 31,
        borderRadius: 999,
        padding: 2,
        background: on ? "var(--accent-active)" : "color-mix(in srgb, var(--border-hairline) 80%, transparent)",
        transition: "background 160ms var(--ease-standard)",
        display: "flex",
        justifyContent: on ? "flex-end" : "flex-start"
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: 27,
        height: 27,
        borderRadius: "50%",
        background: "#fff",
        boxShadow: "0 1px 3px rgba(0,0,0,.3)"
      }
    }));
  }
  function SheetShell({
    title,
    onCancel,
    onSave,
    saveLabel,
    children
  }) {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        height: "100%",
        background: "var(--bg-canvas)"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        padding: "48px 16px 12px"
      }
    }, /*#__PURE__*/React.createElement("button", {
      type: "button",
      onClick: onCancel,
      style: {
        appearance: "none",
        border: "none",
        background: "transparent",
        color: "var(--accent-active)",
        font: "var(--weight-regular) var(--text-body)/1 var(--font-system)",
        cursor: "pointer",
        minWidth: 60,
        textAlign: "left"
      }
    }, "Cancel"), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1,
        textAlign: "center",
        color: "var(--text-primary)",
        font: "var(--weight-semibold) var(--text-headline)/1 var(--font-system)"
      }
    }, title), /*#__PURE__*/React.createElement("button", {
      type: "button",
      onClick: onSave,
      style: {
        appearance: "none",
        border: "none",
        background: "transparent",
        color: "var(--accent-active)",
        font: "var(--weight-semibold) var(--text-body)/1 var(--font-system)",
        cursor: "pointer",
        minWidth: 60,
        textAlign: "right"
      }
    }, saveLabel)), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        overflow: "auto",
        padding: "8px 16px 24px",
        display: "flex",
        flexDirection: "column",
        gap: 22
      }
    }, children));
  }

  /* ---------- Management menu (popover) ---------- */
  function ManagementMenu({
    onClose,
    onAction
  }) {
    const items = [{
      key: "add-routine",
      label: "Add Routine"
    }, {
      key: "add-group",
      label: "Add Group"
    }, {
      key: "edit",
      label: "Edit"
    }, {
      key: "rearrange-groups",
      label: "Rearrange Groups"
    }, {
      key: "rearrange-routines",
      label: "Rearrange Routines"
    }, {
      divider: true,
      key: "div"
    }, {
      key: "settings",
      label: "Week Starts On"
    }];
    return /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        inset: 0,
        zIndex: 80
      },
      onClick: onClose
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        inset: 0,
        background: "rgba(0,0,0,0.28)"
      }
    }), /*#__PURE__*/React.createElement("div", {
      onClick: e => e.stopPropagation(),
      style: {
        position: "absolute",
        top: 96,
        right: 14,
        width: 268,
        background: "color-mix(in srgb, var(--surface-sheet) 92%, transparent)",
        backdropFilter: "blur(20px)",
        WebkitBackdropFilter: "blur(20px)",
        borderRadius: 16,
        boxShadow: "var(--shadow-menu)",
        border: "1px solid var(--border-hairline-soft)",
        overflow: "hidden"
      }
    }, items.map(it => it.divider ? /*#__PURE__*/React.createElement("div", {
      key: it.key,
      style: {
        height: 1,
        background: "var(--border-hairline)"
      }
    }) : /*#__PURE__*/React.createElement("button", {
      key: it.key,
      type: "button",
      onClick: () => onAction(it.key),
      style: {
        appearance: "none",
        border: "none",
        background: "transparent",
        width: "100%",
        textAlign: "left",
        padding: "15px 18px",
        color: "var(--text-primary)",
        font: "var(--weight-regular) var(--text-title3)/1 var(--font-system)",
        cursor: "pointer"
      }
    }, it.label))));
  }

  /* ---------- Add / Edit Routine ---------- */
  function RoutineForm({
    groups,
    initial,
    onCancel,
    onSave,
    onDelete
  }) {
    const isEdit = !!initial;
    const [name, setName] = React.useState(initial ? initial.name : "");
    const [target, setTarget] = React.useState(initial ? initial.target : 3);
    const [period, setPeriod] = React.useState(initial ? initial.period : "week");
    const [groupId, setGroupId] = React.useState(initial ? initial.groupId : groups[0] ? groups[0].id : null);
    const [allDay, setAllDay] = React.useState(initial ? !initial.availability : true);
    const groupName = (groups.find(g => g.id === groupId) || {}).name || "Choose a group";
    const cycleGroup = () => {
      const idx = groups.findIndex(g => g.id === groupId);
      setGroupId(groups[(idx + 1) % groups.length].id);
    };
    return /*#__PURE__*/React.createElement(SheetShell, {
      title: isEdit ? "Edit Routine" : "Add Routine",
      saveLabel: isEdit ? "Save" : "Add",
      onCancel: onCancel,
      onSave: () => name.trim() && onSave({
        name: name.trim(),
        target,
        period,
        groupId
      })
    }, /*#__PURE__*/React.createElement(FormGroup, null, /*#__PURE__*/React.createElement(FormRow, null, /*#__PURE__*/React.createElement("input", {
      value: name,
      onChange: e => setName(e.target.value),
      placeholder: "Name",
      autoFocus: true,
      style: {
        flex: 1,
        appearance: "none",
        border: "none",
        outline: "none",
        background: "transparent",
        color: "var(--text-primary)",
        font: "var(--weight-regular) var(--text-body)/1 var(--font-system)"
      }
    })), /*#__PURE__*/React.createElement(FormRow, null, /*#__PURE__*/React.createElement("span", {
      style: labelStyle
    }, "Target"), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1
      }
    }), /*#__PURE__*/React.createElement(Stepper, {
      value: target,
      onDec: () => setTarget(t => Math.max(1, t - 1)),
      onInc: () => setTarget(t => t + 1)
    })), /*#__PURE__*/React.createElement(FormRow, null, /*#__PURE__*/React.createElement(Segmented, {
      value: period,
      onChange: setPeriod,
      options: [{
        value: "week",
        label: "Weekly"
      }, {
        value: "month",
        label: "Monthly"
      }]
    })), /*#__PURE__*/React.createElement(FormRow, {
      last: true
    }, /*#__PURE__*/React.createElement("span", {
      style: labelStyle
    }, "Group"), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1
      }
    }), /*#__PURE__*/React.createElement("button", {
      type: "button",
      onClick: cycleGroup,
      style: {
        appearance: "none",
        border: "none",
        background: "transparent",
        cursor: "pointer",
        display: "flex",
        alignItems: "center",
        gap: 6,
        color: "var(--accent-active)",
        font: "var(--weight-regular) var(--text-body)/1 var(--font-system)"
      }
    }, groupName, /*#__PURE__*/React.createElement(Icon, {
      name: "chevron-updown",
      size: 18
    })))), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 8
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--text-secondary)",
        font: "var(--weight-semibold) var(--text-footnote)/1 var(--font-system)",
        textTransform: "uppercase",
        letterSpacing: "0.04em",
        padding: "0 4px"
      }
    }, "Availability"), /*#__PURE__*/React.createElement(FormGroup, null, /*#__PURE__*/React.createElement(FormRow, {
      last: allDay
    }, /*#__PURE__*/React.createElement("span", {
      style: labelStyle
    }, "Available all day"), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1
      }
    }), /*#__PURE__*/React.createElement(Switch, {
      on: allDay,
      onToggle: () => setAllDay(v => !v)
    })), !allDay && /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(FormRow, null, /*#__PURE__*/React.createElement("span", {
      style: labelStyle
    }, "Start"), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1
      }
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--accent-active)",
        font: "var(--weight-regular) var(--text-body)/1 var(--font-system)",
        background: "var(--tint-active-soft)",
        padding: "6px 12px",
        borderRadius: 8
      }
    }, "9:00 AM")), /*#__PURE__*/React.createElement(FormRow, {
      last: true
    }, /*#__PURE__*/React.createElement("span", {
      style: labelStyle
    }, "End"), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1
      }
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--accent-active)",
        font: "var(--weight-regular) var(--text-body)/1 var(--font-system)",
        background: "var(--tint-active-soft)",
        padding: "6px 12px",
        borderRadius: 8
      }
    }, "5:00 PM"))))), isEdit && /*#__PURE__*/React.createElement(FormGroup, null, /*#__PURE__*/React.createElement(FormRow, {
      last: true
    }, /*#__PURE__*/React.createElement("button", {
      type: "button",
      onClick: onDelete,
      style: {
        appearance: "none",
        border: "none",
        background: "transparent",
        cursor: "pointer",
        color: "var(--accent-destructive)",
        font: "var(--weight-regular) var(--text-body)/1 var(--font-system)"
      }
    }, "Delete Routine"))));
  }

  /* ---------- Add / Edit Group ---------- */
  function GroupForm({
    initial,
    onCancel,
    onSave,
    onDelete
  }) {
    const isEdit = !!initial;
    const [name, setName] = React.useState(initial ? initial.name : "");
    return /*#__PURE__*/React.createElement(SheetShell, {
      title: isEdit ? "Rename Group" : "Add Group",
      saveLabel: isEdit ? "Save" : "Add",
      onCancel: onCancel,
      onSave: () => name.trim() && onSave({
        name: name.trim()
      })
    }, /*#__PURE__*/React.createElement(FormGroup, null, /*#__PURE__*/React.createElement(FormRow, {
      last: true
    }, /*#__PURE__*/React.createElement("input", {
      value: name,
      onChange: e => setName(e.target.value),
      placeholder: "Name",
      autoFocus: true,
      style: {
        flex: 1,
        appearance: "none",
        border: "none",
        outline: "none",
        background: "transparent",
        color: "var(--text-primary)",
        font: "var(--weight-regular) var(--text-body)/1 var(--font-system)"
      }
    }))), isEdit && /*#__PURE__*/React.createElement(FormGroup, null, /*#__PURE__*/React.createElement(FormRow, {
      last: true
    }, /*#__PURE__*/React.createElement("button", {
      type: "button",
      onClick: onDelete,
      style: {
        appearance: "none",
        border: "none",
        background: "transparent",
        cursor: "pointer",
        color: "var(--accent-destructive)",
        font: "var(--weight-regular) var(--text-body)/1 var(--font-system)"
      }
    }, "Delete Group"))));
  }

  /* ---------- Settings (week starts on) ---------- */
  function Settings({
    value,
    onChange,
    onClose
  }) {
    const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
    return /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        height: "100%",
        background: "var(--bg-canvas)"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        padding: "48px 16px 12px"
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1
      }
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--text-primary)",
        font: "var(--weight-semibold) var(--text-headline)/1 var(--font-system)"
      }
    }, "Week Starts On"), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1,
        display: "flex",
        justifyContent: "flex-end"
      }
    }, /*#__PURE__*/React.createElement("button", {
      type: "button",
      onClick: onClose,
      style: {
        appearance: "none",
        border: "none",
        background: "transparent",
        color: "var(--accent-active)",
        font: "var(--weight-semibold) var(--text-body)/1 var(--font-system)",
        cursor: "pointer"
      }
    }, "Done"))), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "8px 16px",
        display: "flex",
        flexDirection: "column",
        gap: 10
      }
    }, /*#__PURE__*/React.createElement(FormGroup, null, days.map((d, i) => /*#__PURE__*/React.createElement(FormRow, {
      key: d,
      last: i === days.length - 1
    }, /*#__PURE__*/React.createElement("button", {
      type: "button",
      onClick: () => onChange(d),
      style: {
        flex: 1,
        display: "flex",
        alignItems: "center",
        appearance: "none",
        border: "none",
        background: "transparent",
        cursor: "pointer",
        padding: 0
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: labelStyle
    }, d), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1
      }
    }), value === d && /*#__PURE__*/React.createElement(Icon, {
      name: "check",
      size: 20,
      color: "var(--accent-active)"
    }))))), /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--text-secondary)",
        font: "var(--weight-regular) var(--text-footnote)/1.4 var(--font-system)",
        padding: "2px 8px"
      }
    }, "Controls when your weekly routine progress resets.")));
  }

  /* ---------- Rearrange (groups or routines) ---------- */
  function RearrangeView({
    kind,
    data,
    onDone
  }) {
    const rows = kind === "groups" ? data.groups.map(g => ({
      id: g.id,
      name: g.name
    })) : data.groups.flatMap(g => g.routineIds.map(rid => data.routines.find(r => r.id === rid)).filter(Boolean).map(r => ({
      id: r.id,
      name: r.name,
      group: g.name,
      summary: `${r.target} per ${r.period === "month" ? "month" : "week"}`
    })));
    let lastGroup = null;
    return /*#__PURE__*/React.createElement("div", {
      style: {
        minHeight: "100%",
        background: "var(--bg-canvas)"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        padding: "8px 16px 12px",
        paddingTop: 14
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--text-primary)",
        font: "var(--weight-semibold) var(--text-title)/var(--leading-title) var(--font-system)"
      }
    }, kind === "groups" ? "Rearrange Groups" : "Rearrange Routines"), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1
      }
    }), /*#__PURE__*/React.createElement("button", {
      type: "button",
      onClick: onDone,
      style: {
        appearance: "none",
        border: "none",
        background: "transparent",
        color: "var(--accent-active)",
        font: "var(--weight-semibold) var(--text-body)/1 var(--font-system)",
        cursor: "pointer",
        minHeight: 44
      }
    }, "Done")), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "0 16px",
        display: "flex",
        flexDirection: "column",
        gap: 14
      }
    }, rows.map(row => {
      const showHeader = kind === "routines" && row.group !== lastGroup;
      lastGroup = row.group;
      return /*#__PURE__*/React.createElement(React.Fragment, {
        key: row.id
      }, showHeader && /*#__PURE__*/React.createElement("span", {
        style: {
          color: "var(--text-secondary)",
          font: "var(--weight-semibold) var(--text-subheadline)/1 var(--font-system)",
          marginTop: 8
        }
      }, row.group), /*#__PURE__*/React.createElement("div", {
        style: {
          display: "flex",
          alignItems: "center",
          gap: 12,
          padding: "14px",
          background: "var(--surface-sheet)",
          borderRadius: "var(--radius-row)",
          boxShadow: "inset 0 0 0 1px var(--border-hairline-soft)"
        }
      }, /*#__PURE__*/React.createElement("div", {
        style: {
          display: "flex",
          flexDirection: "column",
          gap: 4,
          flex: 1,
          minWidth: 0
        }
      }, /*#__PURE__*/React.createElement("span", {
        style: {
          color: "var(--text-primary)",
          font: "var(--weight-regular) var(--text-body)/1 var(--font-system)"
        }
      }, row.name), row.summary && /*#__PURE__*/React.createElement("span", {
        style: {
          color: "var(--text-secondary)",
          font: "var(--weight-regular) var(--text-subheadline)/1 var(--font-system)"
        }
      }, row.summary)), /*#__PURE__*/React.createElement(Icon, {
        name: "reorder",
        size: 22,
        color: "var(--text-secondary)"
      })));
    })));
  }
  Object.assign(window, {
    ManagementMenu,
    RoutineForm,
    GroupForm,
    Settings,
    RearrangeView
  });
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/routine_app/Forms.jsx", error: String((e && e.message) || e) }); }

// ui_kits/routine_app/History.jsx
try { (() => {
/* Routine UI kit — Routine History */
(function () {
  const NS = window.RoutineDesignSystem_14e910;
  const {
    ProgressRing,
    Button,
    IconButton
  } = NS;
  const MONTH_ABBR = "Jun";
  function freqSummary(r) {
    return `${r.target} per ${r.period === "month" ? "month" : "week"}`;
  }
  function periodProgress(r) {
    return `${r.completed}/${r.target} this ${r.period === "month" ? "month" : "week"}`;
  }
  function lastDoneDisplay(r) {
    if (r.lastDone === "Today") return "Done today";
    if (r.lastDone === "Yesterday") return "Last done yesterday";
    if (!r.lastDone || r.lastDone === "Never") return "No completions yet";
    return `Last done ${r.lastDone}`;
  }
  function relativeFor(day) {
    if (day === 10) return "Today";
    if (day === 9) return "Yesterday";
    return null;
  }
  function NavHeader({
    title,
    onBack
  }) {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        position: "relative",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: "8px 8px 4px",
        minHeight: 48
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        left: 8
      }
    }, /*#__PURE__*/React.createElement(IconButton, {
      icon: "chevron-left",
      label: "Back",
      tone: "primary",
      onClick: onBack
    })), /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--text-primary)",
        font: "var(--weight-semibold) var(--text-headline)/1 var(--font-system)"
      }
    }, title));
  }
  function SummaryCard({
    r
  }) {
    const accent = r.state === "complete" || r.state === "target-met" ? "complete" : "active";
    return /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        gap: 16,
        padding: 16,
        background: "var(--surface-sheet)",
        borderRadius: "var(--radius-card)",
        boxShadow: "inset 0 0 0 1px var(--border-hairline-soft)"
      }
    }, /*#__PURE__*/React.createElement(ProgressRing, {
      completed: r.completed,
      target: r.target,
      showCheckmark: r.state === "complete",
      accent: accent,
      size: 72,
      strokeWidth: 7
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 6,
        minWidth: 0
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--text-primary)",
        font: "var(--weight-semibold) var(--text-title3)/var(--leading-title3) var(--font-system)"
      }
    }, r.name), /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--text-secondary)",
        font: "var(--weight-semibold) var(--text-subheadline)/1 var(--font-system)"
      }
    }, freqSummary(r)), /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--text-primary)",
        font: "var(--weight-semibold) var(--text-headline)/1 var(--font-system)"
      }
    }, periodProgress(r)), /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--text-secondary)",
        font: "var(--weight-regular) var(--text-body)/1.2 var(--font-system)"
      }
    }, lastDoneDisplay(r))));
  }
  function MonthGrid({
    r,
    data
  }) {
    const done = new Set(r.completions);
    const cells = [];
    for (let i = 0; i < data.firstWeekdayIndex; i++) cells.push(/*#__PURE__*/React.createElement("div", {
      key: `p${i}`
    }));
    for (let d = 1; d <= data.daysInMonth; d++) {
      const isToday = d === data.today.day;
      const isDone = done.has(d);
      cells.push(/*#__PURE__*/React.createElement("div", {
        key: d,
        style: {
          position: "relative",
          height: 36,
          display: "grid",
          placeItems: "center"
        }
      }, isDone && /*#__PURE__*/React.createElement("span", {
        style: {
          position: "absolute",
          width: 32,
          height: 32,
          borderRadius: "50%",
          background: "var(--calendar-day-complete)"
        }
      }), isToday && /*#__PURE__*/React.createElement("span", {
        style: {
          position: "absolute",
          width: 32,
          height: 32,
          borderRadius: "50%",
          boxShadow: "inset 0 0 0 2px var(--accent-active)"
        }
      }), /*#__PURE__*/React.createElement("span", {
        style: {
          position: "relative",
          color: isDone ? "var(--text-primary)" : "var(--text-secondary)",
          font: `${isToday ? "var(--weight-semibold)" : "var(--weight-regular)"} var(--text-subheadline)/1 var(--font-system)`
        }
      }, d)));
    }
    return /*#__PURE__*/React.createElement("div", {
      style: {
        padding: 16,
        background: "var(--surface-card)",
        borderRadius: "var(--radius-card)",
        boxShadow: "inset 0 0 0 1px var(--border-hairline-soft)",
        display: "flex",
        flexDirection: "column",
        gap: 16
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--text-primary)",
        font: "var(--weight-semibold) var(--text-headline)/1 var(--font-system)"
      }
    }, data.monthTitle), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "grid",
        gridTemplateColumns: "repeat(7,1fr)",
        gap: 8
      }
    }, data.weekdaySymbols.map(s => /*#__PURE__*/React.createElement("div", {
      key: s,
      style: {
        textAlign: "center",
        color: "var(--text-secondary)",
        font: "var(--weight-semibold) var(--text-caption)/1 var(--font-system)"
      }
    }, s)), cells));
  }
  function CompletionRow({
    day,
    onRemove
  }) {
    const rel = relativeFor(day);
    return /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        gap: 12,
        padding: 14,
        background: "var(--surface-sheet)",
        borderRadius: "var(--radius-row)",
        boxShadow: "inset 0 0 0 1px var(--border-hairline-soft)"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 4,
        flex: 1,
        minWidth: 0
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--text-primary)",
        font: "var(--weight-semibold) var(--text-body)/1 var(--font-system)"
      }
    }, MONTH_ABBR, " ", day, ", 2026"), rel && /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--text-secondary)",
        font: "var(--weight-regular) var(--text-caption)/1 var(--font-system)"
      }
    }, rel)), /*#__PURE__*/React.createElement(Button, {
      variant: "bordered",
      tone: "destructive",
      size: "sm",
      onClick: () => onRemove(day)
    }, /*#__PURE__*/React.createElement(NS.Icon, {
      name: "trash",
      size: 16
    }), " Remove"));
  }
  function History({
    routine,
    data,
    onBack,
    onRemove
  }) {
    const recent = [...routine.completions].sort((a, b) => b - a);
    return /*#__PURE__*/React.createElement("div", {
      style: {
        minHeight: "100%",
        background: "var(--bg-canvas)",
        paddingBottom: 28
      }
    }, /*#__PURE__*/React.createElement(NavHeader, {
      title: "History",
      onBack: onBack
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "12px 16px 0",
        display: "flex",
        flexDirection: "column",
        gap: 24
      }
    }, /*#__PURE__*/React.createElement(SummaryCard, {
      r: routine
    }), /*#__PURE__*/React.createElement(MonthGrid, {
      r: routine,
      data: data
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 12
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--text-primary)",
        font: "var(--weight-semibold) var(--text-headline)/1 var(--font-system)"
      }
    }, "Recent completions"), recent.length === 0 ? /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--text-secondary)",
        font: "var(--weight-regular) var(--text-body)/1 var(--font-system)",
        padding: "8px 0"
      }
    }, "No recent completions") : recent.map(d => /*#__PURE__*/React.createElement(CompletionRow, {
      key: d,
      day: d,
      onRemove: onRemove
    })))));
  }
  window.History = History;
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/routine_app/History.jsx", error: String((e && e.message) || e) }); }

// ui_kits/routine_app/app.jsx
try { (() => {
/* Routine UI kit — interactive controller */
(function () {
  const {
    useState,
    useRef,
    useCallback
  } = React;
  function clone(data) {
    return {
      ...data,
      routines: data.routines.map(r => ({
        ...r,
        completions: [...r.completions]
      })),
      groups: data.groups.map(g => ({
        ...g,
        routineIds: [...g.routineIds]
      }))
    };
  }
  function RoutineAppKit() {
    const [theme, setTheme] = useState("dark");
    const [data, setData] = useState(() => clone(window.ROUTINE_DATA));
    const [route, setRoute] = useState("dashboard"); // dashboard | history | rearrange-groups | rearrange-routines
    const [mode, setMode] = useState("tracking"); // tracking | edit
    const [sheet, setSheet] = useState(null); // add-routine | edit-routine | add-group | edit-group | settings
    const [menuOpen, setMenuOpen] = useState(false);
    const [historyId, setHistoryId] = useState(null);
    const [editRoutineId, setEditRoutineId] = useState(null);
    const [editGroupId, setEditGroupId] = useState(null);
    const [weekStart, setWeekStart] = useState("Sunday");
    const [undo, setUndo] = useState(null); // { name, snapshot }
    const undoTimer = useRef(null);
    const addCounter = useRef(0);
    const dark = theme === "dark";
    const byId = id => data.routines.find(r => r.id === id);
    const showUndo = useCallback((name, snapshot) => {
      setUndo({
        name,
        snapshot
      });
      if (undoTimer.current) clearTimeout(undoTimer.current);
      undoTimer.current = setTimeout(() => setUndo(null), 4200);
    }, []);
    const handleComplete = id => {
      const r = byId(id);
      if (!r) return;
      if (r.state === "complete" || r.state === "target-met" || r.state === "over-target") {
        // already done today / met → open history instead of double-completing
        setHistoryId(id);
        setRoute("history");
        return;
      }
      const snapshot = clone(data);
      setData(prev => {
        const next = clone(prev);
        const t = next.routines.find(x => x.id === id);
        t.completed += 1;
        t.lastDone = "Today";
        if (!t.completions.includes(prev.today.day)) t.completions.push(prev.today.day);
        t.state = "complete";
        return next;
      });
      showUndo(`Completed ${r.name}`, snapshot);
    };
    const handleUndo = () => {
      if (undo) setData(undo.snapshot);
      setUndo(null);
      if (undoTimer.current) clearTimeout(undoTimer.current);
    };
    const openHistory = id => {
      setHistoryId(id);
      setRoute("history");
    };
    const handleMenu = key => {
      setMenuOpen(false);
      if (key === "add-routine") setSheet("add-routine");else if (key === "add-group") setSheet("add-group");else if (key === "edit") setMode("edit");else if (key === "rearrange-groups") setRoute("rearrange-groups");else if (key === "rearrange-routines") setRoute("rearrange-routines");else if (key === "settings") setSheet("settings");
    };
    const addRoutine = draft => {
      setData(prev => {
        const next = clone(prev);
        addCounter.current += 1;
        const id = `new-${addCounter.current}`;
        next.routines.push({
          id,
          name: draft.name,
          period: draft.period,
          target: draft.target,
          completed: 0,
          lastDone: "Never",
          state: "incomplete",
          availability: null,
          completions: []
        });
        const g = next.groups.find(x => x.id === draft.groupId) || next.groups[0];
        g.routineIds.push(id);
        return next;
      });
      setSheet(null);
    };
    const saveRoutineEdit = draft => {
      setData(prev => {
        const next = clone(prev);
        const r = next.routines.find(x => x.id === editRoutineId);
        if (r) {
          r.name = draft.name;
          r.target = draft.target;
          r.period = draft.period;
        }
        // move group if changed
        if (draft.groupId) {
          next.groups.forEach(g => {
            g.routineIds = g.routineIds.filter(rid => rid !== editRoutineId);
          });
          const g = next.groups.find(x => x.id === draft.groupId) || next.groups[0];
          g.routineIds.push(editRoutineId);
        }
        return next;
      });
      setSheet(null);
    };
    const deleteRoutine = () => {
      setData(prev => {
        const next = clone(prev);
        next.routines = next.routines.filter(x => x.id !== editRoutineId);
        next.groups.forEach(g => g.routineIds = g.routineIds.filter(rid => rid !== editRoutineId));
        return next;
      });
      setSheet(null);
    };
    const addGroup = draft => {
      setData(prev => {
        const next = clone(prev);
        next.groups.push({
          id: `g-${Date.now()}`,
          name: draft.name,
          routineIds: []
        });
        return next;
      });
      setSheet(null);
    };
    const saveGroupEdit = draft => {
      setData(prev => {
        const next = clone(prev);
        const g = next.groups.find(x => x.id === editGroupId);
        if (g) g.name = draft.name;
        return next;
      });
      setSheet(null);
    };
    const deleteGroup = () => {
      setData(prev => {
        const next = clone(prev);
        next.groups = next.groups.filter(x => x.id !== editGroupId);
        return next;
      });
      setSheet(null);
    };
    const removeCompletion = day => {
      setData(prev => {
        const next = clone(prev);
        const r = next.routines.find(x => x.id === historyId);
        if (r) {
          r.completions = r.completions.filter(d => d !== day);
          r.completed = Math.max(0, r.completed - 1);
          if (day === prev.today.day) {
            r.lastDone = r.completions.length ? "Yesterday" : "Never";
            r.state = r.completed >= r.target ? "target-met" : "incomplete";
          }
        }
        return next;
      });
    };

    // editingInitial for routine edit sheet
    const editInitial = (() => {
      if (sheet !== "edit-routine") return null;
      const r = byId(editRoutineId);
      if (!r) return null;
      const g = data.groups.find(x => x.routineIds.includes(r.id));
      return {
        name: r.name,
        target: r.target,
        period: r.period,
        groupId: g ? g.id : null
      };
    })();
    const editGroupInitial = (() => {
      if (sheet !== "edit-group") return null;
      const g = data.groups.find(x => x.id === editGroupId);
      return g ? {
        name: g.name
      } : null;
    })();
    const historyRoutine = route === "history" ? byId(historyId) : null;
    return /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 18
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        gap: 4,
        padding: 3,
        background: "rgba(120,120,128,0.16)",
        borderRadius: 999
      }
    }, ["dark", "light"].map(t => /*#__PURE__*/React.createElement("button", {
      key: t,
      type: "button",
      onClick: () => setTheme(t),
      style: {
        appearance: "none",
        border: "none",
        cursor: "pointer",
        borderRadius: 999,
        padding: "6px 16px",
        fontFamily: '-apple-system, system-ui, sans-serif',
        fontSize: 13,
        fontWeight: 600,
        textTransform: "capitalize",
        background: theme === t ? "#fff" : "transparent",
        color: theme === t ? "#1a1a1a" : "#8a8a8a",
        boxShadow: theme === t ? "0 1px 3px rgba(0,0,0,.2)" : "none"
      }
    }, t))), /*#__PURE__*/React.createElement(IOSDevice, {
      dark: dark
    }, /*#__PURE__*/React.createElement("div", {
      "data-theme": dark ? "dark" : "light",
      style: {
        position: "relative",
        minHeight: "100%",
        background: "var(--bg-canvas)"
      }
    }, route === "dashboard" && /*#__PURE__*/React.createElement("div", {
      style: {
        paddingTop: 44
      }
    }, /*#__PURE__*/React.createElement(window.Dashboard, {
      data: data,
      mode: mode,
      onComplete: handleComplete,
      onHistory: openHistory,
      onEditRoutine: id => {
        setEditRoutineId(id);
        setSheet("edit-routine");
      },
      onEditGroup: id => {
        setEditGroupId(id);
        setSheet("edit-group");
      },
      onGear: () => setMenuOpen(true),
      onDoneEditing: () => setMode("tracking")
    })), route === "history" && historyRoutine && /*#__PURE__*/React.createElement("div", {
      style: {
        paddingTop: 44
      }
    }, /*#__PURE__*/React.createElement(window.History, {
      routine: historyRoutine,
      data: data,
      onBack: () => setRoute("dashboard"),
      onRemove: removeCompletion
    })), (route === "rearrange-groups" || route === "rearrange-routines") && /*#__PURE__*/React.createElement("div", {
      style: {
        paddingTop: 44
      }
    }, /*#__PURE__*/React.createElement(window.RearrangeView, {
      kind: route === "rearrange-groups" ? "groups" : "routines",
      data: data,
      onDone: () => setRoute("dashboard")
    })), undo && route === "dashboard" && /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        left: 16,
        right: 16,
        bottom: 28,
        zIndex: 70
      }
    }, /*#__PURE__*/React.createElement(window.RoutineDesignSystem_14e910.UndoBanner, {
      message: undo.name,
      onUndo: handleUndo
    })), menuOpen && /*#__PURE__*/React.createElement(window.ManagementMenu, {
      onClose: () => setMenuOpen(false),
      onAction: handleMenu
    }), sheet && /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        inset: 0,
        zIndex: 90
      }
    }, sheet === "add-routine" && /*#__PURE__*/React.createElement(window.RoutineForm, {
      groups: data.groups,
      onCancel: () => setSheet(null),
      onSave: addRoutine
    }), sheet === "edit-routine" && editInitial && /*#__PURE__*/React.createElement(window.RoutineForm, {
      groups: data.groups,
      initial: editInitial,
      onCancel: () => setSheet(null),
      onSave: saveRoutineEdit,
      onDelete: deleteRoutine
    }), sheet === "add-group" && /*#__PURE__*/React.createElement(window.GroupForm, {
      onCancel: () => setSheet(null),
      onSave: addGroup
    }), sheet === "edit-group" && editGroupInitial && /*#__PURE__*/React.createElement(window.GroupForm, {
      initial: editGroupInitial,
      onCancel: () => setSheet(null),
      onSave: saveGroupEdit,
      onDelete: deleteGroup
    }), sheet === "settings" && /*#__PURE__*/React.createElement(window.Settings, {
      value: weekStart,
      onChange: setWeekStart,
      onClose: () => setSheet(null)
    })))));
  }
  window.RoutineAppKit = RoutineAppKit;
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/routine_app/app.jsx", error: String((e && e.message) || e) }); }

// ui_kits/routine_app/ios-frame.jsx
try { (() => {
// @ds-adherence-ignore -- omelette starter scaffold (raw elements/hex/px by design)

/* BEGIN USAGE */
// iOS.jsx — Simplified iOS 26 (Liquid Glass) device frame
// Based on the iOS 26 UI Kit + Figma status bar spec. No assets, no deps.
// Exports (to window): IOSDevice, IOSStatusBar, IOSNavBar, IOSGlassPill, IOSList, IOSListRow, IOSKeyboard
//
// Usage — wrap your screen content in <IOSDevice> to get the bezel, status bar
// and home indicator (props: title, dark, keyboard):
//
//   <IOSDevice title="Settings">
//     ...your screen content...
//   </IOSDevice>
//   <IOSDevice dark title="Search" keyboard>…</IOSDevice>
/* END USAGE */

// ─────────────────────────────────────────────────────────────
// Status bar
// ─────────────────────────────────────────────────────────────
function IOSStatusBar({
  dark = false,
  time = '9:41'
}) {
  const c = dark ? '#fff' : '#000';
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 154,
      alignItems: 'center',
      justifyContent: 'center',
      padding: '21px 24px 19px',
      boxSizing: 'border-box',
      position: 'relative',
      zIndex: 20,
      width: '100%'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      height: 22,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      paddingTop: 1.5
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontWeight: 590,
      fontSize: 17,
      lineHeight: '22px',
      color: c
    }
  }, time)), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      height: 22,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 7,
      paddingTop: 1,
      paddingRight: 1
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: "19",
    height: "12",
    viewBox: "0 0 19 12"
  }, /*#__PURE__*/React.createElement("rect", {
    x: "0",
    y: "7.5",
    width: "3.2",
    height: "4.5",
    rx: "0.7",
    fill: c
  }), /*#__PURE__*/React.createElement("rect", {
    x: "4.8",
    y: "5",
    width: "3.2",
    height: "7",
    rx: "0.7",
    fill: c
  }), /*#__PURE__*/React.createElement("rect", {
    x: "9.6",
    y: "2.5",
    width: "3.2",
    height: "9.5",
    rx: "0.7",
    fill: c
  }), /*#__PURE__*/React.createElement("rect", {
    x: "14.4",
    y: "0",
    width: "3.2",
    height: "12",
    rx: "0.7",
    fill: c
  })), /*#__PURE__*/React.createElement("svg", {
    width: "17",
    height: "12",
    viewBox: "0 0 17 12"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M8.5 3.2C10.8 3.2 12.9 4.1 14.4 5.6L15.5 4.5C13.7 2.7 11.2 1.5 8.5 1.5C5.8 1.5 3.3 2.7 1.5 4.5L2.6 5.6C4.1 4.1 6.2 3.2 8.5 3.2Z",
    fill: c
  }), /*#__PURE__*/React.createElement("path", {
    d: "M8.5 6.8C9.9 6.8 11.1 7.3 12 8.2L13.1 7.1C11.8 5.9 10.2 5.1 8.5 5.1C6.8 5.1 5.2 5.9 3.9 7.1L5 8.2C5.9 7.3 7.1 6.8 8.5 6.8Z",
    fill: c
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "8.5",
    cy: "10.5",
    r: "1.5",
    fill: c
  })), /*#__PURE__*/React.createElement("svg", {
    width: "27",
    height: "13",
    viewBox: "0 0 27 13"
  }, /*#__PURE__*/React.createElement("rect", {
    x: "0.5",
    y: "0.5",
    width: "23",
    height: "12",
    rx: "3.5",
    stroke: c,
    strokeOpacity: "0.35",
    fill: "none"
  }), /*#__PURE__*/React.createElement("rect", {
    x: "2",
    y: "2",
    width: "20",
    height: "9",
    rx: "2",
    fill: c
  }), /*#__PURE__*/React.createElement("path", {
    d: "M25 4.5V8.5C25.8 8.2 26.5 7.2 26.5 6.5C26.5 5.8 25.8 4.8 25 4.5Z",
    fill: c,
    fillOpacity: "0.4"
  }))));
}

// ─────────────────────────────────────────────────────────────
// Liquid glass pill — blur + tint + shine
// ─────────────────────────────────────────────────────────────
function IOSGlassPill({
  children,
  dark = false,
  style = {}
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: 44,
      minWidth: 44,
      borderRadius: 9999,
      position: 'relative',
      overflow: 'hidden',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      boxShadow: dark ? '0 2px 6px rgba(0,0,0,0.35), 0 6px 16px rgba(0,0,0,0.2)' : '0 1px 3px rgba(0,0,0,0.07), 0 3px 10px rgba(0,0,0,0.06)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: 9999,
      backdropFilter: 'blur(12px) saturate(180%)',
      WebkitBackdropFilter: 'blur(12px) saturate(180%)',
      background: dark ? 'rgba(120,120,128,0.28)' : 'rgba(255,255,255,0.5)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: 9999,
      boxShadow: dark ? 'inset 1.5px 1.5px 1px rgba(255,255,255,0.15), inset -1px -1px 1px rgba(255,255,255,0.08)' : 'inset 1.5px 1.5px 1px rgba(255,255,255,0.7), inset -1px -1px 1px rgba(255,255,255,0.4)',
      border: dark ? '0.5px solid rgba(255,255,255,0.15)' : '0.5px solid rgba(0,0,0,0.06)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 1,
      display: 'flex',
      alignItems: 'center',
      padding: '0 4px'
    }
  }, children));
}

// ─────────────────────────────────────────────────────────────
// Navigation bar — glass pills + large title
// ─────────────────────────────────────────────────────────────
function IOSNavBar({
  title = 'Title',
  dark = false,
  trailingIcon = true
}) {
  const muted = dark ? 'rgba(255,255,255,0.6)' : '#404040';
  const text = dark ? '#fff' : '#000';
  const pillIcon = content => /*#__PURE__*/React.createElement(IOSGlassPill, {
    dark: dark
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 36,
      height: 36,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, content));
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 10,
      paddingTop: 62,
      paddingBottom: 10,
      position: 'relative',
      zIndex: 5
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '0 16px'
    }
  }, pillIcon(/*#__PURE__*/React.createElement("svg", {
    width: "12",
    height: "20",
    viewBox: "0 0 12 20",
    fill: "none",
    style: {
      marginLeft: -1
    }
  }, /*#__PURE__*/React.createElement("path", {
    d: "M10 2L2 10l8 8",
    stroke: muted,
    strokeWidth: "2.5",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  }))), trailingIcon && pillIcon(/*#__PURE__*/React.createElement("svg", {
    width: "22",
    height: "6",
    viewBox: "0 0 22 6"
  }, /*#__PURE__*/React.createElement("circle", {
    cx: "3",
    cy: "3",
    r: "2.5",
    fill: muted
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "11",
    cy: "3",
    r: "2.5",
    fill: muted
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "19",
    cy: "3",
    r: "2.5",
    fill: muted
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '0 16px',
      fontFamily: '-apple-system, system-ui',
      fontSize: 34,
      fontWeight: 700,
      lineHeight: '41px',
      color: text,
      letterSpacing: 0.4
    }
  }, title));
}

// ─────────────────────────────────────────────────────────────
// Grouped list (inset card, r:26) + row (52px)
// ─────────────────────────────────────────────────────────────
function IOSListRow({
  title,
  detail,
  icon,
  chevron = true,
  isLast = false,
  dark = false
}) {
  const text = dark ? '#fff' : '#000';
  const sec = dark ? 'rgba(235,235,245,0.6)' : 'rgba(60,60,67,0.6)';
  const ter = dark ? 'rgba(235,235,245,0.3)' : 'rgba(60,60,67,0.3)';
  const sep = dark ? 'rgba(84,84,88,0.65)' : 'rgba(60,60,67,0.12)';
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      minHeight: 52,
      padding: '0 16px',
      position: 'relative',
      fontFamily: '-apple-system, system-ui',
      fontSize: 17,
      letterSpacing: -0.43
    }
  }, icon && /*#__PURE__*/React.createElement("div", {
    style: {
      width: 30,
      height: 30,
      borderRadius: 7,
      background: icon,
      marginRight: 12,
      flexShrink: 0
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      color: text
    }
  }, title), detail && /*#__PURE__*/React.createElement("span", {
    style: {
      color: sec,
      marginRight: 6
    }
  }, detail), chevron && /*#__PURE__*/React.createElement("svg", {
    width: "8",
    height: "14",
    viewBox: "0 0 8 14",
    style: {
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("path", {
    d: "M1 1l6 6-6 6",
    stroke: ter,
    strokeWidth: "2",
    fill: "none",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  })), !isLast && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      bottom: 0,
      right: 0,
      left: icon ? 58 : 16,
      height: 0.5,
      background: sep
    }
  }));
}
function IOSList({
  header,
  children,
  dark = false
}) {
  const hc = dark ? 'rgba(235,235,245,0.6)' : 'rgba(60,60,67,0.6)';
  const bg = dark ? '#1C1C1E' : '#fff';
  return /*#__PURE__*/React.createElement("div", null, header && /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: '-apple-system, system-ui',
      fontSize: 13,
      color: hc,
      textTransform: 'uppercase',
      padding: '8px 36px 6px',
      letterSpacing: -0.08
    }
  }, header), /*#__PURE__*/React.createElement("div", {
    style: {
      background: bg,
      borderRadius: 26,
      margin: '0 16px',
      overflow: 'hidden'
    }
  }, children));
}

// ─────────────────────────────────────────────────────────────
// Device frame
// ─────────────────────────────────────────────────────────────
function IOSDevice({
  children,
  width = 402,
  height = 874,
  dark = false,
  title,
  keyboard = false
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      width,
      height,
      borderRadius: 48,
      overflow: 'hidden',
      position: 'relative',
      background: dark ? '#000' : '#F2F2F7',
      boxShadow: '0 40px 80px rgba(0,0,0,0.18), 0 0 0 1px rgba(0,0,0,0.12)',
      fontFamily: '-apple-system, system-ui, sans-serif',
      WebkitFontSmoothing: 'antialiased'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: 11,
      left: '50%',
      transform: 'translateX(-50%)',
      width: 126,
      height: 37,
      borderRadius: 24,
      background: '#000',
      zIndex: 50
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      zIndex: 10
    }
  }, /*#__PURE__*/React.createElement(IOSStatusBar, {
    dark: dark
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      height: '100%',
      display: 'flex',
      flexDirection: 'column'
    }
  }, title !== undefined && /*#__PURE__*/React.createElement(IOSNavBar, {
    title: title,
    dark: dark
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflow: 'auto'
    }
  }, children), keyboard && /*#__PURE__*/React.createElement(IOSKeyboard, {
    dark: dark
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      bottom: 0,
      left: 0,
      right: 0,
      zIndex: 60,
      height: 34,
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'flex-end',
      paddingBottom: 8,
      pointerEvents: 'none'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 139,
      height: 5,
      borderRadius: 100,
      background: dark ? 'rgba(255,255,255,0.7)' : 'rgba(0,0,0,0.25)'
    }
  })));
}

// ─────────────────────────────────────────────────────────────
// Keyboard — iOS 26 liquid glass
// ─────────────────────────────────────────────────────────────
function IOSKeyboard({
  dark = false
}) {
  const glyph = dark ? 'rgba(255,255,255,0.7)' : '#595959';
  const sugg = dark ? 'rgba(255,255,255,0.6)' : '#333';
  const keyBg = dark ? 'rgba(255,255,255,0.22)' : 'rgba(255,255,255,0.85)';

  // special-key icons
  const icons = {
    shift: /*#__PURE__*/React.createElement("svg", {
      width: "19",
      height: "17",
      viewBox: "0 0 19 17"
    }, /*#__PURE__*/React.createElement("path", {
      d: "M9.5 1L1 9.5h4.5V16h8V9.5H18L9.5 1z",
      fill: glyph
    })),
    del: /*#__PURE__*/React.createElement("svg", {
      width: "23",
      height: "17",
      viewBox: "0 0 23 17"
    }, /*#__PURE__*/React.createElement("path", {
      d: "M7 1h13a2 2 0 012 2v11a2 2 0 01-2 2H7l-6-7.5L7 1z",
      fill: "none",
      stroke: glyph,
      strokeWidth: "1.6",
      strokeLinejoin: "round"
    }), /*#__PURE__*/React.createElement("path", {
      d: "M10 5l7 7M17 5l-7 7",
      stroke: glyph,
      strokeWidth: "1.6",
      strokeLinecap: "round"
    })),
    ret: /*#__PURE__*/React.createElement("svg", {
      width: "20",
      height: "14",
      viewBox: "0 0 20 14"
    }, /*#__PURE__*/React.createElement("path", {
      d: "M18 1v6H4m0 0l4-4M4 7l4 4",
      fill: "none",
      stroke: "#fff",
      strokeWidth: "1.8",
      strokeLinecap: "round",
      strokeLinejoin: "round"
    }))
  };
  const key = (content, {
    w,
    flex,
    ret,
    fs = 25,
    k
  } = {}) => /*#__PURE__*/React.createElement("div", {
    key: k,
    style: {
      height: 42,
      borderRadius: 8.5,
      flex: flex ? 1 : undefined,
      width: w,
      minWidth: 0,
      background: ret ? '#08f' : keyBg,
      boxShadow: '0 1px 0 rgba(0,0,0,0.075)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: '-apple-system, "SF Compact", system-ui',
      fontSize: fs,
      fontWeight: 458,
      color: ret ? '#fff' : glyph
    }
  }, content);
  const row = (keys, pad = 0) => /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6.5,
      justifyContent: 'center',
      padding: `0 ${pad}px`
    }
  }, keys.map(l => key(l, {
    flex: true,
    k: l
  })));
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 15,
      borderRadius: 27,
      overflow: 'hidden',
      padding: '11px 0 2px',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      boxShadow: dark ? '0 -2px 20px rgba(0,0,0,0.09)' : '0 -1px 6px rgba(0,0,0,0.018), 0 -3px 20px rgba(0,0,0,0.012)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: 27,
      backdropFilter: 'blur(12px) saturate(180%)',
      WebkitBackdropFilter: 'blur(12px) saturate(180%)',
      background: dark ? 'rgba(120,120,128,0.14)' : 'rgba(255,255,255,0.25)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: 27,
      boxShadow: dark ? 'inset 1.5px 1.5px 1px rgba(255,255,255,0.15)' : 'inset 1.5px 1.5px 1px rgba(255,255,255,0.7), inset -1px -1px 1px rgba(255,255,255,0.4)',
      border: dark ? '0.5px solid rgba(255,255,255,0.15)' : '0.5px solid rgba(0,0,0,0.06)',
      pointerEvents: 'none'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 20,
      alignItems: 'center',
      padding: '8px 22px 13px',
      width: '100%',
      boxSizing: 'border-box',
      position: 'relative'
    }
  }, ['"The"', 'the', 'to'].map((w, i) => /*#__PURE__*/React.createElement(React.Fragment, {
    key: i
  }, i > 0 && /*#__PURE__*/React.createElement("div", {
    style: {
      width: 1,
      height: 25,
      background: '#ccc',
      opacity: 0.3
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      textAlign: 'center',
      fontFamily: '-apple-system, system-ui',
      fontSize: 17,
      color: sugg,
      letterSpacing: -0.43,
      lineHeight: '22px'
    }
  }, w)))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 13,
      padding: '0 6.5px',
      width: '100%',
      boxSizing: 'border-box',
      position: 'relative'
    }
  }, row(['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p']), row(['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'], 20), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 14.25,
      alignItems: 'center'
    }
  }, key(icons.shift, {
    w: 45,
    k: 'shift'
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6.5,
      flex: 1
    }
  }, ['z', 'x', 'c', 'v', 'b', 'n', 'm'].map(l => key(l, {
    flex: true,
    k: l
  }))), key(icons.del, {
    w: 45,
    k: 'del'
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6,
      alignItems: 'center'
    }
  }, key('ABC', {
    w: 92.25,
    fs: 18,
    k: 'abc'
  }), key('', {
    flex: true,
    k: 'space'
  }), key(icons.ret, {
    w: 92.25,
    ret: true,
    k: 'ret'
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 56,
      width: '100%',
      position: 'relative'
    }
  }));
}
Object.assign(window, {
  IOSDevice,
  IOSStatusBar,
  IOSNavBar,
  IOSGlassPill,
  IOSList,
  IOSListRow,
  IOSKeyboard
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/routine_app/ios-frame.jsx", error: String((e && e.message) || e) }); }

// ui_kits/routine_app/routine-data.js
try { (() => {
/* Routine — UI-kit seed data.
   Mirrors the dogfooding starter dataset and the captured screenshots.
   Fixed "today" = Wednesday, June 10, 2026 (week starts Sunday). Plain JS. */
(function () {
  const completionsFor = days => days; // day-of-month numbers, June 2026

  const ROUTINES = [{
    id: "morning-yoga",
    name: "Morning yoga",
    period: "week",
    target: 5,
    completed: 2,
    lastDone: "Yesterday",
    state: "incomplete",
    availability: null,
    completions: completionsFor([2, 4, 6, 8, 9])
  }, {
    id: "walk-the-dog",
    name: "Walk the dog",
    period: "week",
    target: 5,
    completed: 3,
    lastDone: "Today",
    state: "complete",
    availability: null,
    completions: completionsFor([2, 4, 6, 8, 9, 10])
  }, {
    id: "lunch-walk",
    name: "Lunch walk",
    period: "week",
    target: 3,
    completed: 1,
    lastDone: "Yesterday",
    state: "incomplete",
    availability: "Available until 2:00 PM",
    completions: completionsFor([3, 9])
  }, {
    id: "wake-up-early",
    name: "Wake up early",
    period: "week",
    target: 4,
    completed: 1,
    lastDone: "Yesterday",
    state: "unavailable",
    availability: "Available 12:00 AM–6:45 AM",
    completions: completionsFor([9])
  }, {
    id: "evening-yoga",
    name: "Evening yoga",
    period: "week",
    target: 4,
    completed: 1,
    lastDone: "Yesterday",
    state: "unavailable",
    availability: "Available 11:00 PM–3:00 AM",
    completions: completionsFor([9])
  }, {
    id: "water-plants",
    name: "Water plants",
    period: "week",
    target: 1,
    completed: 1,
    lastDone: "3d ago",
    state: "target-met",
    availability: null,
    completions: completionsFor([7])
  }, {
    id: "read-a-book",
    name: "Read a book",
    period: "week",
    target: 4,
    completed: 2,
    lastDone: "2d ago",
    state: "incomplete",
    availability: null,
    completions: completionsFor([4, 8])
  }, {
    id: "clean-air-purifiers",
    name: "Clean air purifiers",
    period: "month",
    target: 1,
    completed: 1,
    lastDone: "Today",
    state: "complete",
    availability: null,
    completions: completionsFor([10])
  }, {
    id: "whiten-teeth",
    name: "Whiten teeth",
    period: "month",
    target: 1,
    completed: 0,
    lastDone: "May 18",
    state: "incomplete",
    availability: null,
    completions: completionsFor([])
  }];
  const GROUPS = [{
    id: "today-focus",
    name: "Today Focus",
    routineIds: ["morning-yoga", "walk-the-dog", "lunch-walk", "wake-up-early"]
  }, {
    id: "progress-edges",
    name: "Progress Edges",
    routineIds: ["evening-yoga", "water-plants", "read-a-book"]
  }, {
    id: "monthly-maintenance",
    name: "Monthly Maintenance",
    routineIds: ["clean-air-purifiers", "whiten-teeth"]
  }];
  window.ROUTINE_DATA = {
    today: {
      weekday: "Wednesday",
      label: "Wednesday, Jun 10",
      year: 2026,
      month: 6,
      day: 10
    },
    weekdaySymbols: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
    monthTitle: "June 2026",
    daysInMonth: 30,
    firstWeekdayIndex: 1,
    // June 1, 2026 is a Monday (0=Sun)
    routines: ROUTINES,
    groups: GROUPS
  };
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/routine_app/routine-data.js", error: String((e && e.message) || e) }); }

__ds_ns.Button = __ds_scope.Button;

__ds_ns.Icon = __ds_scope.Icon;

__ds_ns.IconButton = __ds_scope.IconButton;

__ds_ns.MetadataPill = __ds_scope.MetadataPill;

__ds_ns.ProgressRing = __ds_scope.ProgressRing;

__ds_ns.RoutineCard = __ds_scope.RoutineCard;

__ds_ns.UndoBanner = __ds_scope.UndoBanner;

})();
