# native.cr Makefile

.PHONY: help build build-android build-ios clean test spec docs install uninstall release doctor

VERSION := 0.1.0
CRYSTAL := crystal
BUILD_DIR := .build
DIST_DIR := dist

help:
	@echo "native.cr Makefile"
	@echo ""
	@echo "Commands:"
	@echo "  make build          Build native.cr CLI for current platform"
	@echo "  make build-android  Build Android engine"
	@echo "  make build-ios      Build iOS engine"
	@echo "  make clean          Remove build artifacts"
	@echo "  make test           Run all tests"
	@echo "  make spec           Run specs"
	@echo "  make docs           Generate documentation"
	@echo "  make install        Install native.cr CLI"
	@echo "  make uninstall      Uninstall native.cr CLI"
	@echo "  make doctor         Check toolchain installation"
	@echo "  make format         Format Crystal code"
	@echo "  make lint           Lint Crystal code"

build:
	@echo "Building native.cr v$(VERSION)"
	@mkdir -p $(BUILD_DIR)
	$(CRYSTAL) build src/native.cr -o $(BUILD_DIR)/native.cr --release
	@echo "Build complete: $(BUILD_DIR)/native.cr"

build-android:
	@echo "Building Android engine"
	@mkdir -p $(BUILD_DIR)/android
	@cd src/native/engine/android && $(MAKE)

build-ios:
	@echo "Building iOS engine"
	@mkdir -p $(BUILD_DIR)/ios
	@cd src/native/engine/ios && $(MAKE)

clean:
	@echo "Cleaning build artifacts"
	@rm -rf $(BUILD_DIR)
	@rm -rf $(DIST_DIR)
	@rm -rf .native_cache
	@rm -rf .shards
	@rm -rf doc
	@find . -name "*.o" -delete
	@find . -name "*.dSYM" -exec rm -rf {} + 2>/dev/null || true
	@echo "Clean complete"

test: spec

spec:
	@echo "Running specs"
	$(CRYSTAL) spec

docs:
	@echo "Generating documentation"
	$(CRYSTAL) docs
	@echo "Documentation generated in doc/"

install: build
	@echo "Installing native.cr to /usr/local/bin"
	@cp $(BUILD_DIR)/native.cr /usr/local/bin/
	@chmod +x /usr/local/bin/native.cr
	@echo "Installed: native.cr v$(VERSION)"

uninstall:
	@echo "Uninstalling native.cr"
	@rm -f /usr/local/bin/native.cr
	@echo "Uninstalled"

doctor:
	@echo "Checking toolchain..."
	@$(CRYSTAL) --version || echo "Crystal not found"
	@echo ""
	@echo "Run 'native.cr doctor' for full check"

format:
	@echo "Formatting Crystal files"
	$(CRYSTAL) tool format src/

lint:
	@echo "Linting Crystal files"
	$(CRYSTAL) tool format --check src/

release: clean test docs
	@echo "Creating release v$(VERSION)"
	@mkdir -p $(DIST_DIR)
	$(CRYSTAL) build src/native.cr -o $(DIST_DIR)/native.cr --release --static
	@echo "Release binary: $(DIST_DIR)/native.cr"

bench:
	@echo "Running benchmarks"
	$(CRYSTAL) run benchmark/benchmark.cr --release

watch:
	@echo "Watching for changes..."
	@watchexec -e cr -- crystal run src/native.cr
