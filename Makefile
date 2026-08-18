ROOT := $(CURDIR)
BASH := $(if $(wildcard /bin/bash),/bin/bash,/usr/bin/bash)
REUSE_X64 ?= auto

.DEFAULT_GOAL := xcode

.PHONY: all xcode app launchers verify configure-wine build-wine runtime arm64-smoke-build x64-components x64-runtime linux-x86_64 linux-x86_64-x64 linux-x86_64-deps linux-x86_64-sdk linux-x86_64-freetype linux-x86_64-preflight linux-x86_64-ios-toolchain linux-x86_64-toolchain linux-x86_64-host-tools linux-x86_64-configure linux-x86_64-configure-pe linux-x86_64-build

# Default: build the iOS app via Xcode
xcode:
	xcodebuild -project Juice.xcodeproj -scheme Juice -sdk iphoneos -configuration Debug build

# Build the app via shell script (macOS or Linux cross-compile)
app: ; $(BASH) scripts/build-app.sh

# Build the launcher helpers (grape-trace-parent, grape-nested-wrapper)
launchers: ; $(BASH) scripts/build-launchers.sh

verify: ; $(BASH) scripts/verify-source.sh

# Wine build (requires cross-compile toolchain)
configure-wine: ; $(BASH) scripts/configure-wine-device.sh
build-wine: ; $(BASH) scripts/build-wine-device.sh
runtime: ; $(BASH) scripts/assemble-runtime.sh

# Smoke tests
arm64-smoke-build: ; $(BASH) scripts/build-arm64-smoke-linux.sh

# x86_64 Linux cross-build components
x64-components: ; $(BASH) scripts/build-experimental-x86_64-linux.sh
x64-runtime: ; $(BASH) scripts/assemble-x86_64-runtime.sh

# Full x86_64 Linux cross-build
linux-x86_64-sdk: ; $(BASH) scripts/fetch-ios-sdk-linux.sh
linux-x86_64-freetype:
	@if test "$${JUICE_WITHOUT_FREETYPE:-0}" != 1; then $(BASH) scripts/fetch-freetype-linux.sh; fi
linux-x86_64-deps: linux-x86_64-sdk linux-x86_64-freetype
linux-x86_64-ios-toolchain: linux-x86_64-sdk
	@v="$${JUICE_IOS_SDK_VERSION:-16.5}"; \
	 IOS_SDK="$${IOS_SDK:-$(ROOT)/build/deps/theos-sdks/iPhoneOS$$v.sdk}" \
	 $(BASH) scripts/bootstrap-ios-toolchain-linux.sh
linux-x86_64-toolchain: ; $(BASH) scripts/bootstrap-x86_64-toolchain-linux.sh
linux-x86_64-host-tools: ; $(BASH) scripts/build-wine-tools-linux.sh
linux-x86_64-preflight: linux-x86_64-deps
	@v="$${JUICE_IOS_SDK_VERSION:-16.5}"; \
	 sdk="$${IOS_SDK:-$(ROOT)/build/deps/theos-sdks/iPhoneOS$$v.sdk}"; \
	 toolchain="$${JUICE_IOS_TOOLCHAIN:-$(ROOT)/build/ios-toolchain}"; \
	 prefix="$${JUICE_IOS_TRIPLE_PREFIX:-arm-apple-darwin11}"; \
	 if test ! -x "$$toolchain/bin/$$prefix-clang"; then \
	   IOS_SDK="$$sdk" JUICE_IOS_TOOLCHAIN="$$toolchain" $(BASH) scripts/bootstrap-ios-toolchain-linux.sh; \
	 else \
	   echo "JUICE_IOS_TOOLCHAIN_REUSE path=$$toolchain"; \
	; fi; \
	 IOS_SDK="$$sdk" JUICE_IOS_TOOLCHAIN="$$toolchain" \
	 JUICE_IOS_ROOTLESS_SYSROOT="$${JUICE_IOS_ROOTLESS_SYSROOT:-$(ROOT)/build/deps/rootless-sysroot}" \
	 $(BASH) scripts/preflight-linux-x86_64.sh
linux-x86_64-configure: linux-x86_64-preflight linux-x86_64-host-tools
	@v="$${JUICE_IOS_SDK_VERSION:-16.5}"; \
	 IOS_SDK="$${IOS_SDK:-$(ROOT)/build/deps/theos-sdks/iPhoneOS$$v.sdk}" \
	 JUICE_IOS_ROOTLESS_SYSROOT="$${JUICE_IOS_ROOTLESS_SYSROOT:-$(ROOT)/build/deps/rootless-sysroot}" \
	 $(BASH) scripts/configure-wine-linux.sh
linux-x86_64-configure-pe: linux-x86_64-preflight linux-x86_64-host-tools linux-x86_64-toolchain
	@v="$${JUICE_IOS_SDK_VERSION:-16.5}"; \
	 IOS_SDK="$${IOS_SDK:-$(ROOT)/build/deps/theos-sdks/iPhoneOS$$v.sdk}" \
	 $(BASH) scripts/configure-wine-pe-linux.sh
linux-x86_64-build: ; $(BASH) scripts/build-wine-linux.sh
linux-x86_64: linux-x86_64-preflight
	@v="$${JUICE_IOS_SDK_VERSION:-16.5}"; \
	 IOS_SDK="$${IOS_SDK:-$(ROOT)/build/deps/theos-sdks/iPhoneOS$$v.sdk}" \
	 JUICE_IOS_ROOTLESS_SYSROOT="$${JUICE_IOS_ROOTLESS_SYSROOT:-$(ROOT)/build/deps/rootless-sysroot}" \
	 $(BASH) scripts/build-all-linux-x86_64.sh
linux-x86_64-x64: linux-x86_64-preflight
	@v="$${JUICE_IOS_SDK_VERSION:-16.5}"; \
	 IOS_SDK="$${IOS_SDK:-$(ROOT)/build/deps/theos-sdks/iPhoneOS$$v.sdk}" \
	 JUICE_IOS_ROOTLESS_SYSROOT="$${JUICE_IOS_ROOTLESS_SYSROOT:-$(ROOT)/build/deps/rootless-sysroot}" \
	 JUICE_BUILD_X64=1 JUICE_REQUIRE_WIN32="$${JUICE_REQUIRE_WIN32:-1}" $(BASH) scripts/build-all-linux-x86_64.sh
