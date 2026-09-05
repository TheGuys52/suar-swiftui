#!/bin/sh

# Hentikan eksekusi jika ada satu perintah yang gagal
set -e

# 1. Tambahkan PATH agar brew & xcodegen dapat ditemukan
export PATH=$PATH:/opt/homebrew/bin:/usr/local/bin
export HOMEBREW_NO_AUTO_UPDATE=1

# 2. Pindah direktori ke root utama repositori
cd "$(dirname "$0")/.." || exit 1

# 3. Install XcodeGen
brew install xcodegen

# 4. Buat direktori dan file Config.xcconfig dari Environment Variable
mkdir -p Suar/SupportingFiles/Config
cat <<EOF > Suar/SupportingFiles/Config/Config.xcconfig
LLM_OLAGON_API_KEY = $LLM_OLAGON_API_KEY
EOF

# 5. Generate Xcode Project
xcodegen generate