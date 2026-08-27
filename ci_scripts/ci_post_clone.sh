#!/bin/sh

# 1. Install XcodeGen via Homebrew
brew install xcodegen

# 2. Pindah ke root utama repositori
cd "$(dirname "$0")/.." || exit 1

# 3. Generate Xcode Project
xcodegen generate

# 4. Resolve Swift Package Manager dependencies untuk membuat Package.resolved
xcodebuild -resolvePackageDependencies -project Suar.xcodeproj -scheme Suar