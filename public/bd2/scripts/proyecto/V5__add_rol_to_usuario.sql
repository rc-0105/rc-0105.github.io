-- ============================================================
--  V5: Add rol column to usuario table
-- ============================================================

ALTER TABLE usuario
    ADD COLUMN rol VARCHAR(20) NOT NULL DEFAULT 'usuario';

-- Promote the admin seed user
UPDATE usuario SET rol = 'admin' WHERE email = 'admin@spoticlone.com';
