/* Routine UI kit — Today Dashboard */
(function () {
  const NS = window.RoutineDesignSystem_14e910;
  const { RoutineCard, IconButton } = NS;

  function SectionHeader({ name, editable, onEdit }) {
    return (
      <div style={{ display: "flex", alignItems: "center", gap: 12, minHeight: editable ? 28 : "auto" }}>
        <span
          style={{
            color: "var(--text-secondary)",
            font: "var(--weight-semibold) var(--text-subheadline)/var(--leading-subheadline) var(--font-system)",
          }}
        >
          {name}
        </span>
        <span style={{ flex: 1 }} />
        {editable && <IconButton icon="pencil" label={`Edit ${name}`} size={20} onClick={onEdit} />}
      </div>
    );
  }

  function Dashboard({ data, mode, onComplete, onHistory, onEditRoutine, onEditGroup, onGear, onDoneEditing }) {
    const byId = React.useMemo(() => {
      const m = {};
      data.routines.forEach((r) => (m[r.id] = r));
      return m;
    }, [data.routines]);

    const editing = mode === "edit";

    return (
      <div style={{ minHeight: "100%", background: "var(--bg-canvas)", paddingBottom: 28 }}>
        <div style={{ padding: "8px 16px 0", display: "flex", flexDirection: "column", gap: 24 }}>
          {/* header */}
          <div style={{ display: "flex", alignItems: "center", gap: 12, paddingTop: 6 }}>
            <span
              style={{
                color: "var(--text-primary)",
                font: "var(--weight-semibold) var(--text-title)/var(--leading-title) var(--font-system)",
              }}
            >
              Today
            </span>
            <span style={{ flex: 1 }} />
            {editing ? (
              <button
                type="button"
                onClick={onDoneEditing}
                style={{
                  appearance: "none",
                  border: "none",
                  background: "transparent",
                  color: "var(--accent-active)",
                  font: "var(--weight-semibold) var(--text-body)/1 var(--font-system)",
                  cursor: "pointer",
                  minHeight: 44,
                  padding: "0 4px",
                }}
              >
                Done
              </button>
            ) : (
              <IconButton icon="settings" label="Management" tone="primary" onClick={onGear} />
            )}
          </div>

          {/* date */}
          <div
            style={{
              marginTop: -12,
              color: "var(--text-secondary)",
              font: "var(--weight-regular) var(--text-subheadline)/var(--leading-subheadline) var(--font-system)",
            }}
          >
            {data.today.label}
          </div>

          {/* sections */}
          {data.groups.map((group) => (
            <div key={group.id} style={{ display: "flex", flexDirection: "column", gap: 10 }}>
              <SectionHeader name={group.name} editable={editing} onEdit={() => onEditGroup(group.id)} />
              <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
                {group.routineIds.map((rid) => {
                  const r = byId[rid];
                  if (!r) return null;
                  return (
                    <RoutineCard
                      key={r.id}
                      name={r.name}
                      count={`${r.completed}/${r.target}`}
                      period={r.period}
                      lastDone={r.lastDone}
                      availability={r.availability}
                      completed={r.completed}
                      target={r.target}
                      state={r.state}
                      showEdit={editing}
                      showHistory={!editing}
                      onComplete={() => onComplete(r.id)}
                      onHistory={() => onHistory(r.id)}
                      onEdit={() => onEditRoutine(r.id)}
                    />
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  window.Dashboard = Dashboard;
})();
