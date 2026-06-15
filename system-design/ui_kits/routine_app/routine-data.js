/* Routine — UI-kit seed data.
   Mirrors the dogfooding starter dataset and the captured screenshots.
   Fixed "today" = Wednesday, June 10, 2026 (week starts Sunday). Plain JS. */
(function () {
  const completionsFor = (days) => days; // day-of-month numbers, June 2026

  const ROUTINES = [
    {
      id: "morning-yoga",
      name: "Morning yoga",
      period: "week",
      target: 5,
      completed: 2,
      lastDone: "Yesterday",
      state: "incomplete",
      availability: null,
      completions: completionsFor([2, 4, 6, 8, 9]),
    },
    {
      id: "walk-the-dog",
      name: "Walk the dog",
      period: "week",
      target: 5,
      completed: 3,
      lastDone: "Today",
      state: "complete",
      availability: null,
      completions: completionsFor([2, 4, 6, 8, 9, 10]),
    },
    {
      id: "lunch-walk",
      name: "Lunch walk",
      period: "week",
      target: 3,
      completed: 1,
      lastDone: "Yesterday",
      state: "incomplete",
      availability: "Available until 2:00 PM",
      completions: completionsFor([3, 9]),
    },
    {
      id: "wake-up-early",
      name: "Wake up early",
      period: "week",
      target: 4,
      completed: 1,
      lastDone: "Yesterday",
      state: "unavailable",
      availability: "Available 12:00 AM–6:45 AM",
      completions: completionsFor([9]),
    },
    {
      id: "evening-yoga",
      name: "Evening yoga",
      period: "week",
      target: 4,
      completed: 1,
      lastDone: "Yesterday",
      state: "unavailable",
      availability: "Available 11:00 PM–3:00 AM",
      completions: completionsFor([9]),
    },
    {
      id: "water-plants",
      name: "Water plants",
      period: "week",
      target: 1,
      completed: 1,
      lastDone: "3d ago",
      state: "target-met",
      availability: null,
      completions: completionsFor([7]),
    },
    {
      id: "read-a-book",
      name: "Read a book",
      period: "week",
      target: 4,
      completed: 2,
      lastDone: "2d ago",
      state: "incomplete",
      availability: null,
      completions: completionsFor([4, 8]),
    },
    {
      id: "clean-air-purifiers",
      name: "Clean air purifiers",
      period: "month",
      target: 1,
      completed: 1,
      lastDone: "Today",
      state: "complete",
      availability: null,
      completions: completionsFor([10]),
    },
    {
      id: "whiten-teeth",
      name: "Whiten teeth",
      period: "month",
      target: 1,
      completed: 0,
      lastDone: "May 18",
      state: "incomplete",
      availability: null,
      completions: completionsFor([]),
    },
  ];

  const GROUPS = [
    { id: "today-focus", name: "Today Focus", routineIds: ["morning-yoga", "walk-the-dog", "lunch-walk", "wake-up-early"] },
    { id: "progress-edges", name: "Progress Edges", routineIds: ["evening-yoga", "water-plants", "read-a-book"] },
    { id: "monthly-maintenance", name: "Monthly Maintenance", routineIds: ["clean-air-purifiers", "whiten-teeth"] },
  ];

  window.ROUTINE_DATA = {
    today: { weekday: "Wednesday", label: "Wednesday, Jun 10", year: 2026, month: 6, day: 10 },
    weekdaySymbols: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
    monthTitle: "June 2026",
    daysInMonth: 30,
    firstWeekdayIndex: 1, // June 1, 2026 is a Monday (0=Sun)
    routines: ROUTINES,
    groups: GROUPS,
  };
})();
