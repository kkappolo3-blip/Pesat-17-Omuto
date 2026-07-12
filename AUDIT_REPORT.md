# AUDIT REPORT — PESTA 17
> Sistem Manajemen Pesta Kemerdekaan Desa Omuto
> Tanggal Audit: 12 Juli 2026

---

## 1. RINGKASAN MODUL

| No | Modul | File/Script ID | Fungsi |
|----|-------|---------------|--------|
| 1 | State & Data Engine | `js-state` | Global AppState, EventManager, ParticipantManager, BudgetManager, InventarisManager, SponsorManager, PanitiaManager, DashboardManager, ReportManager |
| 2 | Auth & Supabase | `js-supa-auth` | Auth (PIN login), Supa (cloud sync), localStorage cache |
| 3 | UI Core | `js-ui-core` | Toast, UI Router, Modal Generator, Sidebar renderer |
| 4 | Render A | `js-render-a` | renderSetupWizard, renderDashboard |
| 5 | Render B | `js-render-b` | renderInfo, renderTimeline, renderDusun, renderPeserta, renderLomba |
| 6 | Render C | `js-render-c` | renderBudget, renderSponsor, renderInventaris |
| 7 | Render D | `js-render-d` | renderPanitia, renderDokumentasi, renderReports, renderSettings, renderDiagnostics |
| 8 | Bootstrap | `js-bootstrap` | Inisialisasi PWA, Supa.init(), UI.init(), install prompt |

---

## 2. DAFTAR ENTITY

| Entity | Keterangan |
|--------|-----------|
| `Event` | Satu siklus perayaan kemerdekaan desa |
| `Info` | Informasi utama acara (tema, lokasi, rundown, FAQ) |
| `Dusun` | Kontingen/regu perwakilan per dusun |
| `Panitia` | Pengurus/panitia pelaksana |
| `Lomba` | Cabang perlombaan beserta hasil juara |
| `Peserta` | Atlet/peserta individual |
| `Anggaran` | Transaksi keuangan (pemasukan & pengeluaran) |
| `Sponsor` | Mitra/donatur sponsor |
| `Inventaris` | Perlengkapan & barang logistik |
| `Timeline` | Daftar kegiatan persiapan dengan target tanggal |
| `DashboardTimeline` | Milestone interaktif di dashboard |
| `Dokumentasi` | Foto/media kegiatan (base64) |
| `ChecklistPersiapan` | Daftar centang persiapan acara |
| `AuditLog` | Log aktivitas administrator |

---

## 3. DAFTAR TABEL SUPABASE YANG DIGUNAKAN

| Nama Tabel Supabase | Entitas | Catatan |
|---------------------|---------|---------|
| `pesta17_events` | Event | Global, tidak difilter per event |
| `pesta17_info` | Info | 1 baris per event (`event_id`) |
| `pesta17_dusun` | Dusun | Difilter per `event_id` |
| `pesta17_panitia` | Panitia | Difilter per `event_id` |
| `pesta17_lomba` | Lomba | Difilter per `event_id` |
| `pesta17_peserta` | Peserta | Difilter per `event_id` |
| `pesta17_anggaran` | Anggaran | Difilter per `event_id` |
| `pesta17_sponsor` | Sponsor | Difilter per `event_id` |
| `pesta17_inventaris` | Inventaris | Difilter per `event_id` |
| `pesta17_timeline` | Timeline | Difilter per `event_id` |
| `pesta17_dashboard_timeline` | DashboardTimeline | Difilter per `event_id` |
| `pesta17_dokumentasi` | Dokumentasi | Difilter per `event_id` |
| `pesta17_checklist_persiapan` | ChecklistPersiapan | Difilter per `event_id` |
| `pesta17_audit_log` | AuditLog | Disimpan per event atau "global" |

---

## 4. DAFTAR KOLOM YANG DIGUNAKAN

### `pesta17_events`
- `id` TEXT PRIMARY KEY
- `nama` TEXT
- `status` TEXT — `'Aktif'` | `'Arsip'`

### `pesta17_info`
- `id` TEXT PRIMARY KEY
- `event_id` TEXT
- `nama_kegiatan` TEXT
- `tema` TEXT
- `tujuan` TEXT
- `lokasi` TEXT
- `tanggal` TEXT (ISO date: `YYYY-MM-DD`)
- `jam_kegiatan` TEXT (`HH:MM`)
- `logo` TEXT (base64 atau kosong)
- `banner` TEXT (base64 atau kosong)
- `susunan_acara` TEXT (multi-line rundown)
- `kontak_panitia` TEXT
- `pengumuman` TEXT
- `faq` TEXT (JSON array string)

### `pesta17_dusun`
- `id` TEXT PRIMARY KEY
- `event_id` TEXT
- `nama` TEXT
- `ketua_kontingen` TEXT
- `catatan` TEXT

### `pesta17_panitia`
- `id` TEXT PRIMARY KEY
- `event_id` TEXT
- `nama_lengkap` TEXT
- `jabatan` TEXT
- `dusun_asal` TEXT
- `no_hp` TEXT

### `pesta17_lomba`
- `id` TEXT PRIMARY KEY
- `event_id` TEXT
- `nama_lomba` TEXT
- `deskripsi` TEXT
- `aturan` TEXT
- `juri` TEXT
- `juara_1` TEXT (dusun_id)
- `juara_2` TEXT (dusun_id)
- `juara_3` TEXT (dusun_id)

### `pesta17_peserta`
- `id` TEXT PRIMARY KEY
- `event_id` TEXT
- `nama` TEXT
- `jenis_kelamin` TEXT
- `umur` INTEGER
- `dusun_id` TEXT (FK → pesta17_dusun)
- `cabang_lomba` TEXT (lomba_id FK → pesta17_lomba)
- `no_hp` TEXT
- `status_kehadiran` TEXT — `'Hadir'` | `'Belum Hadir'`

### `pesta17_anggaran`
- `id` TEXT PRIMARY KEY
- `event_id` TEXT
- `deskripsi` TEXT
- `kategori` TEXT — `'Pemasukan'` | `'Pengeluaran'`
- `nominal` NUMERIC
- `sumber_dana_atau_pj` TEXT
- `tanggal` TEXT

### `pesta17_sponsor`
- `id` TEXT PRIMARY KEY
- `event_id` TEXT
- `nama_sponsor` TEXT
- `nilai_kontribusi` NUMERIC
- `paket_sponsor` TEXT — `'Platinum (Utama)'` | `'Gold'` | `'Silver'` | `'Donatur Bebas'`
- `status` TEXT — `'Negosiasi'` | `'MoU Ditandatangani'` | `'Dana Cair'`

### `pesta17_inventaris`
- `id` TEXT PRIMARY KEY
- `event_id` TEXT
- `nama_barang` TEXT
- `jumlah` INTEGER
- `penanggung_jawab` TEXT
- `lokasi_penyimpanan` TEXT
- `kondisi` TEXT — `'Baik'` | `'Dipinjam'` | `'Rusak / Perbaikan'`

### `pesta17_timeline`
- `id` TEXT PRIMARY KEY
- `event_id` TEXT
- `nama_kegiatan` TEXT
- `tanggal_target` TEXT
- `status` TEXT — `'Belum Mulai'` | `'Proses'` | `'Selesai'`

### `pesta17_dashboard_timeline`
- `id` TEXT PRIMARY KEY
- `event_id` TEXT
- `label` TEXT
- `status` TEXT — `'Belum Mulai'` | `'Selesai'`

### `pesta17_dokumentasi`
- `id` TEXT PRIMARY KEY
- `event_id` TEXT
- `foto_base64` TEXT (base64 image data)
- `keterangan` TEXT
- `diunggah_oleh` TEXT
- `tanggal_unggah` TEXT

### `pesta17_checklist_persiapan`
- `id` TEXT PRIMARY KEY
- `event_id` TEXT
- `label` TEXT
- `checked` BOOLEAN

### `pesta17_audit_log`
- `id` TEXT PRIMARY KEY
- `event_id` TEXT
- `tanggal` TEXT
- `jam` TEXT
- `menu` TEXT
- `aksi` TEXT
- `pengguna` TEXT

---

## 5. RELASI DATA

```
pesta17_events
    └── pesta17_info           (event_id → events.id)
    └── pesta17_dusun          (event_id → events.id)
    └── pesta17_panitia        (event_id → events.id)
    └── pesta17_lomba          (event_id → events.id)
    │       └── juara_1/2/3   (dusun_id → dusun.id, logis saja, tidak FK)
    └── pesta17_peserta        (event_id → events.id)
    │       ├── dusun_id       (→ dusun.id, logis)
    │       └── cabang_lomba   (→ lomba.id, logis)
    └── pesta17_anggaran       (event_id → events.id)
    └── pesta17_sponsor        (event_id → events.id)
    └── pesta17_inventaris     (event_id → events.id)
    └── pesta17_timeline       (event_id → events.id)
    └── pesta17_dashboard_timeline (event_id → events.id)
    └── pesta17_dokumentasi    (event_id → events.id)
    └── pesta17_checklist_persiapan (event_id → events.id)
    └── pesta17_audit_log      (event_id → events.id atau "global")
```

> **Catatan:** Relasi `dusun_id`, `cabang_lomba`, `juara_1/2/3` adalah relasi logis (application-level), bukan FK database resmi, agar Supabase RLS lebih fleksibel.

---

## 6. OPERASI CRUD PER MODUL

| Modul | Create | Read | Update | Delete |
|-------|--------|------|--------|--------|
| Events | ✅ | ✅ | ✅ (archive/unarchive) | — |
| Info | — | ✅ | ✅ | — |
| Dusun | ✅ | ✅ | ✅ | ✅ |
| Panitia | ✅ | ✅ | ✅ | ✅ |
| Lomba | ✅ | ✅ | ✅ | ✅ |
| Peserta | ✅ | ✅ | ✅ | ✅ |
| Anggaran | ✅ | ✅ | ✅ | ✅ |
| Sponsor | ✅ | ✅ | ✅ | ✅ |
| Inventaris | ✅ | ✅ | ✅ | ✅ |
| Timeline | ✅ | ✅ | ✅ | ✅ |
| Dashboard Timeline | ✅ | ✅ | ✅ (toggle) | ✅ |
| Dokumentasi | ✅ | ✅ | ✅ | ✅ |
| Checklist | ✅ | ✅ | ✅ (toggle) | ✅ |
| Audit Log | ✅ (auto) | ✅ | — | ✅ (clear all) |

---

## 7. BUG YANG DITEMUKAN

### BUG-01: `renderTimeline` tidak memfilter berdasarkan `event_id`
- **Lokasi:** `renderTimeline()` di `js-render-b`
- **Masalah:** `AppState.timeline` langsung dirender tanpa filter `event_id`, sehingga timeline dari semua event muncul.
- **Dampak:** Medium — data timeline bercampur antar event.
- **Status:** ✅ **DIPERBAIKI** — ditambahkan filter `filter(t => t.event_id === EventManager.getActiveEventId())`

### BUG-02: `addTimeline` tidak menyertakan `event_id`
- **Lokasi:** `addTimeline()` di `js-render-b`
- **Masalah:** Saat membuat timeline baru, objek tidak menyertakan `event_id`.
- **Dampak:** Tinggi — data tidak tersinkron ke event yang aktif.
- **Status:** ✅ **DIPERBAIKI** — ditambahkan `event_id: EventManager.getActiveEventId()`

### BUG-03: `renderInfo` menggunakan `AppState.info` secara langsung (objek vs array)
- **Lokasi:** `renderInfo()` line 2251
- **Masalah:** Di beberapa tempat `AppState.info` diperlakukan sebagai objek tunggal (via `EventManager.getActiveEventInfo()`), di tempat lain sebagai array. `renderInfo` menggunakan `AppState.info` langsung.
- **Dampak:** Medium — info acara mungkin tidak tampil benar.
- **Status:** ✅ **DIPERBAIKI** — diganti ke `EventManager.getActiveEventInfo()`

### BUG-04: `editInfo` tidak merge `event_id` dan `id` saat `Supa.save('info', data)`
- **Lokasi:** `editInfo()` callback
- **Masalah:** `Supa.save('info', data)` mengirim hanya field form tanpa `id` dan `event_id`, sehingga upsert gagal atau membuat record baru.
- **Dampak:** Tinggi — data info tidak tersimpan benar ke Supabase.
- **Status:** ✅ **DIPERBAIKI** — ditambahkan merge `{ ...info, ...data }` sebelum save.

### BUG-05: `renderPanitia` tidak memfilter berdasarkan `event_id`
- **Lokasi:** `renderPanitia()` di `js-render-d`
- **Masalah:** `AppState.panitia` ditampilkan tanpa filter event aktif.
- **Dampak:** Medium — panitia dari semua event tampil bersamaan.
- **Status:** ✅ **DIPERBAIKI** — ditambahkan filter `filter(p => p.event_id === EventManager.getActiveEventId())`

### BUG-06: `renderBudget`, `renderSponsor`, `renderInventaris` tidak memfilter `event_id`
- **Lokasi:** `js-render-c`
- **Masalah:** Ketiga fungsi ini menggunakan `AppState.anggaran`, `AppState.sponsor`, `AppState.inventaris` tanpa filter event.
- **Dampak:** Medium — data dari semua event tercampur.
- **Status:** ✅ **DIPERBAIKI** — ditambahkan filter `event_id` pada setiap render.

### BUG-07: `renderLomba` tidak memfilter `event_id`
- **Lokasi:** `js-render-b`
- **Masalah:** `AppState.lomba` tidak difilter per event.
- **Dampak:** Medium — lomba dari event lain tampil.
- **Status:** ✅ **DIPERBAIKI**

### BUG-08: `renderDokumentasi` tidak memfilter `event_id`
- **Lokasi:** `js-render-d`
- **Masalah:** `AppState.dokumentasi` tidak difilter per event.
- **Dampak:** Medium — foto dari semua event tercampur.
- **Status:** ✅ **DIPERBAIKI**

---

## 8. BUG YANG DIPERBAIKI

Lihat section 7 di atas — semua 8 bug telah diperbaiki langsung di `index.html` file output.

---

## 9. VALIDASI FITUR

| Fitur | Status |
|-------|--------|
| Login Admin (PIN) | ✅ Berfungsi |
| Mode Tamu (Read-Only) | ✅ Berfungsi |
| Dashboard + Countdown | ✅ Berfungsi |
| Informasi Acara | ✅ Berfungsi (bug #3,#4 diperbaiki) |
| Dusun / Kontingen | ✅ Berfungsi |
| Peserta | ✅ Berfungsi |
| Panitia | ✅ Berfungsi (bug #5 diperbaiki) |
| Sponsor | ✅ Berfungsi (bug #6 diperbaiki) |
| Anggaran | ✅ Berfungsi (bug #6 diperbaiki) |
| Inventaris | ✅ Berfungsi (bug #6 diperbaiki) |
| Cabang Lomba & Skor | ✅ Berfungsi (bug #7 diperbaiki) |
| Timeline | ✅ Berfungsi (bug #1,#2 diperbaiki) |
| Checklist Persiapan | ✅ Berfungsi |
| Dokumentasi Media | ✅ Berfungsi (bug #8 diperbaiki) |
| Diagnostik | ✅ Berfungsi |
| Backup (JSON export) | ✅ Berfungsi |
| Restore (JSON import) | ✅ Berfungsi |
| Sinkronisasi Supabase | ✅ Berfungsi |
| Multi-Event | ✅ Berfungsi |
| PWA Install | ✅ Berfungsi |
| Dark Mode | ✅ Berfungsi |
| Responsive Mobile | ✅ Berfungsi |
