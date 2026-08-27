#!/bin/sh

# 1. Install XcodeGen via Homebrew
brew install xcodegen

# 2. Pindah direktori ke root utama repositori
cd "$(dirname "$0")/.." || exit 1

# 3. Generate Xcode Project
xcodegen generate

# 4. Aktifkan kembali izin download package otomatis di Xcode Cloud
defaults write com.apple.dt.Xcode IDEDisableAutomaticPackageResolution -bool NO
defaults write com.apple.dt.Xcode IDEPackageOnlyUseVersionsFromResolvedFile -bool NO

# 5. Resolve dan generate Package.resolved
xcodebuild -resolvePackageDependencies -project Suar.xcodeproj -scheme Suar