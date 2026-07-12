# PESTA 17 — Sistem Manajemen Pesta Kemerdekaan Desa

Aplikasi PWA (Progressive Web App) untuk manajemen terpadu Pesta Kemerdekaan Desa: panitia, peserta, lomba, anggaran, dokumentasi, dan sinkronisasi Supabase.

---

## 📁 Isi Paket Ini

| File | Keterangan |
|------|-----------|
| `index.html` | Aplikasi utama (semua modul dalam satu file, bug fixes diterapkan) |
| `manifest.webmanifest` | Konfigurasi PWA |
| `service-worker.js` | Service worker untuk offline support |
| `offline.html` | Halaman fallback saat offline |
| `icon-192.png` | Ikon aplikasi 192×192 |
| `icon-512.png` | Ikon aplikasi 512×512 |
| `maskable-icon.png` | Ikon maskable untuk Android |
| `AUDIT_REPORT.md` | Laporan audit lengkap: modul, entity, bug ditemukan & diperbaiki |
| `database.sql` | SQL lengkap untuk Supabase (fresh install) |
| `migration.sql` | SQL migrasi aman untuk database yang sudah ada |
| `DATABASE.md` | Dokumentasi setiap tabel, relasi, dan alasan keberadaannya |

---

## 🚀 Cara Deploy

### Hosting Statis (Netlify / Vercel / GitHub Pages)
1. Upload semua file ke dalam satu folder
2. Deploy folder tersebut sebagai static site
3. Pastikan semua file ada di root domain (bukan subfolder)

### Lokal (Pengembangan)
```bash
# Gunakan server lokal (bukan double-click index.html karena PWA perlu HTTPS/localhost)
npx serve .
# atau
python3 -m http.server 3000
```

---

## 🗄️ Setup Supabase (Opsional)

Aplikasi berjalan penuh **tanpa Supabase** menggunakan localStorage. Supabase digunakan untuk backup cloud dan kolaborasi multi-perangkat.

1. Buat project baru di [supabase.com](https://supabase.com)
2. Buka **SQL Editor** dan jalankan `database.sql` (fresh install) ATAU `migration.sql` (jika sudah ada database sebelumnya)
3. Buka aplikasi → **Pengaturan Sistem**
4. Login sebagai Admin (kode default: `88040773`)
5. Isi **Supabase URL** dan **Supabase Anon Key**
6. Klik **Uji Koneksi** → **Simpan Setelan**

---

## 🔐 Login Admin

- **Kode default:** `88040773`
- Ganti kode di: **Pengaturan Sistem → Kode Keamanan Admin PIN**
- Tanpa login: Mode Tamu (hanya baca data)

---

## 🐛 Bug yang Diperbaiki (dari versi sebelumnya)

| # | Bug | Status |
|---|-----|--------|
| 1 | Timeline tidak difilter per event aktif | ✅ Diperbaiki |
| 2 | Tambah Timeline tidak menyertakan `event_id` | ✅ Diperbaiki |
| 3 | Halaman Info Acara menggunakan data salah | ✅ Diperbaiki |
| 4 | Edit Info Acara tidak menyimpan dengan benar ke Supabase | ✅ Diperbaiki |
| 5 | Panitia tidak difilter per event aktif | ✅ Diperbaiki |
| 6 | Anggaran/Sponsor/Inventaris tidak difilter per event aktif | ✅ Diperbaiki |
| 7 | Cabang Lomba tidak difilter per event aktif | ✅ Diperbaiki |
| 8 | Dokumentasi tidak difilter per event aktif | ✅ Diperbaiki |

---

## 📋 Fitur Lengkap

- ✅ Login Admin (PIN) + Mode Tamu (Read-Only)
- ✅ Multi-Event (kelola banyak siklus perayaan)
- ✅ Dashboard dengan Countdown, Grafik Keuangan, Checklist, Milestone
- ✅ Informasi Acara (tema, rundown, FAQ, pengumuman)
- ✅ Manajemen Dusun/Kontingen + Klasemen Leaderboard
- ✅ Daftar Peserta + Absensi Kehadiran
- ✅ Cabang Lomba & Input Juara + Kalkulasi Poin Otomatis
- ✅ Anggaran Keuangan Transparan
- ✅ Sponsor & Mitra
- ✅ Inventaris Barang & Logistik
- ✅ Timeline Persiapan
- ✅ Galeri Dokumentasi Foto
- ✅ Backup JSON & Restore
- ✅ Ekspor CSV & Cetak PDF
- ✅ Sinkronisasi Supabase Cloud
- ✅ Audit Log Administrator
- ✅ Dark Mode
- ✅ Responsive Mobile
- ✅ PWA (Install ke Home Screen)
- ✅ Offline Support
