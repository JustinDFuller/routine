# routine

Routine is a personal iPhone app for tracking recurring habits and routines in a simple, visual way.

The product and system have been scoped in the planning documents below. Implementation should now follow [PROJECT_DESIGN.md](PROJECT_DESIGN.md), which breaks the MVP into dependency-ordered milestones and marks the current step.

## References

- [PROJECT_DESIGN.md](PROJECT_DESIGN.md)
- [PRODUCT_BRIEF.md](PRODUCT_BRIEF.md)
- [VISUAL_DESIGN.md](VISUAL_DESIGN.md)
- [DATA_DESIGN.md](DATA_DESIGN.md)
- [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md)

## Local Development

Use the scripts directly or the matching `make` targets:

- Generate the Xcode project: `./Scripts/generate-project.sh` or `make generate`
- Format Swift sources: `./Scripts/format.sh` or `make format`
- Check formatting: `./Scripts/check-format.sh` or `make check-format`
- Run SwiftLint: `./Scripts/lint.sh` or `make lint`
- Run portable package tests: `./Scripts/test-core.sh` or `make test-core`
- Build the app for a generic iOS destination when available: `./Scripts/build-ios.sh` or `make build-ios`
- Run iOS tests with an explicit destination: `IOS_TEST_DESTINATION='platform=iOS Simulator,name=iPhone 16' ./Scripts/test-ios.sh` or `IOS_TEST_DESTINATION='platform=iOS Simulator,name=iPhone 16' make test-ios`
- Run the full local validation chain: `./Scripts/validate.sh` or `make validate`

To run the app interactively, generate the project and open `Routine.xcodeproj` in Xcode, then select the `RoutineApp` scheme and a simulator or connected iPhone destination.

## Implementation Workflow

Each implementation session should:

1. Read [AGENTS.md](AGENTS.md), [PROJECT_DESIGN.md](PROJECT_DESIGN.md), and the four source specs.
2. Work only on the milestone marked `CURRENT` in [PROJECT_DESIGN.md](PROJECT_DESIGN.md).
3. Update [PROJECT_DESIGN.md](PROJECT_DESIGN.md) when the milestone is complete.
4. Commit, push, open a pull request, and stop.
