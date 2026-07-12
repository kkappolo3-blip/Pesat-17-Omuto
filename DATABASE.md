# DATABASE.md — PESTA 17
> Dokumentasi struktur database lengkap beserta penjelasan, relasi, dan alasan keberadaan setiap tabel

---

## Gambaran Umum

PESTA 17 menggunakan **Supabase (PostgreSQL)** sebagai database cloud opsional. Aplikasi juga berjalan penuh secara offline menggunakan `localStorage` browser sebagai cache lokal dengan nama key `pesta17_cache_<tabel>`.

Seluruh tabel menggunakan **prefix `pesta17_`** untuk menghindari konflik dengan tabel lain di project Supabase yang sama.

Sistem mendukung **Multi-Event**: satu project Supabase dapat mengelola beberapa siklus perayaan kemerdekaan dari tahun ke tahun. Setiap entitas (kecuali `pesta17_events`) memiliki kolom `event_id` yang mengikat data ke satu event.

---

## Diagram Relasi

```
pesta17_events (1)
    │
    ├──(1:1)── pesta17_info
    │
    ├──(1:N)── pesta17_dusun ──────────────────────────────────┐
    │                                                           │ (logis)
    ├──(1:N)── pesta17_panitia                                  │
    │                                                           │
    ├──(1:N)── pesta17_lomba ◄─────────────────────────────────┤
    │              │ juara_1/2/3 → dusun_id (logis)             │
    │                                                           │
    ├──(1:N)── pesta17_peserta ──── dusun_id (logis) ──────────┘
    │               └────────── cabang_lomba → lomba.id (logis)
    │
    ├──(1:N)── pesta17_anggaran
    ├──(1:N)── pesta17_sponsor
    ├──(1:N)── pesta17_inventaris
    ├──(1:N)── pesta17_timeline
    ├──(1:N)── pesta17_dashboard_timeline
    ├──(1:N)── pesta17_dokumentasi
    ├──(1:N)── pesta17_checklist_persiapan
    └──(1:N)── pesta17_audit_log
```

> **Catatan "relasi logis":** Kolom `dusun_id`, `cabang_lomba`, dan `juara_1/2/3` tidak didefinisikan sebagai `FOREIGN KEY` di level database. Ini disengaja agar:
> 1. Supabase RLS lebih fleksibel
> 2. Data tidak broken saat dusun/lomba dihapus (data historis tetap ada)
> 3. Restore backup JSON tidak butuh urutan insert tertentu

---

## Detail Tabel

### 1. `pesta17_events`
**Alasan keberadaan:** Fondasi multi-event sistem. Setiap siklus perayaan kemerdekaan (HUT RI 80, 81, 82, dst.) tersimpan sebagai satu baris event.

| Kolom | Tipe | Keterangan |
|-------|------|-----------|
| `id` | TEXT PK | ID unik event, format: `evt-<timestamp>` |
| `nama` | TEXT | Nama event, contoh: "Pesta Kemerdekaan HUT RI 81 Desa Omuto" |
| `status` | TEXT | `'Aktif'` — dapat diedit \| `'Arsip'` — read-only |

---

### 2. `pesta17_info`
**Alasan keberadaan:** Menyimpan metadata utama satu event — informasi yang ditampilkan ke publik (tamu/warga) di halaman Dashboard dan Informasi Acara.

| Kolom | Tipe | Keterangan |
|-------|------|-----------|
| `id` | TEXT PK | Format: `inf-<timestamp>` |
| `event_id` | TEXT FK | Relasi ke `pesta17_events.id` |
| `nama_kegiatan` | TEXT | Nama resmi kegiatan |
| `tema` | TEXT | Tema kemerdekaan tahun ini |
| `tujuan` | TEXT | Tujuan dan deskripsi kegiatan |
| `lokasi` | TEXT | Lokasi pelaksanaan |
| `tanggal` | TEXT | Tanggal `YYYY-MM-DD` |
| `jam_kegiatan` | TEXT | Jam mulai `HH:MM` |
| `logo` | TEXT | Logo acara (base64 atau kosong) |
| `banner` | TEXT | Banner latar belakang (base64 atau kosong) |
| `susunan_acara` | TEXT | Rundown multi-baris |
| `kontak_panitia` | TEXT | Info kontak panitia |
| `pengumuman` | TEXT | Pengumuman aktif untuk warga |
| `faq` | TEXT | JSON string array: `[{q: "...", a: "..."}]` |

---

### 3. `pesta17_dusun`
**Alasan keberadaan:** Menyimpan daftar kontingen/regu per dusun. Digunakan sebagai referensi di peserta (dusun_id) dan lomba (juara_1/2/3). Juga menjadi dasar kalkulasi klasemen leaderboard.

| Kolom | Tipe | Keterangan |
|-------|------|-----------|
| `id` | TEXT PK | Format: `dsn-<timestamp>` |
| `event_id` | TEXT FK | Relasi ke `pesta17_events.id` |
| `nama` | TEXT | Nama dusun |
| `ketua_kontingen` | TEXT | Nama ketua kontingen/dusun |
| `catatan` | TEXT | Catatan tambahan |

---

### 4. `pesta17_panitia`
**Alasan keberadaan:** Menyimpan struktur kepengurusan panitia pelaksana. Ditampilkan ke publik (Mode Tamu) untuk transparansi kepengurusan.

| Kolom | Tipe | Keterangan |
|-------|------|-----------|
| `id` | TEXT PK | Format: `pn-<timestamp>` |
| `event_id` | TEXT FK | Relasi ke `pesta17_events.id` |
| `nama_lengkap` | TEXT | Nama pengurus |
| `jabatan` | TEXT | Jabatan/divisi (pilihan tetap: Ketua Panitia, Wakil, Sekretaris, dll.) |
| `dusun_asal` | TEXT | Dusun asal pengurus |
| `no_hp` | TEXT | Nomor WhatsApp |

---

### 5. `pesta17_lomba`
**Alasan keberadaan:** Mendefinisikan cabang perlombaan beserta aturan dan hasil pemenang. Juara 1/2/3 disimpan sebagai `dusun_id` untuk kalkulasi leaderboard otomatis (5 poin juara 1, 3 poin juara 2, 1 poin juara 3).

| Kolom | Tipe | Keterangan |
|-------|------|-----------|
| `id` | TEXT PK | Format: `lmb-<timestamp>` |
| `event_id` | TEXT FK | Relasi ke `pesta17_events.id` |
| `nama_lomba` | TEXT | Nama cabang lomba |
| `deskripsi` | TEXT | Deskripsi singkat |
| `aturan` | TEXT | Regulasi & aturan teknis |
| `juri` | TEXT | Nama penilai/juri |
| `juara_1` | TEXT | `dusun_id` peraih juara 1 |
| `juara_2` | TEXT | `dusun_id` peraih juara 2 |
| `juara_3` | TEXT | `dusun_id` peraih juara 3 |

---

### 6. `pesta17_peserta`
**Alasan keberadaan:** Daftar atlet/peserta individual per cabang lomba. Digunakan untuk kehadiran (toggle hadir/belum) dan rekapitulasi peserta per dusun/lomba.

| Kolom | Tipe | Keterangan |
|-------|------|-----------|
| `id` | TEXT PK | Format: `pst-<timestamp>` |
| `event_id` | TEXT FK | Relasi ke `pesta17_events.id` |
| `nama` | TEXT | Nama peserta |
| `jenis_kelamin` | TEXT | `'Laki-laki'` \| `'Perempuan'` |
| `umur` | INTEGER | Usia peserta |
| `dusun_id` | TEXT | ID dusun asal (logis → dusun.id) |
| `cabang_lomba` | TEXT | ID lomba diikuti (logis → lomba.id) |
| `no_hp` | TEXT | Nomor kontak |
| `status_kehadiran` | TEXT | `'Hadir'` \| `'Belum Hadir'` |

---

### 7. `pesta17_anggaran`
**Alasan keberadaan:** Transparansi keuangan — mencatat setiap transaksi pemasukan dan pengeluaran. Ditampilkan ke publik (Mode Tamu) untuk akuntabilitas. Digunakan pula di Dashboard untuk chart keuangan.

| Kolom | Tipe | Keterangan |
|-------|------|-----------|
| `id` | TEXT PK | Format: `bg-<timestamp>` |
| `event_id` | TEXT FK | Relasi ke `pesta17_events.id` |
| `deskripsi` | TEXT | Keterangan transaksi |
| `kategori` | TEXT | `'Pemasukan'` \| `'Pengeluaran'` |
| `nominal` | NUMERIC | Jumlah rupiah |
| `sumber_dana_atau_pj` | TEXT | Sumber dana atau penanggungjawab |
| `tanggal` | TEXT | Tanggal pembukuan `YYYY-MM-DD` |

---

### 8. `pesta17_sponsor`
**Alasan keberadaan:** Manajemen kerjasama sponsor dan donatur. Status kerjasama ditampilkan ke publik untuk transparansi pendanaan desa.

| Kolom | Tipe | Keterangan |
|-------|------|-----------|
| `id` | TEXT PK | Format: `sp-<timestamp>` |
| `event_id` | TEXT FK | Relasi ke `pesta17_events.id` |
| `nama_sponsor` | TEXT | Nama perusahaan/perorangan |
| `nilai_kontribusi` | NUMERIC | Nilai kontribusi tunai (rupiah) |
| `paket_sponsor` | TEXT | `'Platinum (Utama)'` \| `'Gold'` \| `'Silver'` \| `'Donatur Bebas'` |
| `status` | TEXT | `'Negosiasi'` \| `'MoU Ditandatangani'` \| `'Dana Cair'` |

---

### 9. `pesta17_inventaris`
**Alasan keberadaan:** Manajemen logistik perlengkapan (tenda, sound system, piala, dll.). Admin dapat melacak kondisi barang dan siapa yang bertanggung jawab.

| Kolom | Tipe | Keterangan |
|-------|------|-----------|
| `id` | TEXT PK | Format: `inv-<timestamp>` |
| `event_id` | TEXT FK | Relasi ke `pesta17_events.id` |
| `nama_barang` | TEXT | Nama barang/perlengkapan |
| `jumlah` | INTEGER | Jumlah unit |
| `penanggung_jawab` | TEXT | Nama PJ |
| `lokasi_penyimpanan` | TEXT | Tempat penyimpanan |
| `kondisi` | TEXT | `'Baik'` \| `'Dipinjam'` \| `'Rusak / Perbaikan'` |

---

### 10. `pesta17_timeline`
**Alasan keberadaan:** Perencanaan kegiatan persiapan dengan target tanggal dan status. Admin dapat mengubah status langsung dari tabel (toggle Belum Mulai → Proses → Selesai). Berbeda dengan `dashboard_timeline` yang hanya binary Selesai/Belum.

| Kolom | Tipe | Keterangan |
|-------|------|-----------|
| `id` | TEXT PK | Format: `tl-<timestamp>` |
| `event_id` | TEXT FK | Relasi ke `pesta17_events.id` |
| `nama_kegiatan` | TEXT | Nama kegiatan/persiapan |
| `tanggal_target` | TEXT | Target selesai `YYYY-MM-DD` |
| `status` | TEXT | `'Belum Mulai'` \| `'Proses'` \| `'Selesai'` |

---

### 11. `pesta17_dashboard_timeline`
**Alasan keberadaan:** Milestone interaktif di Dashboard (bukan di halaman Timeline). Tampil sebagai progress bar visual di Dashboard untuk gambaran cepat progress persiapan acara. Lebih sederhana dari `timeline` (hanya binary Selesai/Belum Mulai).

| Kolom | Tipe | Keterangan |
|-------|------|-----------|
| `id` | TEXT PK | Format: `mst-<timestamp>` |
| `event_id` | TEXT FK | Relasi ke `pesta17_events.id` |
| `label` | TEXT | Label milestone (contoh: "H-30 Rapat Panitia") |
| `status` | TEXT | `'Belum Mulai'` \| `'Selesai'` |

---

### 12. `pesta17_dokumentasi`
**Alasan keberadaan:** Galeri foto kegiatan. Foto disimpan sebagai base64 langsung di database (tidak ada storage bucket). Ditampilkan ke publik (Mode Tamu).

| Kolom | Tipe | Keterangan |
|-------|------|-----------|
| `id` | TEXT PK | Format: `dk-<timestamp>` |
| `event_id` | TEXT FK | Relasi ke `pesta17_events.id` |
| `foto_base64` | TEXT | Foto dalam format base64 (dapat besar) |
| `keterangan` | TEXT | Caption/keterangan foto |
| `diunggah_oleh` | TEXT | Nama pengunggah/PJ |
| `tanggal_unggah` | TEXT | Tanggal `YYYY-MM-DD` |

> ⚠️ **Perhatian:** Kolom `foto_base64` dapat sangat besar. Jika performa lambat, pertimbangkan migrasi ke Supabase Storage Bucket di versi mendatang.

---

### 13. `pesta17_checklist_persiapan`
**Alasan keberadaan:** Daftar centang persiapan acara yang ditampilkan di Dashboard. Admin dapat menambah, mencentang, dan menghapus item. Berbeda dari `timeline` yang punya tanggal target — checklist ini lebih informal/cepat.

| Kolom | Tipe | Keterangan |
|-------|------|-----------|
| `id` | TEXT PK | Format: `chk-<timestamp>` |
| `event_id` | TEXT FK | Relasi ke `pesta17_events.id` |
| `label` | TEXT | Deskripsi item persiapan |
| `checked` | BOOLEAN | Status tercentang (`true`/`false`) |

---

### 14. `pesta17_audit_log`
**Alasan keberadaan:** Rekam jejak seluruh aktivitas administrator. Diisi otomatis oleh sistem setiap ada operasi CRUD. Ditampilkan di halaman Diagnostik. Maksimal 100 baris disimpan di memori lokal (entri lama dihapus otomatis).

| Kolom | Tipe | Keterangan |
|-------|------|-----------|
| `id` | TEXT PK | Format: `log-<timestamp>-<random>` |
| `event_id` | TEXT | Event terkait, atau `'global'` |
| `tanggal` | TEXT | Tanggal lokal `DD/MM/YYYY` |
| `jam` | TEXT | Waktu `HH:MM:SS` |
| `menu` | TEXT | Nama modul/halaman (contoh: "Peserta", "Anggaran") |
| `aksi` | TEXT | Deskripsi tindakan |
| `pengguna` | TEXT | Nama pengguna (default: `'Admin'`) |

---

## Catatan Penting untuk Supabase

1. **RLS (Row Level Security) wajib diaktifkan** — semua tabel menggunakan `anon key` karena tidak ada autentikasi Supabase Auth. Pastikan policies untuk SELECT, INSERT, UPDATE, DELETE telah dibuat.

2. **Upsert digunakan untuk semua operasi simpan** — aplikasi menggunakan `supabase.from(table).upsert(data)` sehingga database harus mendukung upsert berdasarkan primary key `id`.

3. **Tidak ada trigger atau function database** — semua logika bisnis (kalkulasi leaderboard, validasi) dijalankan di sisi client (JavaScript browser).

4. **Foto base64 bisa sangat besar** — kolom `foto_base64` di `pesta17_dokumentasi` tidak diberi batasan ukuran. Monitor ukuran database Supabase jika banyak foto diunggah.

5. **Multi-event isolation** — semua query data dari cloud menggunakan `SELECT *` lalu difilter di JavaScript berdasarkan `event_id` aktif. Ini menjaga kesederhanaan kode tapi berarti seluruh data ter-download ke client.
