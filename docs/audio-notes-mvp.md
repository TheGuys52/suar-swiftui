# Catatan suara per halaman — MVP

Branch: `f/audio-notes`, berisi perubahan audio di atas commit onboarding pada `f/onboarding`.

## Urutan PR

1. PR onboarding: base `main`, compare `f/onboarding`.
2. PR audio: base `f/onboarding`, compare `f/audio-notes` selama onboarding belum digabungkan.
3. Setelah onboarding masuk `main`, arahkan PR audio ke `main`. Jika onboarding di-squash/rebase saat merge, jalankan `git fetch origin` lalu `git rebase --onto origin/main f/onboarding f/audio-notes` agar hanya commit audio yang dibawa. Jika branch audio sudah dipush, pembaruan hasil rebase memerlukan `git push --force-with-lease origin f/audio-notes`.

Commit gabungan awal disimpan lokal pada `codex/backup-audio-before-split`. Backup ini juga memuat artefak dan konfigurasi lokal lama; bukan branch untuk PR atau dipush.

## Cara mencoba

1. Buka naskah dan pilih halaman.
2. Buka menu titik tiga di kanan atas.
3. Pilih **Rekam catatan suara**, lalu izinkan mikrofon.
4. Pilih **Hentikan**; rekaman otomatis disimpan.
5. Rekam lagi untuk menambah catatan; rekaman sebelumnya tetap ada.
6. Gunakan **Putar/Jeda** untuk mendengarkan. Menu titik tiga pada setiap catatan berisi **Ubah nama** dan **Hapus**.
7. Tutup panel, pindah halaman, lalu kembali. Menu **Catatan suara (jumlah)** membuka daftar untuk halaman aktif.

Isi audio bebas: ide, saran, pengingat, atau eksplorasi pembacaan. Catatan terkait ke ID halaman, bukan dialog.

## Batas MVP

- Beberapa catatan per halaman, nama otomatis yang bisa diubah, tanggal dan durasi.
- Ubah nama hanya memperbarui judul catatan; berkas audio tetap sama. Nama kosong ditolak.
- Audio tersimpan lokal di Application Support; metadata di SwiftData.
- Hanya satu rekaman atau pemutaran yang aktif.
- Perekaman berhenti dan mencoba menyimpan ketika aplikasi masuk background, audio terinterupsi, atau perangkat audio dilepas.
- Tidak melanjutkan perekaman secara otomatis setelah gangguan.
- Draf yang gagal disimpan dapat dicoba simpan kembali atau dihapus. Manifest lokal memungkinkan pemulihan setelah aplikasi dibuka ulang.
- Panel tidak bisa ditutup selama merekam, meminta izin, atau memiliki draf yang belum diselesaikan.
- Belum mencakup impor audio, waveform, transkripsi, sinkronisasi teks, atau rekaman di background.

## Struktur

- `AudioNote`: relasi ke `ScriptPage`, nomor catatan, tanggal, durasi, dan nama berkas.
- `AudioNoteFileStore`: berkas audio, manifest draf, dan pemulihan berkas jika penghapusan database gagal.
- `AudioNoteRepository`: operasi SwiftData dalam context tersendiri agar rollback tidak mengubah state reader.
- `AudioNoteService`: izin mikrofon, AVAudioRecorder, AVAudioPlayer, dan gangguan audio.
- `AudioNotesViewModel` / `AudioNotesView`: alur catatan dan panel yang dibuka reader.
- `project.yml`: deklarasi izin mikrofon; jalankan `xcodegen generate` setelah menambah file.

## Verifikasi

- Tujuh test `AudioNoteRepositoryTests` lulus: persistensi beberapa rekaman antarhalaman, rename tanpa mengubah audio dan penolakan nama kosong, migrasi schema onboarding, draf saat save gagal, penolakan relasi script yang salah, penghapusan, dan pemulihan berkas jika transaksi gagal.
- Pada pemeriksaan seluruh suite sebelum penambahan rename: 11 test dijalankan, 9 lulus dan 2 test parser gagal pada ekspektasi tokoh `8. WANITA` (PDF digital dan scan). Implementasi parser tidak diubah oleh fitur audio.
- Migrasi diuji menggunakan snapshot model `f/onboarding`, termasuk isi dialog dan posisi baca terakhir.
- Uji manual simulator: menu kanan atas, dua rekaman di satu halaman, pemutaran, isolasi halaman, dan penyimpanan saat masuk background.
- Uji manual rename: nama lama terisi di dialog, Simpan nonaktif untuk nama kosong, nama baru muncul di daftar dan label Putar/Opsi. Rekaman existing tetap tersedia setelah pembaruan schema.
- Lint ketat untuk file fitur audio dan test repository bersih.
- Build normal masih diblokir pelanggaran SwiftLint lama di parser/mock/test lain. Kompilasi dan unit test diverifikasi dengan PATH sementara yang tidak memuat SwiftLint. Konfigurasi lint repository tidak diubah.
- Audio dengan VoiceOver, headphone fisik, panggilan telepon, dan penolakan izin mikrofon masih perlu diuji pada iPhone sebelum penggunaan nyata. Label kontrol terlihat pada accessibility tree simulator; itu belum membuktikan kualitas penggunaan dengan VoiceOver.

Perubahan kecil pendukung: tiga pemanggilan test parser diberi `onProgress: nil` agar target test dapat dikompilasi, dan context `ScriptRepository` ditandai MainActor untuk operasi database.
