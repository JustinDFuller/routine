/* Routine UI kit — Routine History */
(function () {
  const NS = window.RoutineDesignSystem_14e910;
  const { ProgressRing, Button, IconButton } = NS;

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

  function NavHeader({ title, onBack }) {
    return (
      <div style={{ position: "relative", display: "flex", alignItems: "center", justifyContent: "center", padding: "8px 8px 4px", minHeight: 48 }}>
        <div style={{ position: "absolute", left: 8 }}>
          <IconButton icon="chevron-left" label="Back" tone="primary" onClick={onBack} />
        </div>
        <span style={{ color: "var(--text-primary)", font: "var(--weight-semibold) var(--text-headline)/1 var(--font-system)" }}>
          {title}
        </span>
      </div>
    );
  }

  function SummaryCard({ r }) {
    const accent = r.state === "complete" || r.state === "target-met" ? "complete" : "active";
    return (
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 16,
          padding: 16,
          background: "var(--surface-sheet)",
          borderRadius: "var(--radius-card)",
          boxShadow: "inset 0 0 0 1px var(--border-hairline-soft)",
        }}
      >
        <ProgressRing
          completed={r.completed}
          target={r.target}
          showCheckmark={r.state === "complete"}
          accent={accent}
          size={72}
          strokeWidth={7}
        />
        <div style={{ display: "flex", flexDirection: "column", gap: 6, minWidth: 0 }}>
          <span style={{ color: "var(--text-primary)", font: "var(--weight-semibold) var(--text-title3)/var(--leading-title3) var(--font-system)" }}>
            {r.name}
          </span>
          <span style={{ color: "var(--text-secondary)", font: "var(--weight-semibold) var(--text-subheadline)/1 var(--font-system)" }}>
            {freqSummary(r)}
          </span>
          <span style={{ color: "var(--text-primary)", font: "var(--weight-semibold) var(--text-headline)/1 var(--font-system)" }}>
            {periodProgress(r)}
          </span>
          <span style={{ color: "var(--text-secondary)", font: "var(--weight-regular) var(--text-body)/1.2 var(--font-system)" }}>
            {lastDoneDisplay(r)}
          </span>
        </div>
      </div>
    );
  }

  function MonthGrid({ r, data }) {
    const done = new Set(r.completions);
    const cells = [];
    for (let i = 0; i < data.firstWeekdayIndex; i++) cells.push(<div key={`p${i}`} />);
    for (let d = 1; d <= data.daysInMonth; d++) {
      const isToday = d === data.today.day;
      const isDone = done.has(d);
      cells.push(
        <div key={d} style={{ position: "relative", height: 36, display: "grid", placeItems: "center" }}>
          {isDone && (
            <span style={{ position: "absolute", width: 32, height: 32, borderRadius: "50%", background: "var(--calendar-day-complete)" }} />
          )}
          {isToday && (
            <span style={{ position: "absolute", width: 32, height: 32, borderRadius: "50%", boxShadow: "inset 0 0 0 2px var(--accent-active)" }} />
          )}
          <span
            style={{
              position: "relative",
              color: isDone ? "var(--text-primary)" : "var(--text-secondary)",
              font: `${isToday ? "var(--weight-semibold)" : "var(--weight-regular)"} var(--text-subheadline)/1 var(--font-system)`,
            }}
          >
            {d}
          </span>
        </div>
      );
    }
    return (
      <div
        style={{
          padding: 16,
          background: "var(--surface-card)",
          borderRadius: "var(--radius-card)",
          boxShadow: "inset 0 0 0 1px var(--border-hairline-soft)",
          display: "flex",
          flexDirection: "column",
          gap: 16,
        }}
      >
        <span style={{ color: "var(--text-primary)", font: "var(--weight-semibold) var(--text-headline)/1 var(--font-system)" }}>
          {data.monthTitle}
        </span>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(7,1fr)", gap: 8 }}>
          {data.weekdaySymbols.map((s) => (
            <div key={s} style={{ textAlign: "center", color: "var(--text-secondary)", font: "var(--weight-semibold) var(--text-caption)/1 var(--font-system)" }}>
              {s}
            </div>
          ))}
          {cells}
        </div>
      </div>
    );
  }

  function CompletionRow({ day, onRemove }) {
    const rel = relativeFor(day);
    return (
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 12,
          padding: 14,
          background: "var(--surface-sheet)",
          borderRadius: "var(--radius-row)",
          boxShadow: "inset 0 0 0 1px var(--border-hairline-soft)",
        }}
      >
        <div style={{ display: "flex", flexDirection: "column", gap: 4, flex: 1, minWidth: 0 }}>
          <span style={{ color: "var(--text-primary)", font: "var(--weight-semibold) var(--text-body)/1 var(--font-system)" }}>
            {MONTH_ABBR} {day}, 2026
          </span>
          {rel && (
            <span style={{ color: "var(--text-secondary)", font: "var(--weight-regular) var(--text-caption)/1 var(--font-system)" }}>
              {rel}
            </span>
          )}
        </div>
        <Button variant="bordered" tone="destructive" size="sm" onClick={() => onRemove(day)}>
          <NS.Icon name="trash" size={16} /> Remove
        </Button>
      </div>
    );
  }

  function History({ routine, data, onBack, onRemove }) {
    const recent = [...routine.completions].sort((a, b) => b - a);
    return (
      <div style={{ minHeight: "100%", background: "var(--bg-canvas)", paddingBottom: 28 }}>
        <NavHeader title="History" onBack={onBack} />
        <div style={{ padding: "12px 16px 0", display: "flex", flexDirection: "column", gap: 24 }}>
          <SummaryCard r={routine} />
          <MonthGrid r={routine} data={data} />
          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            <span style={{ color: "var(--text-primary)", font: "var(--weight-semibold) var(--text-headline)/1 var(--font-system)" }}>
              Recent completions
            </span>
            {recent.length === 0 ? (
              <span style={{ color: "var(--text-secondary)", font: "var(--weight-regular) var(--text-body)/1 var(--font-system)", padding: "8px 0" }}>
                No recent completions
              </span>
            ) : (
              recent.map((d) => <CompletionRow key={d} day={d} onRemove={onRemove} />)
            )}
          </div>
        </div>
      </div>
    );
  }

  window.History = History;
})();
