```markdown
# Suar (iOS Application)

Aplikasi iOS pembaca naskah teater ramah VoiceOver dan aksesibilitas berbasis ekstraksi Vision OCR dan pemilah entitas skrip cerdas[cite: 1]. Repositori ini menggunakan arsitektur **Feature-Driven SwiftUI MVVM-C** serta manajemen project deterministik via **XcodeGen**.

---

## 🛠 Tech Stack & Tools

* **UI & Architecture:** SwiftUI, MVVM-C (Model-View-ViewModel-Coordinator), Feature-Driven[cite: 2]
* **Persistensi & Framework:** SwiftData, Vision, PDFKit, Accessibility Rotor[cite: 1]
* **Project Generator:** [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`project.yml`)[cite: 2]
* **Linter & Formatter:** [SwiftLint](https://github.com/realm/SwiftLint) (`.swiftlint.yml`)[cite: 2]
* **Git Hooks Manager:** [Lefthook](https://github.com/evilmartians/lefthook) (`lefthook.yml`)[cite: 2]
* **Debugging & Network Logs:** [Pulse](https://github.com/kean/Pulse) / PulseUI[cite: 2]
* **Unit Testing:** [ViewInspector](https://github.com/nalexn/ViewInspector)[cite: 2]

---

## 🚀 First-Time Setup (Onboarding)

Pastikan Anda telah menginstal [Homebrew](https://brew.sh/) sebelum memulai.

### 1. Install Dependencies
Jalankan di Terminal untuk memasang seluruh build tools yang dibutuhkan:
```bash
brew install xcodegen swiftlint lefthook

```

### 2. Clone Repositori

```bash
git clone [https://github.com/theguys52/suar-swiftui.git](https://github.com/theguys52/suar-swiftui.git)
cd suar-swiftui

```

### 3. Setup Konfigurasi Lokal

Salin file template `.xcconfig` agar Xcode dapat membaca environment configuration lokal:

```bash
cp Suar/Suar/SupportingFiles/Config/ConfigExample.xcconfig Suar/Suar/SupportingFiles/Config/Secrets.xcconfig

```

### 4. Aktifkan Git Hooks

Daftarkan hook validasi linter dan format pesan commit ke Git lokal:

```bash
lefthook install

```

### 5. Generate Xcode Project

Buat file `Suar.xcodeproj` secara otomatis:

```bash
xcodegen generate

```

### 6. Buka Project & Build

Buka file `Suar.xcodeproj` di Xcode, tunggu resolusi Swift Package selesai, lalu tekan **Cmd + B** untuk memastikan build berhasil.

---

## 🔄 Feature Lifecycle & Workflow

### 1. Membuat Branch Baru

Selalu sinkronkan branch `main` lokal Anda sebelum mulai mengerjakan fitur baru:

```bash
git checkout main
git pull origin main
git checkout -b feat/nama-fitur

```

*Format branch:* `feat/<nama-fitur>`, `fix/<nama-bug>`, atau `chore/<tugas-tooling>`.

### 2. Menambah Modul & File Baru

Setiap fitur baru diletakkan di bawah direktori `Suar/Suar/Features/`:

```text
Suar/Suar/Features/<NamaFitur>/
├── Coordinators/
├── Views/
└── ViewModels/

```

> **Penting:** Jika Anda menambahkan file atau folder baru di luar Xcode (misal melalui VS Code atau Terminal), jalankan `xcodegen generate` agar file baru tersebut otomatis terdaftar ke dalam target kompilasi Xcode.
> 
> 

### 3. Commit Kode (Conventional Commits)

Lakukan staging dan commit:

```bash
git add .
git commit -m "feat(reader): implement discrete dialogue block navigation"

```

Lefthook akan secara otomatis menjalankan dua tahap validasi:

* **Pre-Commit:** Menjalankan `swiftlint --fix` pada file yang di-stage.


* **Commit-Msg:** Memeriksa format pesan commit. Commit akan **ditolak** jika tidak mematuhi awalan berikut:


* `feat:` atau `feat(scope):` — Penambahan fitur baru


* `fix:` atau `fix(scope):` — Perbaikan bug


* `chore:` — Pemeliharaan tooling, package, config


* `refactor:` — Perapian kode tanpa mengubah fungsionalitas


* `docs:` — Perubahan dokumentasi/README





### 4. Push & Buat Pull Request (PR)

```bash
git push -u origin feat/nama-fitur

```

Buat Pull Request ke branch `main`. Pastikan minimal 1 anggota tim me-review dan menyetujui kode sebelum di-merge.

---

## 📌 Aturan Main Repositori

1. **Dilarang Commit `.xcodeproj` / `.xcworkspace`:** File project Xcode diabaikan oleh `.gitignore`. Konfigurasi target, build phases, dan dependencies sepenuhnya dikelola di `project.yml`.


2. **Sinkronisasi Otomatis:** Setelah menjalankan `git pull` atau berpindah branch, hook `post-merge` dan `post-checkout` Lefthook akan otomatis mengeksekusi `xcodegen generate`.


3. **Accessibility Standard:** Seluruh elemen UI kustom wajib memiliki minimal touch target $44 \times 44\text{ pt}$ dan label/hint VoiceOver yang eksplisit.



```

```