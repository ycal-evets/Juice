# Juice

Juice is an experimental Wine GUI runtime for Windows applications on iPhone and iPad. The bundled Wine runtime is named **Grape**. This repository contains the UIKit app, launch helpers, complete modified Wine 11.13 source, the same Wine delta as an auditable patch, packaging assets, FEX integration, and the build system used to produce Juice.

Juice currently provides:

- a lightweight native ARM64 `JuiceGUI.exe` desktop inside one Wine desktop surface, with an application list, taskbar, custom BMP wallpaper, Files, and installer controls;
- a UIKit surface for Wine windows and BGRA frames;
- touch-to-Wine pointer input with selectable left and right buttons;
- direct Windows ARM64 application execution;
- AMD64/x86-64 execution through ARM64EC Wine and FEX;
- safe portable ZIP import with adjacent DLLs and assets preserved;
- fullscreen display;
- UTF-16 text and Backspace, Tab, and Enter transport to a touched control;
- persistent Wine prefixes plus MSI and ordinary setup-EXE support;
- a versioned, non-framebuffer control channel from `wineios.drv` to UIKit for file import and host-routed launches;
- persistent app and Wine-driver diagnostic logs.

## Supported target

Juice targets **non-jailbroken** iOS/iPadOS devices. The app is sideloaded via Xcode, AltStore, or SideStore and requires **JIT** for Wine's dynamic recompilation. No jailbreak, TrollStore, or CoreTrust bypass is needed.

JIT is enabled through one of:
- **Xcode debugging**: attach the Xcode debugger to the app, which grants `CS_DEBUGGED`
- **SideStore JIT**: use SideStore's JIT enabling feature (AltJIT)
- **AltStore**: sideload with JIT support enabled

The app includes `grape-trace-parent`, a ptrace-based JIT handshake that completes Wine's `PT_TRACE_ME` / `CS_DEBUGGED` handshake, enabling anonymous RWX memory mappings required for JIT compilation.

## Build — Xcode (primary method)

Requires macOS with Xcode 15+ and iOS SDK.

### Quick build

```sh
git clone https://github.com/ExoCore-Kernel/Juice.git
cd Juice
make xcode
```

Or open `Juice.xcodeproj` in Xcode and build directly.

### Manual build

```sh
xcodebuild -project Juice.xcodeproj -scheme Juice -sdk iphoneos -configuration Debug build
```

### Build without Xcode (macOS or Linux)

```sh
make app      # Build the iOS app
make launchers  # Build grape-trace-parent and grape-nested-wrapper
```

## Build — x86_64 Linux cross-compile

The full Wine runtime can be cross-compiled from x86_64 Linux:

```sh
sudo apt install -y \
  build-essential clang lld cmake git python3 bison flex m4 curl file rsync \
  zip unzip xz-utils tar pkg-config autoconf automake libtool \
  libssl-dev libxml2-dev zlib1g-dev

git clone https://github.com/ExoCore-Kernel/Juice.git
cd Juice
make
```

This builds the complete runtime including ARM64 Wine, ARM64 Windows PE modules, and the ARM64EC/FEX x86-64 translation layer.

## Installing and running

### Via Xcode

1. Open `Juice.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run to your connected device
4. **JIT is required**: while the app is running, attach the debugger from Xcode (Debug → Attach to Process) or use SideStore's JIT enabling

### Via SideStore

1. Build the IPA: `xcodebuild -project Juice.xcodeproj -scheme Juice -sdk iphoneos -configuration Release archive`
2. Export the archive as an IPA
3. Install via SideStore
4. Enable JIT through SideStore's JIT feature

### Wine runtime

The Wine runtime (Grape) must be bundled with the app. Place the compiled Grape runtime in `Juice.app/Grape/` (or `Grape-X64/` for x86-64 support). The runtime contains the Wine loader, server, DLLs, and prefix template.

## Repository map

- `app`: UIKit GUI, input bridge, file picker, and ZIP extractor.
- `wine`: complete Wine 11.13 source with the Juice changes already applied.
- `patches`: the reproducible Wine delta against the recorded upstream commit.
- `launcher`: source for the trace parent and nested launcher.
- `toolchain`: iOS compiler wrappers and PE resource-wrapper sources.
- `scripts`: build, runtime staging, and verification scripts.
- `config`: entitlements, plists, base revision, pinned toolchain/FEX settings, and runtime module manifest.
- `packaging`: minimal Wine prefix template.
- `proofs`: historical frames and diagnostic logs.
- `legacy`: curated source-only material recovered from the scattered iPad tree; it is provenance, not an active build input.

## Source integrity

The full Wine tree is based on commit `6eb2e4c32cc9e271856146df11ed3a5c2cf29234`. Running:

```sh
make verify
```

checks source syntax and safety markers, validates the runtime module manifest, and proves that `patches/wine-ios.patch` reverses cleanly from the included modified Wine tree.

## Security and licensing

Juice runs Windows programs without the normal iOS app sandbox and exposes the host filesystem through Wine's Z: drive. Only run software you trust. Read [Security](SECURITY.md) before testing or distributing it.

Wine remains LGPL-2.1-or-later under its in-tree license files. Juice-original code is licensed under the MIT license.
