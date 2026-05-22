-- ============================================================
--  SpotiClone – Script DDL PostgreSQL
--  Universidad El Bosque | Bases de Datos 2 | 2026-1
--  Integrantes: Ricardo Carrero, Anthony Vega, Samuel Mesa
--  Motor: PostgreSQL 15+
--  Encoding: UTF-8
-- ============================================================

--  1. TABLAS BASE
-- ============================================================

-- ------------------------------------------------------------
--  1.1 GENERO
-- ------------------------------------------------------------
CREATE TABLE genero (
    id_genero   SERIAL          PRIMARY KEY,
    nombre      VARCHAR(60)     NOT NULL UNIQUE,
    descripcion TEXT
);

COMMENT ON TABLE  genero             IS 'Catálogo de géneros musicales';
COMMENT ON COLUMN genero.nombre      IS 'Nombre único del género (ej. Rock, Pop, Jazz)';


-- ------------------------------------------------------------
--  1.2 ARTISTA
-- ------------------------------------------------------------
CREATE TABLE artista (
    id_artista      SERIAL          PRIMARY KEY,
    nom_artistico   VARCHAR(120)    NOT NULL,
    pais            VARCHAR(60),
    biografia       TEXT,
    foto_url        VARCHAR(300),
    fecha_registro  TIMESTAMP       NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  artista               IS 'Artistas del catálogo musical';
COMMENT ON COLUMN artista.nom_artistico IS 'Nombre artístico o nombre de banda';


-- ------------------------------------------------------------
--  1.3 USUARIO
-- ------------------------------------------------------------
CREATE TABLE usuario (
    id_usuario      SERIAL          PRIMARY KEY,
    nombre          VARCHAR(120)    NOT NULL,
    email           VARCHAR(200)    NOT NULL UNIQUE,
    password_hash   VARCHAR(255)    NOT NULL,
    foto_perfil     VARCHAR(300),
    fecha_registro  TIMESTAMP       NOT NULL DEFAULT NOW(),
    activo          BOOLEAN         NOT NULL DEFAULT TRUE
);

COMMENT ON TABLE  usuario              IS 'Usuarios registrados en la plataforma';
COMMENT ON COLUMN usuario.email        IS 'Email único — usado como identificador de login';
COMMENT ON COLUMN usuario.password_hash IS 'Hash bcrypt de la contraseña (nunca texto plano)';


-- ------------------------------------------------------------
--  1.4 SUSCRIPCION (1:1 con USUARIO)
-- ------------------------------------------------------------
CREATE TABLE suscripcion (
    id_suscripcion  SERIAL          PRIMARY KEY,
    id_usuario      INT             NOT NULL UNIQUE,   -- UNIQUE fuerza 1:1
    tipo            VARCHAR(20)     NOT NULL DEFAULT 'freemium'
                                    CHECK (tipo IN ('freemium', 'premium')),
    fecha_inicio    DATE            NOT NULL DEFAULT CURRENT_DATE,
    fecha_fin       DATE,
    precio          NUMERIC(10,2)   NOT NULL DEFAULT 0.00,
    activa          BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT fk_suscripcion_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
        ON DELETE CASCADE
);

COMMENT ON TABLE  suscripcion          IS 'Suscripción activa del usuario (relación 1:1)';
COMMENT ON COLUMN suscripcion.tipo     IS 'freemium = gratis, premium = pago';
COMMENT ON COLUMN suscripcion.id_usuario IS 'UNIQUE garantiza máximo una suscripción por usuario';


-- ------------------------------------------------------------
--  1.5 ALBUM
-- ------------------------------------------------------------
CREATE TABLE album (
    id_album            SERIAL          PRIMARY KEY,
    id_artista          INT             NOT NULL,
    titulo              VARCHAR(200)    NOT NULL,
    tipo                VARCHAR(20)     NOT NULL DEFAULT 'album'
                                        CHECK (tipo IN ('album', 'single', 'ep')),
    fecha_lanzamiento   DATE,
    portada_url         VARCHAR(300),

    CONSTRAINT fk_album_artista
        FOREIGN KEY (id_artista) REFERENCES artista(id_artista)
        ON DELETE CASCADE
);

COMMENT ON TABLE  album       IS 'Álbumes, singles y EPs del catálogo';
COMMENT ON COLUMN album.tipo  IS 'album | single | ep';


-- ------------------------------------------------------------
--  1.6 CANCION
-- ------------------------------------------------------------
CREATE TABLE cancion (
    id_cancion      SERIAL          PRIMARY KEY,
    id_album        INT             NOT NULL,
    id_genero       INT             NOT NULL,
    titulo          VARCHAR(200)    NOT NULL,
    duracion_seg    INT             NOT NULL CHECK (duracion_seg > 0),
    url_preview     VARCHAR(300),
    letra           TEXT,
    numero_pista    INT,
    fecha_registro  TIMESTAMP       NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_cancion_album
        FOREIGN KEY (id_album)  REFERENCES album(id_album)   ON DELETE CASCADE,
    CONSTRAINT fk_cancion_genero
        FOREIGN KEY (id_genero) REFERENCES genero(id_genero) ON DELETE RESTRICT
);

COMMENT ON TABLE  cancion              IS 'Catálogo de canciones';
COMMENT ON COLUMN cancion.duracion_seg IS 'Duración en segundos (debe ser > 0)';
COMMENT ON COLUMN cancion.url_preview  IS 'URL del preview de 30s (simulado)';


-- ------------------------------------------------------------
--  1.7 PLAYLIST
-- ------------------------------------------------------------
CREATE TABLE playlist (
    id_playlist     SERIAL          PRIMARY KEY,
    id_usuario      INT             NOT NULL,
    nombre          VARCHAR(200)    NOT NULL,
    descripcion     TEXT,
    es_publica      BOOLEAN         NOT NULL DEFAULT FALSE,
    fecha_creacion  TIMESTAMP       NOT NULL DEFAULT NOW(),
    total_canciones INT             NOT NULL DEFAULT 0,   -- mantenido por trigger

    CONSTRAINT fk_playlist_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
        ON DELETE CASCADE
);

COMMENT ON TABLE  playlist                  IS 'Listas de reproducción creadas por usuarios';
COMMENT ON COLUMN playlist.total_canciones  IS 'Contador actualizado automáticamente por trigger';


-- ============================================================
--  2. TABLAS PIVOTE (N:M)
-- ============================================================

-- ------------------------------------------------------------
--  2.1 PLAYLIST_CANCION
-- ------------------------------------------------------------
CREATE TABLE playlist_cancion (
    id_playlist     INT     NOT NULL,
    id_cancion      INT     NOT NULL,
    posicion        INT     NOT NULL DEFAULT 0,
    fecha_agregada  TIMESTAMP NOT NULL DEFAULT NOW(),

    PRIMARY KEY (id_playlist, id_cancion),

    CONSTRAINT fk_pc_playlist
        FOREIGN KEY (id_playlist) REFERENCES playlist(id_playlist) ON DELETE CASCADE,
    CONSTRAINT fk_pc_cancion
        FOREIGN KEY (id_cancion)  REFERENCES cancion(id_cancion)   ON DELETE CASCADE
);

COMMENT ON TABLE playlist_cancion IS 'Relación N:M entre playlists y canciones';


-- ------------------------------------------------------------
--  2.2 LIKE_CANCION
-- ------------------------------------------------------------
CREATE TABLE like_cancion (
    id_usuario      INT         NOT NULL,
    id_cancion      INT         NOT NULL,
    fecha_like      TIMESTAMP   NOT NULL DEFAULT NOW(),

    PRIMARY KEY (id_usuario, id_cancion),

    CONSTRAINT fk_lk_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    CONSTRAINT fk_lk_cancion
        FOREIGN KEY (id_cancion) REFERENCES cancion(id_cancion) ON DELETE CASCADE
);

COMMENT ON TABLE like_cancion IS 'Canciones marcadas como favoritas por el usuario';


-- ------------------------------------------------------------
--  2.3 ARTISTA_GENERO
-- ------------------------------------------------------------
CREATE TABLE artista_genero (
    id_artista  INT NOT NULL,
    id_genero   INT NOT NULL,

    PRIMARY KEY (id_artista, id_genero),

    CONSTRAINT fk_ag_artista
        FOREIGN KEY (id_artista) REFERENCES artista(id_artista) ON DELETE CASCADE,
    CONSTRAINT fk_ag_genero
        FOREIGN KEY (id_genero)  REFERENCES genero(id_genero)   ON DELETE CASCADE
);

COMMENT ON TABLE artista_genero IS 'Relación N:M entre artistas y géneros musicales';


-- ============================================================
--  3. TABLA DE AUDITORÍA
-- ============================================================
CREATE SEQUENCE seq_log_id START 1;

CREATE TABLE auditoria_log (
    id_log      BIGINT          PRIMARY KEY DEFAULT nextval('seq_log_id'),
    tabla       VARCHAR(60)     NOT NULL,
    operacion   VARCHAR(10)     NOT NULL CHECK (operacion IN ('INSERT','UPDATE','DELETE')),
    id_registro INT,
    descripcion TEXT,
    usuario_db  VARCHAR(100)    NOT NULL DEFAULT current_user,
    fecha       TIMESTAMP       NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE auditoria_log IS 'Log de auditoría para operaciones críticas';


-- ============================================================
--  4. ÍNDICES
-- ============================================================
CREATE INDEX idx_cancion_album      ON cancion(id_album);
CREATE INDEX idx_cancion_genero     ON cancion(id_genero);
CREATE INDEX idx_album_artista      ON album(id_artista);
CREATE INDEX idx_playlist_usuario   ON playlist(id_usuario);
CREATE INDEX idx_like_cancion       ON like_cancion(id_cancion);
CREATE INDEX idx_like_usuario       ON like_cancion(id_usuario);
CREATE INDEX idx_usuario_email      ON usuario(email);
CREATE INDEX idx_suscripcion_tipo   ON suscripcion(tipo);


-- ============================================================
--  5. FUNCIONES
-- ============================================================

-- ------------------------------------------------------------
--  5.1 fn_duracion_total_playlist
--      Retorna la duración total en segundos de una playlist
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_duracion_total_playlist(p_id_playlist INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_duracion INT := 0;
BEGIN
    SELECT COALESCE(SUM(c.duracion_seg), 0)
    INTO   v_duracion
    FROM   playlist_cancion pc
    JOIN   cancion c ON c.id_cancion = pc.id_cancion
    WHERE  pc.id_playlist = p_id_playlist;

    RETURN v_duracion;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'fn_duracion_total_playlist: error para playlist %: %',
                      p_id_playlist, SQLERRM;
        RETURN -1;
END;
$$;

COMMENT ON FUNCTION fn_duracion_total_playlist(INT)
    IS 'Retorna duración total en segundos de una playlist. -1 si ocurre error.';


-- ------------------------------------------------------------
--  5.2 fn_canciones_por_artista
--      Cuenta el total de canciones de un artista
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_canciones_por_artista(p_id_artista INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT := 0;
BEGIN
    SELECT COUNT(c.id_cancion)
    INTO   v_total
    FROM   cancion c
    JOIN   album a ON a.id_album = c.id_album
    WHERE  a.id_artista = p_id_artista;

    RETURN v_total;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'fn_canciones_por_artista: error para artista %: %',
                      p_id_artista, SQLERRM;
        RETURN -1;
END;
$$;

COMMENT ON FUNCTION fn_canciones_por_artista(INT)
    IS 'Retorna el total de canciones de un artista sumando todos sus álbumes.';


-- ------------------------------------------------------------
--  5.3 fn_tiene_suscripcion_activa
--      Verifica si un usuario tiene suscripción premium activa
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_tiene_suscripcion_activa(p_id_usuario INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_existe BOOLEAN := FALSE;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM suscripcion
        WHERE  id_usuario = p_id_usuario
          AND  tipo       = 'premium'
          AND  activa     = TRUE
          AND  (fecha_fin IS NULL OR fecha_fin >= CURRENT_DATE)
    )
    INTO v_existe;

    RETURN v_existe;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'fn_tiene_suscripcion_activa: error para usuario %: %',
                      p_id_usuario, SQLERRM;
        RETURN FALSE;
END;
$$;

COMMENT ON FUNCTION fn_tiene_suscripcion_activa(INT)
    IS 'Retorna TRUE si el usuario tiene suscripción premium vigente.';


-- ============================================================
--  6. TRIGGERS
-- ============================================================

-- ------------------------------------------------------------
--  6.1 TRG: actualizar contador de canciones en playlist
--      Se dispara en INSERT/DELETE sobre playlist_cancion
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_fn_actualizar_contador_playlist()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE playlist
        SET    total_canciones = total_canciones + 1
        WHERE  id_playlist = NEW.id_playlist;

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        UPDATE playlist
        SET    total_canciones = GREATEST(total_canciones - 1, 0)
        WHERE  id_playlist = OLD.id_playlist;

        RETURN OLD;
    END IF;

    RETURN NULL;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'trg_fn_actualizar_contador_playlist: %', SQLERRM;
END;
$$;

CREATE TRIGGER trg_contador_playlist
AFTER INSERT OR DELETE ON playlist_cancion
FOR EACH ROW EXECUTE FUNCTION trg_fn_actualizar_contador_playlist();

COMMENT ON FUNCTION trg_fn_actualizar_contador_playlist()
    IS 'Mantiene sincronizado playlist.total_canciones en INSERT/DELETE de playlist_cancion.';


-- ------------------------------------------------------------
--  6.2 TRG: log de auditoría en INSERT de usuario
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_fn_log_usuario()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO auditoria_log (tabla, operacion, id_registro, descripcion)
    VALUES (
        'usuario',
        TG_OP,
        NEW.id_usuario,
        'Nuevo usuario registrado: ' || NEW.email
    );

    RETURN NEW;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'trg_fn_log_usuario: no se pudo registrar log para usuario %: %',
                      NEW.id_usuario, SQLERRM;
        RETURN NEW;
END;
$$;

CREATE TRIGGER trg_log_nuevo_usuario
AFTER INSERT ON usuario
FOR EACH ROW EXECUTE FUNCTION trg_fn_log_usuario();

COMMENT ON FUNCTION trg_fn_log_usuario()
    IS 'Registra en auditoria_log cada vez que se inserta un nuevo usuario.';


-- ============================================================
--  7. PROCEDIMIENTOS ALMACENADOS
-- ============================================================

-- ------------------------------------------------------------
--  7.1 sp_registrar_usuario
--      Registra un nuevo usuario con suscripción freemium
--      Usa transacción explícita con manejo de excepciones
-- ------------------------------------------------------------
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
    -- Validar que el email no exista
    IF EXISTS (SELECT 1 FROM usuario WHERE email = p_email) THEN
        RAISE EXCEPTION 'El email % ya está registrado.', p_email;
    END IF;

    -- Insertar usuario
    INSERT INTO usuario (nombre, email, password_hash)
    VALUES (p_nombre, p_email, p_password_hash)
    RETURNING id_usuario INTO v_id_usuario;

    -- Crear suscripción freemium automáticamente
    INSERT INTO suscripcion (id_usuario, tipo, precio)
    VALUES (v_id_usuario, 'freemium', 0.00);

    COMMIT;

    RAISE NOTICE 'Usuario % registrado con id % y suscripción freemium.',
                 p_email, v_id_usuario;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE EXCEPTION 'sp_registrar_usuario falló para %: %', p_email, SQLERRM;
END;
$$;

COMMENT ON PROCEDURE sp_registrar_usuario(VARCHAR, VARCHAR, VARCHAR)
    IS 'Registra usuario + suscripción freemium en una transacción atómica.';


-- ------------------------------------------------------------
--  7.2 sp_crear_playlist
--      Crea una playlist para un usuario existente
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_crear_playlist(
    p_id_usuario    INT,
    p_nombre        VARCHAR,
    p_descripcion   TEXT,
    p_es_publica    BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_playlist INT;
BEGIN
    -- Verificar que el usuario exista y esté activo
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE id_usuario = p_id_usuario AND activo = TRUE) THEN
        RAISE EXCEPTION 'Usuario % no existe o está inactivo.', p_id_usuario;
    END IF;

    -- Insertar playlist
    INSERT INTO playlist (id_usuario, nombre, descripcion, es_publica)
    VALUES (p_id_usuario, p_nombre, p_descripcion, p_es_publica)
    RETURNING id_playlist INTO v_id_playlist;

    COMMIT;

    RAISE NOTICE 'Playlist "%" creada con id % para usuario %.',
                 p_nombre, v_id_playlist, p_id_usuario;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE EXCEPTION 'sp_crear_playlist falló: %', SQLERRM;
END;
$$;

COMMENT ON PROCEDURE sp_crear_playlist(INT, VARCHAR, TEXT, BOOLEAN)
    IS 'Crea una nueva playlist validando que el usuario exista y esté activo.';


-- ------------------------------------------------------------
--  7.3 sp_agregar_cancion_playlist
--      Agrega una canción a una playlist con validaciones
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_agregar_cancion_playlist(
    p_id_playlist   INT,
    p_id_cancion    INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_posicion INT;
BEGIN
    -- Verificar que la playlist exista
    IF NOT EXISTS (SELECT 1 FROM playlist WHERE id_playlist = p_id_playlist) THEN
        RAISE EXCEPTION 'Playlist % no encontrada.', p_id_playlist;
    END IF;

    -- Verificar que la canción exista
    IF NOT EXISTS (SELECT 1 FROM cancion WHERE id_cancion = p_id_cancion) THEN
        RAISE EXCEPTION 'Canción % no encontrada.', p_id_cancion;
    END IF;

    -- Verificar que la canción no esté ya en la playlist
    IF EXISTS (
        SELECT 1 FROM playlist_cancion
        WHERE id_playlist = p_id_playlist AND id_cancion = p_id_cancion
    ) THEN
        RAISE EXCEPTION 'La canción % ya existe en la playlist %.', p_id_cancion, p_id_playlist;
    END IF;

    -- Calcular posición (siguiente al último)
    SELECT COALESCE(MAX(posicion), 0) + 1
    INTO   v_posicion
    FROM   playlist_cancion
    WHERE  id_playlist = p_id_playlist;

    -- Insertar (el trigger actualizará total_canciones automáticamente)
    INSERT INTO playlist_cancion (id_playlist, id_cancion, posicion)
    VALUES (p_id_playlist, p_id_cancion, v_posicion);

    COMMIT;

    RAISE NOTICE 'Canción % agregada a playlist % en posición %.',
                 p_id_cancion, p_id_playlist, v_posicion;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE EXCEPTION 'sp_agregar_cancion_playlist falló: %', SQLERRM;
END;
$$;

COMMENT ON PROCEDURE sp_agregar_cancion_playlist(INT, INT)
    IS 'Agrega una canción a una playlist con validaciones y posición automática.';


-- ------------------------------------------------------------
--  7.4 sp_cambiar_suscripcion
--      Cambia el tipo de suscripción de un usuario
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_cambiar_suscripcion(
    p_id_usuario    INT,
    p_nuevo_tipo    VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_tipo_actual VARCHAR(20);
BEGIN
    -- Validar tipo
    IF p_nuevo_tipo NOT IN ('freemium', 'premium') THEN
        RAISE EXCEPTION 'Tipo de suscripción inválido: %. Use freemium o premium.', p_nuevo_tipo;
    END IF;

    -- Obtener tipo actual
    SELECT tipo INTO v_tipo_actual
    FROM   suscripcion
    WHERE  id_usuario = p_id_usuario;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró suscripción para el usuario %.', p_id_usuario;
    END IF;

    IF v_tipo_actual = p_nuevo_tipo THEN
        RAISE NOTICE 'El usuario % ya tiene suscripción %.', p_id_usuario, p_nuevo_tipo;
        RETURN;
    END IF;

    -- Actualizar suscripción
    UPDATE suscripcion
    SET    tipo        = p_nuevo_tipo,
           fecha_inicio = CURRENT_DATE,
           fecha_fin    = CASE
                              WHEN p_nuevo_tipo = 'premium' THEN CURRENT_DATE + INTERVAL '30 days'
                              ELSE NULL
                          END,
           precio       = CASE p_nuevo_tipo
                              WHEN 'premium'  THEN 9.99
                              WHEN 'freemium' THEN 0.00
                          END,
           activa       = TRUE
    WHERE  id_usuario = p_id_usuario;

    -- Registrar en auditoría
    INSERT INTO auditoria_log (tabla, operacion, id_registro, descripcion)
    VALUES (
        'suscripcion', 'UPDATE', p_id_usuario,
        'Cambio de suscripción: ' || v_tipo_actual || ' → ' || p_nuevo_tipo
    );

    COMMIT;

    RAISE NOTICE 'Suscripción de usuario % cambiada de % a %.',
                 p_id_usuario, v_tipo_actual, p_nuevo_tipo;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE EXCEPTION 'sp_cambiar_suscripcion falló para usuario %: %', p_id_usuario, SQLERRM;
END;
$$;

COMMENT ON PROCEDURE sp_cambiar_suscripcion(INT, VARCHAR)
    IS 'Cambia la suscripción del usuario con auditoría y transacción atómica.';


-- ============================================================
--  8. ROLES Y SEGURIDAD
-- ============================================================

-- Rol de solo lectura (para reportes / frontend)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'spoticlone_readonly') THEN
        CREATE ROLE spoticlone_readonly;
    END IF;
END;
$$;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO spoticlone_readonly;

-- Rol de aplicación (lectura + escritura via stored procedures)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'spoticlone_app') THEN
        CREATE ROLE spoticlone_app;
    END IF;
END;
$$;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES    IN SCHEMA public TO spoticlone_app;
GRANT USAGE, SELECT                  ON ALL SEQUENCES IN SCHEMA public TO spoticlone_app;
GRANT EXECUTE ON ALL FUNCTIONS       IN SCHEMA public TO spoticlone_app;


-- ============================================================
--  FIN DEL SCRIPT DDL
--  SpotiClone – Universidad El Bosque – 2026-1
-- ============================================================