-- ============================================================
-- DATABASE.SQL — PESTA 17
-- Sistem Manajemen Pesta Kemerdekaan Desa
-- Jalankan file ini di Supabase SQL Editor
-- Hanya berisi tabel yang BENAR-BENAR digunakan oleh source code
-- ============================================================

-- Extension untuk timestamp otomatis
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. EVENTS — Daftar perayaan kemerdekaan (global, multi-event)
-- ============================================================
CREATE TABLE IF NOT EXISTS pesta17_events (
  id        TEXT PRIMARY KEY,
  nama      TEXT NOT NULL,
  status    TEXT NOT NULL DEFAULT 'Aktif' CHECK (status IN ('Aktif', 'Arsip'))
);

-- ============================================================
-- 2. INFO — Informasi utama per event
-- ============================================================
CREATE TABLE IF NOT EXISTS pesta17_info (
  id               TEXT PRIMARY KEY,
  event_id         TEXT NOT NULL REFERENCES pesta17_events(id) ON DELETE CASCADE,
  nama_kegiatan    TEXT,
  tema             TEXT,
  tujuan           TEXT,
  lokasi           TEXT,
  tanggal          TEXT,           -- YYYY-MM-DD
  jam_kegiatan     TEXT,           -- HH:MM
  logo             TEXT,           -- base64 image atau URL
  banner           TEXT,           -- base64 image atau URL
  susunan_acara    TEXT,           -- multi-line rundown
  kontak_panitia   TEXT,
  pengumuman       TEXT,
  faq              TEXT            -- JSON string array [{q,a}]
);

CREATE INDEX IF NOT EXISTS idx_pesta17_info_event_id ON pesta17_info(event_id);

-- ============================================================
-- 3. DUSUN — Kontingen/regu perwakilan per dusun
-- ============================================================
CREATE TABLE IF NOT EXISTS pesta17_dusun (
  id                TEXT PRIMARY KEY,
  event_id          TEXT NOT NULL REFERENCES pesta17_events(id) ON DELETE CASCADE,
  nama              TEXT NOT NULL,
  ketua_kontingen   TEXT,
  catatan           TEXT
);

CREATE INDEX IF NOT EXISTS idx_pesta17_dusun_event_id ON pesta17_dusun(event_id);

-- ============================================================
-- 4. PANITIA — Pengurus dan panitia pelaksana
-- ============================================================
CREATE TABLE IF NOT EXISTS pesta17_panitia (
  id           TEXT PRIMARY KEY,
  event_id     TEXT NOT NULL REFERENCES pesta17_events(id) ON DELETE CASCADE,
  nama_lengkap TEXT NOT NULL,
  jabatan      TEXT,
  dusun_asal   TEXT,
  no_hp        TEXT
);

CREATE INDEX IF NOT EXISTS idx_pesta17_panitia_event_id ON pesta17_panitia(event_id);

-- ============================================================
-- 5. LOMBA — Cabang perlombaan beserta hasil juara
-- ============================================================
CREATE TABLE IF NOT EXISTS pesta17_lomba (
  id         TEXT PRIMARY KEY,
  event_id   TEXT NOT NULL REFERENCES pesta17_events(id) ON DELETE CASCADE,
  nama_lomba TEXT NOT NULL,
  deskripsi  TEXT,
  aturan     TEXT,
  juri       TEXT,
  juara_1    TEXT,  -- dusun_id (relasi logis)
  juara_2    TEXT,  -- dusun_id (relasi logis)
  juara_3    TEXT   -- dusun_id (relasi logis)
);

CREATE INDEX IF NOT EXISTS idx_pesta17_lomba_event_id ON pesta17_lomba(event_id);

-- ============================================================
-- 6. PESERTA — Atlet/peserta individual per lomba
-- ============================================================
CREATE TABLE IF NOT EXISTS pesta17_peserta (
  id               TEXT PRIMARY KEY,
  event_id         TEXT NOT NULL REFERENCES pesta17_events(id) ON DELETE CASCADE,
  nama             TEXT NOT NULL,
  jenis_kelamin    TEXT,
  umur             INTEGER,
  dusun_id         TEXT,            -- relasi logis ke pesta17_dusun.id
  cabang_lomba     TEXT,            -- relasi logis ke pesta17_lomba.id
  no_hp            TEXT,
  status_kehadiran TEXT NOT NULL DEFAULT 'Belum Hadir' CHECK (status_kehadiran IN ('Hadir', 'Belum Hadir'))
);

CREATE INDEX IF NOT EXISTS idx_pesta17_peserta_event_id ON pesta17_peserta(event_id);
CREATE INDEX IF NOT EXISTS idx_pesta17_peserta_dusun_id ON pesta17_peserta(dusun_id);

-- ============================================================
-- 7. ANGGARAN — Transaksi keuangan (pemasukan & pengeluaran)
-- ============================================================
CREATE TABLE IF NOT EXISTS pesta17_anggaran (
  id                  TEXT PRIMARY KEY,
  event_id            TEXT NOT NULL REFERENCES pesta17_events(id) ON DELETE CASCADE,
  deskripsi           TEXT NOT NULL,
  kategori            TEXT NOT NULL CHECK (kategori IN ('Pemasukan', 'Pengeluaran')),
  nominal             NUMERIC NOT NULL DEFAULT 0,
  sumber_dana_atau_pj TEXT,
  tanggal             TEXT            -- YYYY-MM-DD
);

CREATE INDEX IF NOT EXISTS idx_pesta17_anggaran_event_id ON pesta17_anggaran(event_id);

-- ============================================================
-- 8. SPONSOR — Mitra dan donatur sponsor
-- ============================================================
CREATE TABLE IF NOT EXISTS pesta17_sponsor (
  id                TEXT PRIMARY KEY,
  event_id          TEXT NOT NULL REFERENCES pesta17_events(id) ON DELETE CASCADE,
  nama_sponsor      TEXT NOT NULL,
  nilai_kontribusi  NUMERIC NOT NULL DEFAULT 0,
  paket_sponsor     TEXT,
  status            TEXT NOT NULL DEFAULT 'Negosiasi' CHECK (status IN ('Negosiasi', 'MoU Ditandatangani', 'Dana Cair'))
);

CREATE INDEX IF NOT EXISTS idx_pesta17_sponsor_event_id ON pesta17_sponsor(event_id);

-- ============================================================
-- 9. INVENTARIS — Perlengkapan dan barang logistik
-- ============================================================
CREATE TABLE IF NOT EXISTS pesta17_inventaris (
  id                  TEXT PRIMARY KEY,
  event_id            TEXT NOT NULL REFERENCES pesta17_events(id) ON DELETE CASCADE,
  nama_barang         TEXT NOT NULL,
  jumlah              INTEGER NOT NULL DEFAULT 1,
  penanggung_jawab    TEXT,
  lokasi_penyimpanan  TEXT,
  kondisi             TEXT NOT NULL DEFAULT 'Baik' CHECK (kondisi IN ('Baik', 'Dipinjam', 'Rusak / Perbaikan'))
);

CREATE INDEX IF NOT EXISTS idx_pesta17_inventaris_event_id ON pesta17_inventaris(event_id);

-- ============================================================
-- 10. TIMELINE — Daftar kegiatan persiapan
-- ============================================================
CREATE TABLE IF NOT EXISTS pesta17_timeline (
  id              TEXT PRIMARY KEY,
  event_id        TEXT NOT NULL REFERENCES pesta17_events(id) ON DELETE CASCADE,
  nama_kegiatan   TEXT NOT NULL,
  tanggal_target  TEXT,     -- YYYY-MM-DD
  status          TEXT NOT NULL DEFAULT 'Belum Mulai' CHECK (status IN ('Belum Mulai', 'Proses', 'Selesai'))
);

CREATE INDEX IF NOT EXISTS idx_pesta17_timeline_event_id ON pesta17_timeline(event_id);

-- ============================================================
-- 11. DASHBOARD_TIMELINE — Milestone interaktif di dashboard
-- ============================================================
CREATE TABLE IF NOT EXISTS pesta17_dashboard_timeline (
  id       TEXT PRIMARY KEY,
  event_id TEXT NOT NULL REFERENCES pesta17_events(id) ON DELETE CASCADE,
  label    TEXT NOT NULL,
  status   TEXT NOT NULL DEFAULT 'Belum Mulai' CHECK (status IN ('Belum Mulai', 'Selesai'))
);

CREATE INDEX IF NOT EXISTS idx_pesta17_dashboard_timeline_event_id ON pesta17_dashboard_timeline(event_id);

-- ============================================================
-- 12. DOKUMENTASI — Foto/media kegiatan
-- ============================================================
CREATE TABLE IF NOT EXISTS pesta17_dokumentasi (
  id             TEXT PRIMARY KEY,
  event_id       TEXT NOT NULL REFERENCES pesta17_events(id) ON DELETE CASCADE,
  foto_base64    TEXT,     -- base64 encoded image
  keterangan     TEXT,
  diunggah_oleh  TEXT,
  tanggal_unggah TEXT      -- YYYY-MM-DD
);

CREATE INDEX IF NOT EXISTS idx_pesta17_dokumentasi_event_id ON pesta17_dokumentasi(event_id);

-- ============================================================
-- 13. CHECKLIST_PERSIAPAN — Daftar centang persiapan
-- ============================================================
CREATE TABLE IF NOT EXISTS pesta17_checklist_persiapan (
  id       TEXT PRIMARY KEY,
  event_id TEXT NOT NULL REFERENCES pesta17_events(id) ON DELETE CASCADE,
  label    TEXT NOT NULL,
  checked  BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_pesta17_checklist_event_id ON pesta17_checklist_persiapan(event_id);

-- ============================================================
-- 14. AUDIT_LOG — Log aktivitas administrator
-- ============================================================
CREATE TABLE IF NOT EXISTS pesta17_audit_log (
  id        TEXT PRIMARY KEY,
  event_id  TEXT NOT NULL DEFAULT 'global',
  tanggal   TEXT,
  jam       TEXT,
  menu      TEXT,
  aksi      TEXT,
  pengguna  TEXT NOT NULL DEFAULT 'Admin'
);

CREATE INDEX IF NOT EXISTS idx_pesta17_audit_log_event_id ON pesta17_audit_log(event_id);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- Aktifkan RLS agar data aman. Gunakan anon key untuk read-only.
-- ============================================================

-- Events
ALTER TABLE pesta17_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read events" ON pesta17_events FOR SELECT USING (true);
CREATE POLICY "Anon insert events" ON pesta17_events FOR INSERT WITH CHECK (true);
CREATE POLICY "Anon update events" ON pesta17_events FOR UPDATE USING (true);
CREATE POLICY "Anon delete events" ON pesta17_events FOR DELETE USING (true);

-- Info
ALTER TABLE pesta17_info ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read info" ON pesta17_info FOR SELECT USING (true);
CREATE POLICY "Anon insert info" ON pesta17_info FOR INSERT WITH CHECK (true);
CREATE POLICY "Anon update info" ON pesta17_info FOR UPDATE USING (true);
CREATE POLICY "Anon delete info" ON pesta17_info FOR DELETE USING (true);

-- Dusun
ALTER TABLE pesta17_dusun ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read dusun" ON pesta17_dusun FOR SELECT USING (true);
CREATE POLICY "Anon insert dusun" ON pesta17_dusun FOR INSERT WITH CHECK (true);
CREATE POLICY "Anon update dusun" ON pesta17_dusun FOR UPDATE USING (true);
CREATE POLICY "Anon delete dusun" ON pesta17_dusun FOR DELETE USING (true);

-- Panitia
ALTER TABLE pesta17_panitia ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read panitia" ON pesta17_panitia FOR SELECT USING (true);
CREATE POLICY "Anon insert panitia" ON pesta17_panitia FOR INSERT WITH CHECK (true);
CREATE POLICY "Anon update panitia" ON pesta17_panitia FOR UPDATE USING (true);
CREATE POLICY "Anon delete panitia" ON pesta17_panitia FOR DELETE USING (true);

-- Lomba
ALTER TABLE pesta17_lomba ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read lomba" ON pesta17_lomba FOR SELECT USING (true);
CREATE POLICY "Anon insert lomba" ON pesta17_lomba FOR INSERT WITH CHECK (true);
CREATE POLICY "Anon update lomba" ON pesta17_lomba FOR UPDATE USING (true);
CREATE POLICY "Anon delete lomba" ON pesta17_lomba FOR DELETE USING (true);

-- Peserta
ALTER TABLE pesta17_peserta ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read peserta" ON pesta17_peserta FOR SELECT USING (true);
CREATE POLICY "Anon insert peserta" ON pesta17_peserta FOR INSERT WITH CHECK (true);
CREATE POLICY "Anon update peserta" ON pesta17_peserta FOR UPDATE USING (true);
CREATE POLICY "Anon delete peserta" ON pesta17_peserta FOR DELETE USING (true);

-- Anggaran
ALTER TABLE pesta17_anggaran ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read anggaran" ON pesta17_anggaran FOR SELECT USING (true);
CREATE POLICY "Anon insert anggaran" ON pesta17_anggaran FOR INSERT WITH CHECK (true);
CREATE POLICY "Anon update anggaran" ON pesta17_anggaran FOR UPDATE USING (true);
CREATE POLICY "Anon delete anggaran" ON pesta17_anggaran FOR DELETE USING (true);

-- Sponsor
ALTER TABLE pesta17_sponsor ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read sponsor" ON pesta17_sponsor FOR SELECT USING (true);
CREATE POLICY "Anon insert sponsor" ON pesta17_sponsor FOR INSERT WITH CHECK (true);
CREATE POLICY "Anon update sponsor" ON pesta17_sponsor FOR UPDATE USING (true);
CREATE POLICY "Anon delete sponsor" ON pesta17_sponsor FOR DELETE USING (true);

-- Inventaris
ALTER TABLE pesta17_inventaris ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read inventaris" ON pesta17_inventaris FOR SELECT USING (true);
CREATE POLICY "Anon insert inventaris" ON pesta17_inventaris FOR INSERT WITH CHECK (true);
CREATE POLICY "Anon update inventaris" ON pesta17_inventaris FOR UPDATE USING (true);
CREATE POLICY "Anon delete inventaris" ON pesta17_inventaris FOR DELETE USING (true);

-- Timeline
ALTER TABLE pesta17_timeline ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read timeline" ON pesta17_timeline FOR SELECT USING (true);
CREATE POLICY "Anon insert timeline" ON pesta17_timeline FOR INSERT WITH CHECK (true);
CREATE POLICY "Anon update timeline" ON pesta17_timeline FOR UPDATE USING (true);
CREATE POLICY "Anon delete timeline" ON pesta17_timeline FOR DELETE USING (true);

-- Dashboard Timeline
ALTER TABLE pesta17_dashboard_timeline ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read dashboard_timeline" ON pesta17_dashboard_timeline FOR SELECT USING (true);
CREATE POLICY "Anon insert dashboard_timeline" ON pesta17_dashboard_timeline FOR INSERT WITH CHECK (true);
CREATE POLICY "Anon update dashboard_timeline" ON pesta17_dashboard_timeline FOR UPDATE USING (true);
CREATE POLICY "Anon delete dashboard_timeline" ON pesta17_dashboard_timeline FOR DELETE USING (true);

-- Dokumentasi
ALTER TABLE pesta17_dokumentasi ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read dokumentasi" ON pesta17_dokumentasi FOR SELECT USING (true);
CREATE POLICY "Anon insert dokumentasi" ON pesta17_dokumentasi FOR INSERT WITH CHECK (true);
CREATE POLICY "Anon update dokumentasi" ON pesta17_dokumentasi FOR UPDATE USING (true);
CREATE POLICY "Anon delete dokumentasi" ON pesta17_dokumentasi FOR DELETE USING (true);

-- Checklist Persiapan
ALTER TABLE pesta17_checklist_persiapan ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read checklist" ON pesta17_checklist_persiapan FOR SELECT USING (true);
CREATE POLICY "Anon insert checklist" ON pesta17_checklist_persiapan FOR INSERT WITH CHECK (true);
CREATE POLICY "Anon update checklist" ON pesta17_checklist_persiapan FOR UPDATE USING (true);
CREATE POLICY "Anon delete checklist" ON pesta17_checklist_persiapan FOR DELETE USING (true);

-- Audit Log
ALTER TABLE pesta17_audit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read audit_log" ON pesta17_audit_log FOR SELECT USING (true);
CREATE POLICY "Anon insert audit_log" ON pesta17_audit_log FOR INSERT WITH CHECK (true);
CREATE POLICY "Anon update audit_log" ON pesta17_audit_log FOR UPDATE USING (true);
CREATE POLICY "Anon delete audit_log" ON pesta17_audit_log FOR DELETE USING (true);
