#!/bin/sh

# Hentikan eksekusi jika ada satu perintah yang gagal
set -e

# 1. Matikan auto-update brew agar proses install xcodegen jauh lebih cepat
export HOMEBREW_NO_AUTO_UPDATE=1
brew install xcodegen

# 2. Pindah direktori ke root utama repositori
cd "$(dirname "$0")/.." || exit 1

# 3. Buat direktori dan file Config.xcconfig dari Environment Variable Xcode Cloud
# (Sesuaikan path folder "Suar/SupportingFiles/Config" sesuai struktur folder proyekmu)
mkdir -p Suar/SupportingFiles/Config
cat <<EOF > Suar/SupportingFiles/Config/Config.xcconfig
LLM_OLAGON_API_KEY = $LLM_OLAGON_API_KEY
EOF

# 4. Generate Xcode Project (sekarang file Config.xcconfig sudah tersedia)
xcodegen generate

# 5. Resolve Package Dependencies
xcodebuild -resolvePackageDependencies -project Suar.xcodeproj -scheme Suar