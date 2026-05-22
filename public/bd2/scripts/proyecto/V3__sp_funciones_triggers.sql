-- ============================================================
--  SpotiClone – Script 003: Procedimientos, Funciones y Triggers
--  Universidad El Bosque | Bases de Datos 2 | 2026-1
--  Integrantes: Ricardo Carrero, Anthony Vega, Samuel Mesa
--  Motor: PostgreSQL 15+
--  Requiere: 001_ddl_schema.sql y 002_dml_seed.sql ejecutados
-- ============================================================


-- ============================================================
--  0. LIMPIEZA IDEMPOTENTE
-- ============================================================

DROP TRIGGER   IF EXISTS trg_log_playlist           ON playlist;
DROP TRIGGER   IF EXISTS trg_reordenar_posiciones    ON playlist_cancion;

DROP FUNCTION  IF EXISTS trg_fn_log_playlist();
DROP FUNCTION  IF EXISTS trg_fn_reordenar_posiciones();

DROP FUNCTION  IF EXISTS fn_total_likes_cancion(INT);
DROP FUNCTION  IF EXISTS fn_canciones_por_genero(INT);

DROP PROCEDURE IF EXISTS sp_eliminar_cancion_playlist(INT, INT);
DROP PROCEDURE IF EXISTS sp_dar_like(INT, INT);
DROP PROCEDURE IF EXISTS sp_quitar_like(INT, INT);


-- ============================================================
--  1. FUNCIONES
-- ============================================================

-- ------------------------------------------------------------
--  1.1 fn_total_likes_cancion
--      Retorna el total de likes que tiene una canción.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_total_likes_cancion(p_id_cancion INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT := 0;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM cancion WHERE id_cancion = p_id_cancion) THEN
        RAISE EXCEPTION 'fn_total_likes_cancion: canción % no encontrada.', p_id_cancion;
    END IF;

    SELECT COUNT(*)
    INTO   v_total
    FROM   like_cancion
    WHERE  id_cancion = p_id_cancion;

    RETURN v_total;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'fn_total_likes_cancion: error para canción %: %',
                      p_id_cancion, SQLERRM;
        RETURN -1;
END;
$$;

COMMENT ON FUNCTION fn_total_likes_cancion(INT)
    IS 'Retorna el total de likes de una canción. -1 si ocurre error.';


-- ------------------------------------------------------------
--  1.2 fn_canciones_por_genero
--      Retorna la cantidad de canciones asociadas a un género.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_canciones_por_genero(p_id_genero INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT := 0;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM genero WHERE id_genero = p_id_genero) THEN
        RAISE EXCEPTION 'fn_canciones_por_genero: género % no encontrado.', p_id_genero;
    END IF;

    SELECT COUNT(*)
    INTO   v_total
    FROM   cancion
    WHERE  id_genero = p_id_genero;

    RETURN v_total;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'fn_canciones_por_genero: error para género %: %',
                      p_id_genero, SQLERRM;
        RETURN -1;
END;
$$;

COMMENT ON FUNCTION fn_canciones_por_genero(INT)
    IS 'Retorna el total de canciones registradas en un género. -1 si ocurre error.';


-- ============================================================
--  2. TRIGGERS
-- ============================================================

-- ------------------------------------------------------------
--  2.1 trg_log_playlist
--      Registra en auditoria_log cada INSERT y DELETE en playlist.
--      El error en el log no debe abortar la operación principal.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_fn_log_playlist()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria_log (tabla, operacion, id_registro, descripcion)
        VALUES (
            'playlist',
            'INSERT',
            NEW.id_playlist,
            'Playlist creada: "' || NEW.nombre || '" (usuario ' || NEW.id_usuario || ')'
        );
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria_log (tabla, operacion, id_registro, descripcion)
        VALUES (
            'playlist',
            'DELETE',
            OLD.id_playlist,
            'Playlist eliminada: "' || OLD.nombre || '"'
        );
        RETURN OLD;
    END IF;

    RETURN NULL;

EXCEPTION
    WHEN OTHERS THEN
        -- El log falla en silencio: la operación sobre playlist ya se completó.
        RAISE WARNING 'trg_fn_log_playlist: no se pudo registrar auditoría: %', SQLERRM;
        IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$$;

CREATE TRIGGER trg_log_playlist
AFTER INSERT OR DELETE ON playlist
FOR EACH ROW EXECUTE FUNCTION trg_fn_log_playlist();

COMMENT ON FUNCTION trg_fn_log_playlist()
    IS 'Registra en auditoria_log cada creación y eliminación de playlist.';


-- ------------------------------------------------------------
--  2.2 trg_reordenar_posiciones
--      Tras eliminar una canción de una playlist, cierra el hueco
--      en el campo posicion para que la numeración sea continua.
--
--      Ejemplo: posiciones [1,2,3,4], se elimina posición 2
--               resultado: [1,2,3]
--
--      Nota: trg_contador_playlist (de 001) también se dispara en
--      DELETE sobre playlist_cancion y decrementa total_canciones.
--      Ambos triggers coexisten sin conflicto.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_fn_reordenar_posiciones()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE playlist_cancion
    SET    posicion = posicion - 1
    WHERE  id_playlist = OLD.id_playlist
      AND  posicion    > OLD.posicion;

    RETURN OLD;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'trg_fn_reordenar_posiciones: error al reordenar playlist %: %',
                        OLD.id_playlist, SQLERRM;
END;
$$;

CREATE TRIGGER trg_reordenar_posiciones
AFTER DELETE ON playlist_cancion
FOR EACH ROW EXECUTE FUNCTION trg_fn_reordenar_posiciones();

COMMENT ON FUNCTION trg_fn_reordenar_posiciones()
    IS 'Reordena las posiciones de las canciones en una playlist tras una eliminación.';


-- ============================================================
--  3. PROCEDIMIENTOS ALMACENADOS
-- ============================================================

-- ------------------------------------------------------------
--  3.1 sp_eliminar_cancion_playlist
--      Elimina una canción de una playlist con validaciones.
--      El trigger trg_contador_playlist decrementa total_canciones.
--      El trigger trg_reordenar_posiciones cierra el hueco.
-- ------------------------------------------------------------
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

    COMMIT;

    RAISE NOTICE 'Canción % eliminada de playlist %.', p_id_cancion, p_id_playlist;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE EXCEPTION 'sp_eliminar_cancion_playlist falló: %', SQLERRM;
END;
$$;

COMMENT ON PROCEDURE sp_eliminar_cancion_playlist(INT, INT)
    IS 'Elimina una canción de una playlist. Los triggers actualizan total_canciones y posiciones.';


-- ------------------------------------------------------------
--  3.2 sp_dar_like
--      Registra un like de un usuario sobre una canción.
--      Valida existencia de usuario (activo) y canción, y que
--      el like no exista previamente (duplicado).
-- ------------------------------------------------------------
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

    COMMIT;

    RAISE NOTICE 'Like registrado: usuario % → canción %.', p_id_usuario, p_id_cancion;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE EXCEPTION 'sp_dar_like falló: %', SQLERRM;
END;
$$;

COMMENT ON PROCEDURE sp_dar_like(INT, INT)
    IS 'Registra un like del usuario sobre una canción con validaciones de duplicado.';


-- ------------------------------------------------------------
--  3.3 sp_quitar_like
--      Elimina un like existente de un usuario sobre una canción.
-- ------------------------------------------------------------
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

    COMMIT;

    RAISE NOTICE 'Like eliminado: usuario % → canción %.', p_id_usuario, p_id_cancion;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE EXCEPTION 'sp_quitar_like falló: %', SQLERRM;
END;
$$;

COMMENT ON PROCEDURE sp_quitar_like(INT, INT)
    IS 'Elimina el like de un usuario sobre una canción. Lanza excepción si no existe.';


-- ============================================================
--  4. PERMISOS (rol de aplicación — consistent con script 001)
-- ============================================================
GRANT EXECUTE ON FUNCTION  fn_total_likes_cancion(INT) TO spoticlone_app;
GRANT EXECUTE ON FUNCTION  fn_canciones_por_genero(INT) TO spoticlone_app;
GRANT EXECUTE ON PROCEDURE sp_eliminar_cancion_playlist(INT, INT) TO spoticlone_app;
GRANT EXECUTE ON PROCEDURE sp_dar_like(INT, INT)  TO spoticlone_app;
GRANT EXECUTE ON PROCEDURE sp_quitar_like(INT, INT) TO spoticlone_app;


-- ============================================================
--  5. VERIFICACIONES POST-MIGRACIÓN
-- ============================================================

-- Confirmar que los nuevos objetos existen
SELECT routine_name, routine_type
FROM   information_schema.routines
WHERE  routine_schema = 'public'
  AND  routine_name IN (
    'fn_total_likes_cancion', 'fn_canciones_por_genero',
    'sp_eliminar_cancion_playlist', 'sp_dar_like', 'sp_quitar_like'
  )
ORDER BY routine_type, routine_name;

-- Confirmar que los triggers están activos
SELECT trigger_name, event_manipulation, event_object_table, action_timing
FROM   information_schema.triggers
WHERE  trigger_schema = 'public'
  AND  trigger_name IN ('trg_log_playlist', 'trg_reordenar_posiciones')
ORDER BY trigger_name, event_manipulation;

-- Probar funciones con datos del seed
SELECT fn_total_likes_cancion(1)  AS likes_cancion_1;
SELECT fn_canciones_por_genero(1) AS canciones_rock;

-- ============================================================
--  FIN DEL SCRIPT 003
--  SpotiClone – Universidad El Bosque – 2026-1
-- ============================================================
