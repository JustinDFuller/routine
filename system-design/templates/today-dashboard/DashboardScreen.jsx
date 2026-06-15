/* Template wrapper — renders the Today dashboard from a `groups` dataset using
   the real design-system components. Kept thin: edit the data in the .dc.html
   logic class, not here. A readiness guard covers the async DS bundle load. */
function DashboardScreen({ groups = [], dateLabel = "" }) {
  const [ready, setReady] = React.useState(!!window.RoutineDesignSystem_14e910);
  React.useEffect(() => {
    if (ready) return;
    const t = setInterval(() => {
      if (window.RoutineDesignSystem_14e910) {
        setReady(true);
        clearInterval(t);
      }
    }, 40);
    return () => clearInterval(t);
  }, [ready]);

  const wrap = {
    minHeight: "100vh",
    background: "var(--bg-canvas)",
    display: "flex",
    justifyContent: "center",
    fontFamily: "var(--font-system)",
  };
  const col = {
    width: "100%",
    maxWidth: 420,
    boxSizing: "border-box",
    padding: "28px 16px 40px",
    display: "flex",
    flexDirection: "column",
    gap: 24,
  };

  if (!ready) return <div data-theme="dark" style={wrap} />;

  const { RoutineCard, IconButton } = window.RoutineDesignSystem_14e910;

  return (
    <div data-theme="dark" style={wrap}>
      <div style={col}>
        <div style={{ display: "flex", alignItems: "flex-end", gap: 12 }}>
          <span style={{ color: "var(--text-primary)", fontWeight: 600, fontSize: "var(--text-title)", lineHeight: "var(--leading-title)" }}>
            Today
          </span>
          <span style={{ flex: 1 }} />
          <IconButton icon="settings" label="Management" tone="primary" />
        </div>
        {dateLabel && (
          <div style={{ color: "var(--text-secondary)", fontSize: "var(--text-subheadline)", lineHeight: "var(--leading-subheadline)", marginTop: -16 }}>
            {dateLabel}
          </div>
        )}

        {groups.map((g, gi) => (
          <div key={gi} style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            <span style={{ color: "var(--text-secondary)", fontWeight: 600, fontSize: "var(--text-subheadline)" }}>
              {g.name}
            </span>
            <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              {(g.routines || []).map((r, ri) => (
                <RoutineCard
                  key={ri}
                  name={r.name}
                  count={r.count}
                  period={r.period}
                  lastDone={r.lastDone}
                  availability={r.availability}
                  completed={r.completed}
                  target={r.target}
                  state={r.state}
                />
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

module.exports = { DashboardScreen };
