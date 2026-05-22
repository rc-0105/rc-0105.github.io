-- ============================================================
--  V7: Remove explicit COMMIT/ROLLBACK from sp_dar_like and sp_quitar_like
--
--  Root cause: both procedures have an explicit COMMIT after their
--  DML and a ROLLBACK inside the EXCEPTION block. When the JDBC
--  layer calls them from a connection with autoCommit=true, the
--  driver wraps the CALL in an implicit subtransaction; the
--  explicit COMMIT inside the SP then fails with:
--    "cannot commit while a subtransaction is active"
--
--  Fix: remove COMMIT/ROLLBACK. autoCommit=true in the Java layer
--  already wraps each CALL in its own atomic transaction.
-- ============================================================

-- Fix sp_dar_like: remove explicit COMMIT
CREATE OR REPLACE PROCEDURE sp_dar_like(
    p_id_usuario    INT,
    p_id_cancion    INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verificar que el usuario exista y esté activo
    IF NOT EXISTS (
        SELECT 1 FROM usuario WHERE id_usuario = p_id_usuario AND activo = TRUE
    ) THEN
        RAISE EXCEPTION 'Usuario % no existe o está inactivo.', p_id_usuario;
    END IF;

    -- Verificar que la canción exista
    IF NOT EXISTS (SELECT 1 FROM cancion WHERE id_cancion = p_id_cancion) THEN
        RAISE EXCEPTION 'Canción % no encontrada.', p_id_cancion;
    END IF;

    -- Verificar que el like no esté duplicado
    IF EXISTS (
        SELECT 1 FROM like_cancion
        WHERE  id_usuario = p_id_usuario AND id_cancion = p_id_cancion
    ) THEN
        RAISE EXCEPTION 'El usuario % ya le dio like a la canción %.', p_id_usuario, p_id_cancion;
    END IF;

    INSERT INTO like_cancion (id_usuario, id_cancion)
    VALUES (p_id_usuario, p_id_cancion);

    RAISE NOTICE 'Like registrado: usuario % → canción %.', p_id_usuario, p_id_cancion;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'sp_dar_like falló: %', SQLERRM;
END;
$$;


-- Fix sp_quitar_like: remove explicit COMMIT
CREATE OR REPLACE PROCEDURE sp_quitar_like(
    p_id_usuario    INT,
    p_id_cancion    INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verificar que el like exista antes de intentar eliminarlo
    IF NOT EXISTS (
        SELECT 1 FROM like_cancion
        WHERE  id_usuario = p_id_usuario AND id_cancion = p_id_cancion
    ) THEN
        RAISE EXCEPTION 'El usuario % no tiene like registrado en la canción %.', p_id_usuario, p_id_cancion;
    END IF;

    DELETE FROM like_cancion
    WHERE  id_usuario = p_id_usuario
      AND  id_cancion = p_id_cancion;

    RAISE NOTICE 'Like eliminado: usuario % → canción %.', p_id_usuario, p_id_cancion;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'sp_quitar_like falló: %', SQLERRM;
END;
$$;
