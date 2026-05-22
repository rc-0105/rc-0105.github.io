-- ============================================================
--  V6: Remove explicit COMMIT/ROLLBACK from sp_eliminar_cancion_playlist
--
--  Root cause: sp_eliminar_cancion_playlist was missed in V4.
--  The trigger trg_reordenar_posiciones has an EXCEPTION block
--  that creates an implicit SAVEPOINT. A subsequent explicit
--  COMMIT inside the SP then fails with:
--    "cannot commit while a subtransaction is active"
--
--  Fix: remove COMMIT/ROLLBACK. autoCommit=true in the Java
--  layer already wraps each CALL in its own atomic transaction.
-- ============================================================

CREATE OR REPLACE PROCEDURE sp_eliminar_cancion_playlist(
    p_id_playlist   INT,
    p_id_cancion    INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verificar que la playlist exista
    IF NOT EXISTS (SELECT 1 FROM playlist WHERE id_playlist = p_id_playlist) THEN
        RAISE EXCEPTION 'Playlist % no encontrada.', p_id_playlist;
    END IF;

    -- Verificar que la canción esté en la playlist
    IF NOT EXISTS (
        SELECT 1 FROM playlist_cancion
        WHERE  id_playlist = p_id_playlist
          AND  id_cancion  = p_id_cancion
    ) THEN
        RAISE EXCEPTION 'La canción % no existe en la playlist %.', p_id_cancion, p_id_playlist;
    END IF;

    -- Eliminar — los triggers se encargan de total_canciones y posiciones
    DELETE FROM playlist_cancion
    WHERE  id_playlist = p_id_playlist
      AND  id_cancion  = p_id_cancion;

    RAISE NOTICE 'Canción % eliminada de playlist %.', p_id_cancion, p_id_playlist;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'sp_eliminar_cancion_playlist falló: %', SQLERRM;
END;
$$;
