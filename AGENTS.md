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
- Do not treat lint violations as acceptable because they were already present, outside documented repo-wide exceptions in the committed config.
- Do not add baselines, suppression comments, new config disables, or exclusions to avoid fixing real SwiftLint violations.
- `Scripts/lint.sh` is the canonical lint command. It runs SwiftLint in strict mode against the committed `.swiftlint.yml`.
- `file_length`, `function_body_length`, and `type_body_length` are intentionally disabled repo-wide in the committed config and should be treated as documented policy, not task-local exceptions.
- `./Scripts/validate.sh` is the canonical final validation command for completed work.
- If `./Scripts/validate.sh` fails, individual scripts such as `./Scripts/test-core.sh`, `./Scripts/test-ios.sh`, `./Scripts/check-format.sh`, `./Scripts/lint.sh`, and `./Scripts/build-ios.sh` may be used to isolate, dig into, or rerun specific failing stages.

## References

- [PROJECT_DESIGN.md](PROJECT_DESIGN.md)
- [PRODUCT_BRIEF.md](PRODUCT_BRIEF.md)
- [VISUAL_DESIGN.md](VISUAL_DESIGN.md)
- [DATA_DESIGN.md](DATA_DESIGN.md)
- [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md)
- [Docs/BUILD_AND_DEPLOY.md](Docs/BUILD_AND_DEPLOY.md) — command index for building, running, and shipping without Xcode
- [Docs/SIGNING_AND_DEPLOY_SETUP.md](Docs/SIGNING_AND_DEPLOY_SETUP.md) — one-time signing and deploy setup
