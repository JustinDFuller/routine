# routine

This repository is building a personal iPhone app that helps track recurring routines in a visual, low-friction way.

Use [PROJECT_DESIGN.md](PROJECT_DESIGN.md) as the implementation roadmap and current milestone tracker.

For product and technical decisions, use the product brief as the source of truth for scope and behavior, the visual design spec for the app's visual and interaction language, the data design spec for data structures, storage, domain methods, views, and routing, and the system design for implementation architecture, build, deployment, testing, debugging, resilience, performance, security, accessibility, and tooling.

## Agent Workflow

Before implementing, read [PROJECT_DESIGN.md](PROJECT_DESIGN.md) and work only on the milestone marked `CURRENT` unless the user explicitly redirects you.

When a milestone is complete:

1. Update [PROJECT_DESIGN.md](PROJECT_DESIGN.md) by marking the completed milestone `DONE`, advancing the next milestone to `CURRENT`, and updating the roadmap table and current milestone line.
2. Run narrow preflight validation as needed during implementation, then run `./Scripts/validate.sh` as the final completion validation and report any skipped lines it emits.
3. Commit, push, open a pull request, and stop.

## Validation Policy

- SwiftLint warnings and errors must be fixed before completion.
- Do not treat lint violations as acceptable because they were already present.
- Do not use baselines, suppression comments, config disables, or exclusions to avoid fixing real SwiftLint violations.
- `Scripts/lint.sh` is the canonical lint command and must pass in strict mode.
- `./Scripts/validate.sh` is the canonical final validation command for completed work.
- Individual scripts such as `./Scripts/test-core.sh`, `./Scripts/test-ios.sh`, `./Scripts/check-format.sh`, `./Scripts/lint.sh`, and `./Scripts/build-ios.sh` are allowed for narrow preflight checks while implementing.

## References

- [PROJECT_DESIGN.md](PROJECT_DESIGN.md)
- [PRODUCT_BRIEF.md](PRODUCT_BRIEF.md)
- [VISUAL_DESIGN.md](VISUAL_DESIGN.md)
- [DATA_DESIGN.md](DATA_DESIGN.md)
- [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md)
