/* Routine UI kit — management menu, forms, settings, rearrange */
(function () {
  const NS = window.RoutineDesignSystem_14e910;
  const { Button, IconButton, Icon } = NS;

  /* ---------- shared form primitives ---------- */
  function FormGroup({ children }) {
    return (
      <div
        style={{
          background: "var(--surface-sheet)",
          borderRadius: "var(--radius-control)",
          overflow: "hidden",
          boxShadow: "inset 0 0 0 1px var(--border-hairline-soft)",
        }}
      >
        {children}
      </div>
    );
  }

  function FormRow({ children, last, style }) {
    return (
      <div
        style={{
          display: "flex",
          alignItems: "center",
          minHeight: 52,
          padding: "10px 14px",
          boxShadow: last ? "none" : "inset 0 -1px 0 var(--border-hairline-soft)",
          ...style,
        }}
      >
        {children}
      </div>
    );
  }

  const labelStyle = { color: "var(--text-primary)", font: "var(--weight-regular) var(--text-body)/1 var(--font-system)" };

  function Stepper({ value, onDec, onInc }) {
    const btn = (child, onClick, disabled) => (
      <button
        type="button"
        onClick={onClick}
        disabled={disabled}
        style={{
          appearance: "none",
          border: "none",
          background: "transparent",
          color: disabled ? "var(--text-secondary)" : "var(--text-primary)",
          width: 48,
          height: 36,
          display: "grid",
          placeItems: "center",
          cursor: disabled ? "default" : "pointer",
          opacity: disabled ? 0.4 : 1,
        }}
      >
        {child}
      </button>
    );
    return (
      <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
        <span style={{ color: "var(--text-secondary)", font: "var(--weight-regular) var(--text-body)/1 var(--font-system)", fontVariantNumeric: "tabular-nums" }}>
          {value}
        </span>
        <div style={{ display: "flex", alignItems: "center", background: "color-mix(in srgb, var(--border-hairline) 50%, transparent)", borderRadius: "var(--radius-pill)" }}>
          {btn(<Icon name="minus" size={20} />, onDec, value <= 1)}
          <span style={{ width: 1, height: 22, background: "var(--border-hairline)" }} />
          {btn(<Icon name="plus" size={20} />, onInc)}
        </div>
      </div>
    );
  }

  function Segmented({ value, options, onChange }) {
    return (
      <div
        style={{
          display: "flex",
          padding: 2,
          gap: 2,
          background: "color-mix(in srgb, var(--border-hairline) 50%, transparent)",
          borderRadius: "var(--radius-pill)",
          width: "100%",
        }}
      >
        {options.map((opt) => {
          const active = opt.value === value;
          return (
            <button
              key={opt.value}
              type="button"
              onClick={() => onChange(opt.value)}
              style={{
                flex: 1,
                appearance: "none",
                border: "none",
                cursor: "pointer",
                borderRadius: "var(--radius-pill)",
                padding: "8px 0",
                background: active ? "var(--surface-sheet)" : "transparent",
                boxShadow: active ? "0 1px 3px rgba(0,0,0,.25)" : "none",
                color: active ? "var(--text-primary)" : "var(--text-secondary)",
                font: "var(--weight-semibold) var(--text-subheadline)/1 var(--font-system)",
              }}
            >
              {opt.label}
            </button>
          );
        })}
      </div>
    );
  }

  function Switch({ on, onToggle }) {
    return (
      <button
        type="button"
        onClick={onToggle}
        aria-pressed={on}
        style={{
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
          justifyContent: on ? "flex-end" : "flex-start",
        }}
      >
        <span style={{ width: 27, height: 27, borderRadius: "50%", background: "#fff", boxShadow: "0 1px 3px rgba(0,0,0,.3)" }} />
      </button>
    );
  }

  function SheetShell({ title, onCancel, onSave, saveLabel, children }) {
    return (
      <div style={{ display: "flex", flexDirection: "column", height: "100%", background: "var(--bg-canvas)" }}>
        <div style={{ display: "flex", alignItems: "center", padding: "48px 16px 12px" }}>
          <button type="button" onClick={onCancel} style={{ appearance: "none", border: "none", background: "transparent", color: "var(--accent-active)", font: "var(--weight-regular) var(--text-body)/1 var(--font-system)", cursor: "pointer", minWidth: 60, textAlign: "left" }}>
            Cancel
          </button>
          <span style={{ flex: 1, textAlign: "center", color: "var(--text-primary)", font: "var(--weight-semibold) var(--text-headline)/1 var(--font-system)" }}>
            {title}
          </span>
          <button type="button" onClick={onSave} style={{ appearance: "none", border: "none", background: "transparent", color: "var(--accent-active)", font: "var(--weight-semibold) var(--text-body)/1 var(--font-system)", cursor: "pointer", minWidth: 60, textAlign: "right" }}>
            {saveLabel}
          </button>
        </div>
        <div style={{ flex: 1, overflow: "auto", padding: "8px 16px 24px", display: "flex", flexDirection: "column", gap: 22 }}>
          {children}
        </div>
      </div>
    );
  }

  /* ---------- Management menu (popover) ---------- */
  function ManagementMenu({ onClose, onAction }) {
    const items = [
      { key: "add-routine", label: "Add Routine" },
      { key: "add-group", label: "Add Group" },
      { key: "edit", label: "Edit" },
      { key: "rearrange-groups", label: "Rearrange Groups" },
      { key: "rearrange-routines", label: "Rearrange Routines" },
      { divider: true, key: "div" },
      { key: "settings", label: "Week Starts On" },
    ];
    return (
      <div style={{ position: "absolute", inset: 0, zIndex: 80 }} onClick={onClose}>
        <div style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.28)" }} />
        <div
          onClick={(e) => e.stopPropagation()}
          style={{
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
            overflow: "hidden",
          }}
        >
          {items.map((it) =>
            it.divider ? (
              <div key={it.key} style={{ height: 1, background: "var(--border-hairline)" }} />
            ) : (
              <button
                key={it.key}
                type="button"
                onClick={() => onAction(it.key)}
                style={{
                  appearance: "none",
                  border: "none",
                  background: "transparent",
                  width: "100%",
                  textAlign: "left",
                  padding: "15px 18px",
                  color: "var(--text-primary)",
                  font: "var(--weight-regular) var(--text-title3)/1 var(--font-system)",
                  cursor: "pointer",
                }}
              >
                {it.label}
              </button>
            )
          )}
        </div>
      </div>
    );
  }

  /* ---------- Add / Edit Routine ---------- */
  function RoutineForm({ groups, initial, onCancel, onSave, onDelete }) {
    const isEdit = !!initial;
    const [name, setName] = React.useState(initial ? initial.name : "");
    const [target, setTarget] = React.useState(initial ? initial.target : 3);
    const [period, setPeriod] = React.useState(initial ? initial.period : "week");
    const [groupId, setGroupId] = React.useState(
      initial ? initial.groupId : groups[0] ? groups[0].id : null
    );
    const [allDay, setAllDay] = React.useState(initial ? !initial.availability : true);

    const groupName = (groups.find((g) => g.id === groupId) || {}).name || "Choose a group";
    const cycleGroup = () => {
      const idx = groups.findIndex((g) => g.id === groupId);
      setGroupId(groups[(idx + 1) % groups.length].id);
    };

    return (
      <SheetShell
        title={isEdit ? "Edit Routine" : "Add Routine"}
        saveLabel={isEdit ? "Save" : "Add"}
        onCancel={onCancel}
        onSave={() => name.trim() && onSave({ name: name.trim(), target, period, groupId })}
      >
        <FormGroup>
          <FormRow>
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Name"
              autoFocus
              style={{ flex: 1, appearance: "none", border: "none", outline: "none", background: "transparent", color: "var(--text-primary)", font: "var(--weight-regular) var(--text-body)/1 var(--font-system)" }}
            />
          </FormRow>
          <FormRow>
            <span style={labelStyle}>Target</span>
            <span style={{ flex: 1 }} />
            <Stepper value={target} onDec={() => setTarget((t) => Math.max(1, t - 1))} onInc={() => setTarget((t) => t + 1)} />
          </FormRow>
          <FormRow>
            <Segmented
              value={period}
              onChange={setPeriod}
              options={[{ value: "week", label: "Weekly" }, { value: "month", label: "Monthly" }]}
            />
          </FormRow>
          <FormRow last>
            <span style={labelStyle}>Group</span>
            <span style={{ flex: 1 }} />
            <button type="button" onClick={cycleGroup} style={{ appearance: "none", border: "none", background: "transparent", cursor: "pointer", display: "flex", alignItems: "center", gap: 6, color: "var(--accent-active)", font: "var(--weight-regular) var(--text-body)/1 var(--font-system)" }}>
              {groupName}
              <Icon name="chevron-updown" size={18} />
            </button>
          </FormRow>
        </FormGroup>

        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          <span style={{ color: "var(--text-secondary)", font: "var(--weight-semibold) var(--text-footnote)/1 var(--font-system)", textTransform: "uppercase", letterSpacing: "0.04em", padding: "0 4px" }}>
            Availability
          </span>
          <FormGroup>
            <FormRow last={allDay}>
              <span style={labelStyle}>Available all day</span>
              <span style={{ flex: 1 }} />
              <Switch on={allDay} onToggle={() => setAllDay((v) => !v)} />
            </FormRow>
            {!allDay && (
              <>
                <FormRow>
                  <span style={labelStyle}>Start</span>
                  <span style={{ flex: 1 }} />
                  <span style={{ color: "var(--accent-active)", font: "var(--weight-regular) var(--text-body)/1 var(--font-system)", background: "var(--tint-active-soft)", padding: "6px 12px", borderRadius: 8 }}>9:00 AM</span>
                </FormRow>
                <FormRow last>
                  <span style={labelStyle}>End</span>
                  <span style={{ flex: 1 }} />
                  <span style={{ color: "var(--accent-active)", font: "var(--weight-regular) var(--text-body)/1 var(--font-system)", background: "var(--tint-active-soft)", padding: "6px 12px", borderRadius: 8 }}>5:00 PM</span>
                </FormRow>
              </>
            )}
          </FormGroup>
        </div>

        {isEdit && (
          <FormGroup>
            <FormRow last>
              <button type="button" onClick={onDelete} style={{ appearance: "none", border: "none", background: "transparent", cursor: "pointer", color: "var(--accent-destructive)", font: "var(--weight-regular) var(--text-body)/1 var(--font-system)" }}>
                Delete Routine
              </button>
            </FormRow>
          </FormGroup>
        )}
      </SheetShell>
    );
  }

  /* ---------- Add / Edit Group ---------- */
  function GroupForm({ initial, onCancel, onSave, onDelete }) {
    const isEdit = !!initial;
    const [name, setName] = React.useState(initial ? initial.name : "");
    return (
      <SheetShell
        title={isEdit ? "Rename Group" : "Add Group"}
        saveLabel={isEdit ? "Save" : "Add"}
        onCancel={onCancel}
        onSave={() => name.trim() && onSave({ name: name.trim() })}
      >
        <FormGroup>
          <FormRow last>
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Name"
              autoFocus
              style={{ flex: 1, appearance: "none", border: "none", outline: "none", background: "transparent", color: "var(--text-primary)", font: "var(--weight-regular) var(--text-body)/1 var(--font-system)" }}
            />
          </FormRow>
        </FormGroup>
        {isEdit && (
          <FormGroup>
            <FormRow last>
              <button type="button" onClick={onDelete} style={{ appearance: "none", border: "none", background: "transparent", cursor: "pointer", color: "var(--accent-destructive)", font: "var(--weight-regular) var(--text-body)/1 var(--font-system)" }}>
                Delete Group
              </button>
            </FormRow>
          </FormGroup>
        )}
      </SheetShell>
    );
  }

  /* ---------- Settings (week starts on) ---------- */
  function Settings({ value, onChange, onClose }) {
    const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
    return (
      <div style={{ display: "flex", flexDirection: "column", height: "100%", background: "var(--bg-canvas)" }}>
        <div style={{ display: "flex", alignItems: "center", padding: "48px 16px 12px" }}>
          <span style={{ flex: 1 }} />
          <span style={{ color: "var(--text-primary)", font: "var(--weight-semibold) var(--text-headline)/1 var(--font-system)" }}>
            Week Starts On
          </span>
          <span style={{ flex: 1, display: "flex", justifyContent: "flex-end" }}>
            <button type="button" onClick={onClose} style={{ appearance: "none", border: "none", background: "transparent", color: "var(--accent-active)", font: "var(--weight-semibold) var(--text-body)/1 var(--font-system)", cursor: "pointer" }}>
              Done
            </button>
          </span>
        </div>
        <div style={{ padding: "8px 16px", display: "flex", flexDirection: "column", gap: 10 }}>
          <FormGroup>
            {days.map((d, i) => (
              <FormRow key={d} last={i === days.length - 1}>
                <button type="button" onClick={() => onChange(d)} style={{ flex: 1, display: "flex", alignItems: "center", appearance: "none", border: "none", background: "transparent", cursor: "pointer", padding: 0 }}>
                  <span style={labelStyle}>{d}</span>
                  <span style={{ flex: 1 }} />
                  {value === d && <Icon name="check" size={20} color="var(--accent-active)" />}
                </button>
              </FormRow>
            ))}
          </FormGroup>
          <span style={{ color: "var(--text-secondary)", font: "var(--weight-regular) var(--text-footnote)/1.4 var(--font-system)", padding: "2px 8px" }}>
            Controls when your weekly routine progress resets.
          </span>
        </div>
      </div>
    );
  }

  /* ---------- Rearrange (groups or routines) ---------- */
  function RearrangeView({ kind, data, onDone }) {
    const rows =
      kind === "groups"
        ? data.groups.map((g) => ({ id: g.id, name: g.name }))
        : data.groups.flatMap((g) =>
            g.routineIds
              .map((rid) => data.routines.find((r) => r.id === rid))
              .filter(Boolean)
              .map((r) => ({ id: r.id, name: r.name, group: g.name, summary: `${r.target} per ${r.period === "month" ? "month" : "week"}` }))
          );
    let lastGroup = null;
    return (
      <div style={{ minHeight: "100%", background: "var(--bg-canvas)" }}>
        <div style={{ display: "flex", alignItems: "center", padding: "8px 16px 12px", paddingTop: 14 }}>
          <span style={{ color: "var(--text-primary)", font: "var(--weight-semibold) var(--text-title)/var(--leading-title) var(--font-system)" }}>
            {kind === "groups" ? "Rearrange Groups" : "Rearrange Routines"}
          </span>
          <span style={{ flex: 1 }} />
          <button type="button" onClick={onDone} style={{ appearance: "none", border: "none", background: "transparent", color: "var(--accent-active)", font: "var(--weight-semibold) var(--text-body)/1 var(--font-system)", cursor: "pointer", minHeight: 44 }}>
            Done
          </button>
        </div>
        <div style={{ padding: "0 16px", display: "flex", flexDirection: "column", gap: 14 }}>
          {rows.map((row) => {
            const showHeader = kind === "routines" && row.group !== lastGroup;
            lastGroup = row.group;
            return (
              <React.Fragment key={row.id}>
                {showHeader && (
                  <span style={{ color: "var(--text-secondary)", font: "var(--weight-semibold) var(--text-subheadline)/1 var(--font-system)", marginTop: 8 }}>
                    {row.group}
                  </span>
                )}
                <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "14px", background: "var(--surface-sheet)", borderRadius: "var(--radius-row)", boxShadow: "inset 0 0 0 1px var(--border-hairline-soft)" }}>
                  <div style={{ display: "flex", flexDirection: "column", gap: 4, flex: 1, minWidth: 0 }}>
                    <span style={{ color: "var(--text-primary)", font: "var(--weight-regular) var(--text-body)/1 var(--font-system)" }}>{row.name}</span>
                    {row.summary && <span style={{ color: "var(--text-secondary)", font: "var(--weight-regular) var(--text-subheadline)/1 var(--font-system)" }}>{row.summary}</span>}
                  </div>
                  <Icon name="reorder" size={22} color="var(--text-secondary)" />
                </div>
              </React.Fragment>
            );
          })}
        </div>
      </div>
    );
  }

  Object.assign(window, { ManagementMenu, RoutineForm, GroupForm, Settings, RearrangeView });
})();
