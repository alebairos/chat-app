# Flutter Project Makefile
# FT-212: Android build support with automatic namespace patching

.PHONY: help deps clean build-android build-ios test patch-android

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

deps: ## Install dependencies and patch Android namespaces
	@echo "📦 Installing Flutter dependencies..."
	@flutter pub get
	@echo ""
	@echo "🔧 Patching Android namespaces..."
	@./scripts/patch_android_namespaces.sh

clean: ## Clean build artifacts
	@flutter clean

build-android: deps ## Build Android APK (debug)
	@flutter build apk --debug

build-android-release: deps ## Build Android APK (release)
	@flutter build apk --release

build-ios: ## Build iOS app
	@flutter build ios

test: ## Run all tests
	@flutter test

patch-android: ## Apply Android namespace patches only
	@./scripts/patch_android_namespaces.sh

run-android: deps ## Run app on Android device
	@flutter run -d android

run-ios: ## Run app on iOS device
	@flutter run -d ios

distribute-android: ## Build and distribute Android via Firebase App Distribution
	@./scripts/release_firebase_android.sh

