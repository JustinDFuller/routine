.PHONY: generate app-icons format check-format lint test-core test-scripts build-ios run-ios test-ios validate archive-ios export-ios release-preflight deploy-device upload-ios release

generate:
	./Scripts/generate-project.sh

app-icons:
	swift Scripts/generate-app-icons.swift

format:
	./Scripts/format.sh

check-format:
	./Scripts/check-format.sh

lint:
	./Scripts/lint.sh

test-core:
	./Scripts/test-core.sh

test-scripts:
	./Scripts/test-ios-script-tests.sh

build-ios:
	./Scripts/build-ios.sh

run-ios:
	./Scripts/run-ios.sh

test-ios:
	./Scripts/test-ios.sh

validate:
	./Scripts/validate.sh

archive-ios:
	CURRENT_PROJECT_VERSION=$${CURRENT_PROJECT_VERSION:?Set CURRENT_PROJECT_VERSION} ./Scripts/archive-ios.sh

export-ios:
	./Scripts/export-ios.sh

release-preflight:
	CURRENT_PROJECT_VERSION=$${CURRENT_PROJECT_VERSION:?Set CURRENT_PROJECT_VERSION} ./Scripts/release-preflight.sh

deploy-device:
	./Scripts/deploy-device.sh

upload-ios:
	./Scripts/upload-ios.sh

release:
	CURRENT_PROJECT_VERSION=$${CURRENT_PROJECT_VERSION:?Set CURRENT_PROJECT_VERSION} ./Scripts/release-preflight.sh
	./Scripts/upload-ios.sh
