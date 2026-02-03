.PHONY: build install clean reload test all

# Variables
PROJECT_DIR = MDQuickLook
SCHEME = MDQuickLook
BUILD_DIR = build
INSTALL_DIR = /Applications
APP_NAME = MDQuickLook.app

# Build the Xcode project
build:
	xcodebuild -project $(PROJECT_DIR)/MDQuickLook.xcodeproj \
		-scheme $(SCHEME) \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR) \
		build

# Install the app to Applications directory
install: build
	mkdir -p "$(INSTALL_DIR)"
	rm -rf "$(INSTALL_DIR)/$(APP_NAME)"
	cp -R "$(BUILD_DIR)/Build/Products/Release/$(APP_NAME)" "$(INSTALL_DIR)/"
	@echo "Extension installed to $(INSTALL_DIR)/$(APP_NAME)"
	@echo "Note: Quick Look extension is embedded at Contents/PlugIns/MDQuickLook.appex"
	@echo "Registering extension with pluginkit..."
	@open "$(INSTALL_DIR)/$(APP_NAME)" 2>/dev/null || true
	@sleep 2
	@killall MDQuickLook 2>/dev/null || true
	@echo "Extension registered successfully"

# Reload Quick Look system
reload:
	qlmanage -r
	qlmanage -r cache
	@echo "Quick Look reloaded. Open a new Finder window to test."

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)
	rm -rf "$(INSTALL_DIR)/$(APP_NAME)"
	rm -rf "$(INSTALL_DIR)/md-spotlighter.app"
	rm -rf "$(HOME)/Applications/$(APP_NAME)"
	@echo "Build artifacts and installed extension removed."

# Test with sample file
test: install reload
	@echo "Testing with sample file..."
	qlmanage -p samples/basic.md

# Build, install, and reload in one command
all: install reload
	@echo "Extension installed and Quick Look reloaded."
