/* Routine UI kit — interactive controller */
(function () {
  const { useState, useRef, useCallback } = React;

  function clone(data) {
    return {
      ...data,
      routines: data.routines.map((r) => ({ ...r, completions: [...r.completions] })),
      groups: data.groups.map((g) => ({ ...g, routineIds: [...g.routineIds] })),
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
    const byId = (id) => data.routines.find((r) => r.id === id);

    const showUndo = useCallback((name, snapshot) => {
      setUndo({ name, snapshot });
      if (undoTimer.current) clearTimeout(undoTimer.current);
      undoTimer.current = setTimeout(() => setUndo(null), 4200);
    }, []);

    const handleComplete = (id) => {
      const r = byId(id);
      if (!r) return;
      if (r.state === "complete" || r.state === "target-met" || r.state === "over-target") {
        // already done today / met → open history instead of double-completing
        setHistoryId(id);
        setRoute("history");
        return;
      }
      const snapshot = clone(data);
      setData((prev) => {
        const next = clone(prev);
        const t = next.routines.find((x) => x.id === id);
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

    const openHistory = (id) => {
      setHistoryId(id);
      setRoute("history");
    };

    const handleMenu = (key) => {
      setMenuOpen(false);
      if (key === "add-routine") setSheet("add-routine");
      else if (key === "add-group") setSheet("add-group");
      else if (key === "edit") setMode("edit");
      else if (key === "rearrange-groups") setRoute("rearrange-groups");
      else if (key === "rearrange-routines") setRoute("rearrange-routines");
      else if (key === "settings") setSheet("settings");
    };

    const addRoutine = (draft) => {
      setData((prev) => {
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
          completions: [],
        });
        const g = next.groups.find((x) => x.id === draft.groupId) || next.groups[0];
        g.routineIds.push(id);
        return next;
      });
      setSheet(null);
    };

    const saveRoutineEdit = (draft) => {
      setData((prev) => {
        const next = clone(prev);
        const r = next.routines.find((x) => x.id === editRoutineId);
        if (r) {
          r.name = draft.name;
          r.target = draft.target;
          r.period = draft.period;
        }
        // move group if changed
        if (draft.groupId) {
          next.groups.forEach((g) => {
            g.routineIds = g.routineIds.filter((rid) => rid !== editRoutineId);
          });
          const g = next.groups.find((x) => x.id === draft.groupId) || next.groups[0];
          g.routineIds.push(editRoutineId);
        }
        return next;
      });
      setSheet(null);
    };

    const deleteRoutine = () => {
      setData((prev) => {
        const next = clone(prev);
        next.routines = next.routines.filter((x) => x.id !== editRoutineId);
        next.groups.forEach((g) => (g.routineIds = g.routineIds.filter((rid) => rid !== editRoutineId)));
        return next;
      });
      setSheet(null);
    };

    const addGroup = (draft) => {
      setData((prev) => {
        const next = clone(prev);
        next.groups.push({ id: `g-${Date.now()}`, name: draft.name, routineIds: [] });
        return next;
      });
      setSheet(null);
    };

    const saveGroupEdit = (draft) => {
      setData((prev) => {
        const next = clone(prev);
        const g = next.groups.find((x) => x.id === editGroupId);
        if (g) g.name = draft.name;
        return next;
      });
      setSheet(null);
    };

    const deleteGroup = () => {
      setData((prev) => {
        const next = clone(prev);
        next.groups = next.groups.filter((x) => x.id !== editGroupId);
        return next;
      });
      setSheet(null);
    };

    const removeCompletion = (day) => {
      setData((prev) => {
        const next = clone(prev);
        const r = next.routines.find((x) => x.id === historyId);
        if (r) {
          r.completions = r.completions.filter((d) => d !== day);
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
      const g = data.groups.find((x) => x.routineIds.includes(r.id));
      return { name: r.name, target: r.target, period: r.period, groupId: g ? g.id : null };
    })();

    const editGroupInitial = (() => {
      if (sheet !== "edit-group") return null;
      const g = data.groups.find((x) => x.id === editGroupId);
      return g ? { name: g.name } : null;
    })();

    const historyRoutine = route === "history" ? byId(historyId) : null;

    return (
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 18 }}>
        {/* theme toggle (kit chrome, not part of the app) */}
        <div style={{ display: "flex", gap: 4, padding: 3, background: "rgba(120,120,128,0.16)", borderRadius: 999 }}>
          {["dark", "light"].map((t) => (
            <button
              key={t}
              type="button"
              onClick={() => setTheme(t)}
              style={{
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
                boxShadow: theme === t ? "0 1px 3px rgba(0,0,0,.2)" : "none",
              }}
            >
              {t}
            </button>
          ))}
        </div>

        <IOSDevice dark={dark}>
          <div data-theme={dark ? "dark" : "light"} style={{ position: "relative", minHeight: "100%", background: "var(--bg-canvas)" }}>
            {/* base route */}
            {route === "dashboard" && (
              <div style={{ paddingTop: 44 }}>
                <window.Dashboard
                  data={data}
                  mode={mode}
                  onComplete={handleComplete}
                  onHistory={openHistory}
                  onEditRoutine={(id) => { setEditRoutineId(id); setSheet("edit-routine"); }}
                  onEditGroup={(id) => { setEditGroupId(id); setSheet("edit-group"); }}
                  onGear={() => setMenuOpen(true)}
                  onDoneEditing={() => setMode("tracking")}
                />
              </div>
            )}
            {route === "history" && historyRoutine && (
              <div style={{ paddingTop: 44 }}>
                <window.History routine={historyRoutine} data={data} onBack={() => setRoute("dashboard")} onRemove={removeCompletion} />
              </div>
            )}
            {(route === "rearrange-groups" || route === "rearrange-routines") && (
              <div style={{ paddingTop: 44 }}>
                <window.RearrangeView kind={route === "rearrange-groups" ? "groups" : "routines"} data={data} onDone={() => setRoute("dashboard")} />
              </div>
            )}

            {/* undo banner */}
            {undo && route === "dashboard" && (
              <div style={{ position: "absolute", left: 16, right: 16, bottom: 28, zIndex: 70 }}>
                <window.RoutineDesignSystem_14e910.UndoBanner message={undo.name} onUndo={handleUndo} />
              </div>
            )}

            {/* management menu */}
            {menuOpen && <window.ManagementMenu onClose={() => setMenuOpen(false)} onAction={handleMenu} />}

            {/* sheets */}
            {sheet && (
              <div style={{ position: "absolute", inset: 0, zIndex: 90 }}>
                {sheet === "add-routine" && (
                  <window.RoutineForm groups={data.groups} onCancel={() => setSheet(null)} onSave={addRoutine} />
                )}
                {sheet === "edit-routine" && editInitial && (
                  <window.RoutineForm groups={data.groups} initial={editInitial} onCancel={() => setSheet(null)} onSave={saveRoutineEdit} onDelete={deleteRoutine} />
                )}
                {sheet === "add-group" && (
                  <window.GroupForm onCancel={() => setSheet(null)} onSave={addGroup} />
                )}
                {sheet === "edit-group" && editGroupInitial && (
                  <window.GroupForm initial={editGroupInitial} onCancel={() => setSheet(null)} onSave={saveGroupEdit} onDelete={deleteGroup} />
                )}
                {sheet === "settings" && (
                  <window.Settings value={weekStart} onChange={setWeekStart} onClose={() => setSheet(null)} />
                )}
              </div>
            )}
          </div>
        </IOSDevice>
      </div>
    );
  }

  window.RoutineAppKit = RoutineAppKit;
})();
