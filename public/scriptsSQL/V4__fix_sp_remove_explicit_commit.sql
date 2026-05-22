-- ============================================================
--  V4: Remove explicit COMMIT/ROLLBACK from stored procedures
--
--  Root cause: trigger functions with EXCEPTION blocks cause
--  PostgreSQL to create implicit SAVEPOINTs. A subsequent
--  COMMIT inside the calling SP fails with:
--    "cannot commit while a subtransaction is active"
--
--  Fix: remove COMMIT/ROLLBACK from all SPs. The Java layer
--  calls them with autoCommit=true, so each CALL is already
--  its own atomic transaction — no explicit commit needed.
-- ============================================================


-- ── sp_registrar_usuario ─────────────────────────────────────
CREATE OR REPLACE PROCEDURE sp_registrar_usuario(
    p_nombre        VARCHAR,
    p_email         VARCHAR,
    p_password_hash VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_usuario INT;
BEGIN
    IF EXISTS (SELECT 1 FROM usuario WHERE email = p_email) THEN
        RAISE EXCEPTION 'El email % ya está registrado.', p_email;
    END IF;

    INSERT INTO usuario (nombre, email, password_hash)
    VALUES (p_nombre, p_email, p_password_hash)
    RETURNING id_usuario INTO v_id_usuario;

    INSERT INTO suscripcion (id_usuario, tipo, precio)
    VALUES (v_id_usuario, 'freemium', 0.00);

    RAISE NOTICE 'Usuario % registrado con id % y suscripción freemium.', p_email, v_id_usuario;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'sp_registrar_usuario falló para %: %', p_email, SQLERRM;
END;
$$;


-- ── sp_crear_playlist ────────────────────────────────────────
CREATE OR REPLACE PROCEDURE sp_crear_playlist(
    p_id_usuario  INT,
    p_nombre      VARCHAR,
    p_descripcion TEXT,
    p_es_publica  BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE id_usuario = p_id_usuario) THEN
        RAISE EXCEPTION 'El usuario % no existe.', p_id_usuario;
    END IF;

    INSERT INTO playlist (id_usuario, nombre, descripcion, es_publica)
    VALUES (p_id_usuario, p_nombre, p_descripcion, p_es_publica);

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'sp_crear_playlist falló: %', SQLERRM;
END;
$$;


-- ── sp_agregar_cancion_playlist ──────────────────────────────
CREATE OR REPLACE PROCEDURE sp_agregar_cancion_playlist(
    p_id_playlist INT,
    p_id_cancion  INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_posicion INT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM playlist WHERE id_playlist = p_id_playlist) THEN
        RAISE EXCEPTION 'La playlist % no existe.', p_id_playlist;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM cancion WHERE id_cancion = p_id_cancion) THEN
        RAISE EXCEPTION 'La canción % no existe.', p_id_cancion;
    END IF;

    IF EXISTS (
        SELECT 1 FROM playlist_cancion
        WHERE id_playlist = p_id_playlist AND id_cancion = p_id_cancion
    ) THEN
        RAISE EXCEPTION 'La canción % ya está en la playlist %.', p_id_cancion, p_id_playlist;
    END IF;

    SELECT COALESCE(MAX(posicion), 0) + 1
    INTO v_posicion
    FROM playlist_cancion
    WHERE id_playlist = p_id_playlist;

    INSERT INTO playlist_cancion (id_playlist, id_cancion, posicion)
    VALUES (p_id_playlist, p_id_cancion, v_posicion);

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'sp_agregar_cancion_playlist falló: %', SQLERRM;
END;
$$;


-- ── sp_cambiar_suscripcion ───────────────────────────────────
CREATE OR REPLACE PROCEDURE sp_cambiar_suscripcion(
    p_id_usuario INT,
    p_nuevo_tipo VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_precio NUMERIC(10,2);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE id_usuario = p_id_usuario) THEN
        RAISE EXCEPTION 'El usuario % no existe.', p_id_usuario;
    END IF;

    IF p_nuevo_tipo NOT IN ('freemium', 'premium', 'familiar') THEN
        RAISE EXCEPTION 'Tipo de suscripción inválido: %. Use freemium, premium o familiar.', p_nuevo_tipo;
    END IF;

    v_precio := CASE p_nuevo_tipo
        WHEN 'freemium' THEN 0.00
        WHEN 'premium'  THEN 9.99
        WHEN 'familiar' THEN 14.99
    END;

    UPDATE suscripcion
    SET tipo        = p_nuevo_tipo,
        precio      = v_precio,
        fecha_inicio = CURRENT_DATE,
        fecha_fin    = CASE
                          WHEN p_nuevo_tipo = 'freemium' THEN NULL
                          ELSE CURRENT_DATE + INTERVAL '30 days'
                       END,
        activa       = TRUE
    WHERE id_usuario = p_id_usuario;

    IF NOT FOUND THEN
        INSERT INTO suscripcion (id_usuario, tipo, precio)
        VALUES (p_id_usuario, p_nuevo_tipo, v_precio);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'sp_cambiar_suscripcion falló para usuario %: %', p_id_usuario, SQLERRM;
END;
$$;
