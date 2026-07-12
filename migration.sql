-- ============================================================
-- MIGRATION.SQL — PESTA 17
-- Migrasi aman untuk database yang sudah ada sebelumnya
-- Script ini TIDAK menghapus data — hanya menambah/memperbaiki
-- Jalankan di Supabase SQL Editor setelah database.sql
-- ============================================================

-- ============================================================
-- BAGIAN A: Tambah kolom yang mungkin belum ada
-- (Gunakan IF NOT EXISTS melalui DO block)
-- ============================================================

-- pesta17_info: tambah kolom logo, banner, jam_kegiatan jika belum ada
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'pesta17_info' AND column_name = 'logo'
  ) THEN
    ALTER TABLE pesta17_info ADD COLUMN logo TEXT;
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'pesta17_info' AND column_name = 'banner'
  ) THEN
    ALTER TABLE pesta17_info ADD COLUMN banner TEXT;
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'pesta17_info' AND column_name = 'jam_kegiatan'
  ) THEN
    ALTER TABLE pesta17_info ADD COLUMN jam_kegiatan TEXT;
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'pesta17_info' AND column_name = 'faq'
  ) THEN
    ALTER TABLE pesta17_info ADD COLUMN faq TEXT;
  END IF;
END$$;

-- pesta17_peserta: tambah kolom no_hp dan status_kehadiran jika belum ada
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'pesta17_peserta' AND column_name = 'no_hp'
  ) THEN
    ALTER TABLE pesta17_peserta ADD COLUMN no_hp TEXT;
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'pesta17_peserta' AND column_name = 'status_kehadiran'
  ) THEN
    ALTER TABLE pesta17_peserta ADD COLUMN status_kehadiran TEXT NOT NULL DEFAULT 'Belum Hadir';
  END IF;
END$$;

-- pesta17_lomba: tambah kolom aturan jika belum ada
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'pesta17_lomba' AND column_name = 'aturan'
  ) THEN
    ALTER TABLE pesta17_lomba ADD COLUMN aturan TEXT;
  END IF;
END$$;

-- pesta17_anggaran: kolom nama_pengeluaran jika kode lama gunakan itu
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'pesta17_anggaran' AND column_name = 'deskripsi'
  ) THEN
    ALTER TABLE pesta17_anggaran ADD COLUMN deskripsi TEXT;
  END IF;
END$$;

-- pesta17_sponsor: kolom nilai_kontribusi (rename dari nilai jika ada)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'pesta17_sponsor' AND column_name = 'nilai_kontribusi'
  ) THEN
    ALTER TABLE pesta17_sponsor ADD COLUMN nilai_kontribusi NUMERIC NOT NULL DEFAULT 0;
  END IF;
END$$;

-- pesta17_inventaris: tambah lokasi_penyimpanan jika belum ada
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'pesta17_inventaris' AND column_name = 'lokasi_penyimpanan'
  ) THEN
    ALTER TABLE pesta17_inventaris ADD COLUMN lokasi_penyimpanan TEXT;
  END IF;
END$$;

-- pesta17_audit_log: tambah kolom event_id jika belum ada
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'pesta17_audit_log' AND column_name = 'event_id'
  ) THEN
    ALTER TABLE pesta17_audit_log ADD COLUMN event_id TEXT NOT NULL DEFAULT 'global';
  END IF;
END$$;

-- ============================================================
-- BAGIAN B: Buat tabel baru jika belum ada sama sekali
-- (Tabel yang mungkin belum dibuat di versi lama)
-- ============================================================

-- pesta17_dashboard_timeline (milestone interaktif, mungkin belum ada di versi lama)
CREATE TABLE IF NOT EXISTS pesta17_dashboard_timeline (
  id       TEXT PRIMARY KEY,
  event_id TEXT NOT NULL DEFAULT 'global',
  label    TEXT NOT NULL,
  status   TEXT NOT NULL DEFAULT 'Belum Mulai'
);

CREATE INDEX IF NOT EXISTS idx_pesta17_dashboard_timeline_event_id
  ON pesta17_dashboard_timeline(event_id);

-- Enable RLS jika belum
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'pesta17_dashboard_timeline'
    AND policyname = 'Public read dashboard_timeline'
  ) THEN
    ALTER TABLE pesta17_dashboard_timeline ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "Public read dashboard_timeline" ON pesta17_dashboard_timeline FOR SELECT USING (true);
    CREATE POLICY "Anon insert dashboard_timeline" ON pesta17_dashboard_timeline FOR INSERT WITH CHECK (true);
    CREATE POLICY "Anon update dashboard_timeline" ON pesta17_dashboard_timeline FOR UPDATE USING (true);
    CREATE POLICY "Anon delete dashboard_timeline" ON pesta17_dashboard_timeline FOR DELETE USING (true);
  END IF;
END$$;

-- pesta17_checklist_persiapan (mungkin belum ada di versi lama)
CREATE TABLE IF NOT EXISTS pesta17_checklist_persiapan (
  id       TEXT PRIMARY KEY,
  event_id TEXT NOT NULL DEFAULT 'global',
  label    TEXT NOT NULL,
  checked  BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_pesta17_checklist_event_id
  ON pesta17_checklist_persiapan(event_id);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'pesta17_checklist_persiapan'
    AND policyname = 'Public read checklist'
  ) THEN
    ALTER TABLE pesta17_checklist_persiapan ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "Public read checklist" ON pesta17_checklist_persiapan FOR SELECT USING (true);
    CREATE POLICY "Anon insert checklist" ON pesta17_checklist_persiapan FOR INSERT WITH CHECK (true);
    CREATE POLICY "Anon update checklist" ON pesta17_checklist_persiapan FOR UPDATE USING (true);
    CREATE POLICY "Anon delete checklist" ON pesta17_checklist_persiapan FOR DELETE USING (true);
  END IF;
END$$;

-- pesta17_events (jika belum ada di versi lama yang hanya single-event)
CREATE TABLE IF NOT EXISTS pesta17_events (
  id     TEXT PRIMARY KEY,
  nama   TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'Aktif'
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'pesta17_events'
    AND policyname = 'Public read events'
  ) THEN
    ALTER TABLE pesta17_events ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "Public read events" ON pesta17_events FOR SELECT USING (true);
    CREATE POLICY "Anon insert events" ON pesta17_events FOR INSERT WITH CHECK (true);
    CREATE POLICY "Anon update events" ON pesta17_events FOR UPDATE USING (true);
    CREATE POLICY "Anon delete events" ON pesta17_events FOR DELETE USING (true);
  END IF;
END$$;

-- ============================================================
-- BAGIAN C: Tambah index yang mungkin kurang
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_pesta17_info_event_id      ON pesta17_info(event_id);
CREATE INDEX IF NOT EXISTS idx_pesta17_dusun_event_id     ON pesta17_dusun(event_id);
CREATE INDEX IF NOT EXISTS idx_pesta17_panitia_event_id   ON pesta17_panitia(event_id);
CREATE INDEX IF NOT EXISTS idx_pesta17_lomba_event_id     ON pesta17_lomba(event_id);
CREATE INDEX IF NOT EXISTS idx_pesta17_peserta_event_id   ON pesta17_peserta(event_id);
CREATE INDEX IF NOT EXISTS idx_pesta17_peserta_dusun_id   ON pesta17_peserta(dusun_id);
CREATE INDEX IF NOT EXISTS idx_pesta17_anggaran_event_id  ON pesta17_anggaran(event_id);
CREATE INDEX IF NOT EXISTS idx_pesta17_sponsor_event_id   ON pesta17_sponsor(event_id);
CREATE INDEX IF NOT EXISTS idx_pesta17_inventaris_event_id ON pesta17_inventaris(event_id);
CREATE INDEX IF NOT EXISTS idx_pesta17_timeline_event_id  ON pesta17_timeline(event_id);
CREATE INDEX IF NOT EXISTS idx_pesta17_dokumentasi_event_id ON pesta17_dokumentasi(event_id);
CREATE INDEX IF NOT EXISTS idx_pesta17_audit_log_event_id ON pesta17_audit_log(event_id);

-- ============================================================
-- SELESAI — Migrasi aman tanpa kehilangan data
-- ============================================================
