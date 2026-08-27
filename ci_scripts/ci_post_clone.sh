#!/bin/sh

# 1. Install XcodeGen via Homebrew
brew install xcodegen

# 2. Pindah direktori ke root utama repositori (naik 1 level dari ci_scripts)
cd "$(dirname "$0")/.." || exit 1

# 3. Generate Xcode Project
xcodegen generate