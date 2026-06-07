.PHONY: generate format check-format lint test-core build-ios test-ios validate

generate:
	./Scripts/generate-project.sh

format:
	./Scripts/format.sh

check-format:
	./Scripts/check-format.sh

lint:
	./Scripts/lint.sh

test-core:
	./Scripts/test-core.sh

build-ios:
	./Scripts/build-ios.sh

test-ios:
	./Scripts/test-ios.sh

validate:
	./Scripts/validate.sh
