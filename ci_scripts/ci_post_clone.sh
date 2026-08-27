#!/bin/sh

# 1. Install XcodeGen via Homebrew
brew install xcodegen

# 2. Pindah direktori ke root utama repositori
cd "$CI_PRIMARY_REPOSITORY_DIR" || exit 1

# 3. Generate Xcode Project
xcodegen generate