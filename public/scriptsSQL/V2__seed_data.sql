-- ============================================================
--  SEED DATA — SpotiClone
--  IMPORTANTE: Ejecutar DESPUÉS del script DDL (V1)
-- ============================================================

-- Reset completo para garantizar secuencias en 1 (idempotente en CI/CD)
TRUNCATE
    like_cancion,
    playlist_cancion,
    auditoria_log,
    suscripcion,
    playlist,
    usuario,
    artista_genero,
    cancion,
    album,
    artista,
    genero
RESTART IDENTITY CASCADE;


-- ============================================================
--  1. GÉNEROS MUSICALES (10 registros)
-- ============================================================
INSERT INTO genero (nombre, descripcion) VALUES
    ('Rock',        'Música rock en todas sus variantes'),
    ('Pop',         'Música popular contemporánea'),
    ('Hip-Hop',     'Rap y cultura hip-hop urbana'),
    ('Electrónica', 'Música electrónica y dance'),
    ('Jazz',        'Jazz clásico y contemporáneo'),
    ('Reggaeton',   'Ritmo urbano latino'),
    ('Clásica',     'Música clásica occidental'),
    ('R&B',         'Rhythm and Blues'),
    ('Metal',       'Metal y sus subgéneros'),
    ('Salsa',       'Música tropical y salsa');


-- ============================================================
--  2. ARTISTAS (10 registros)
-- ============================================================
INSERT INTO artista (nom_artistico, pais, biografia) VALUES
    ('Los Oscuros',       'Colombia',       'Banda bogotana de rock alternativo formada en 2010.'),
    ('Valeria Reyes',     'México',         'Cantautora de pop latino con influencias del R&B.'),
    ('DJ Nexus',          'Argentina',      'Productor y DJ de música electrónica y house.'),
    ('The Midnight Crew', 'Estados Unidos', 'Cuarteto de jazz experimental con raíces en el blues.'),
    ('El Barrio',         'Colombia',       'Grupo de reggaeton y música urbana de Medellín.'),
    ('Orquesta Dorada',   'Cuba',           'Orquesta de salsa y música tropical con 30 años de trayectoria.'),
    ('Sombra Negra',      'Chile',          'Banda de metal progresivo con letras en español.'),
    ('Lena Russo',        'Italia',         'Soprano y compositora de música clásica contemporánea.'),
    ('FreakBeat',         'Colombia',       'Colectivo de hip-hop colombiano con mensaje social.'),
    ('Marcos Silva',      'Brasil',         'Guitarrista y compositor de pop acústico y bossa nova.');


-- ============================================================
--  3. ÁLBUMES (15 registros)
-- ============================================================
INSERT INTO album (id_artista, titulo, tipo, fecha_lanzamiento) VALUES
    (1, 'Noche Eterna',         'album',  '2022-03-15'),
    (1, 'Caos y Orden',         'ep',     '2024-01-20'),
    (2, 'Entre Luces',          'album',  '2023-07-04'),
    (2, 'Despertar',            'single', '2025-02-14'),
    (3, 'Pulsos',               'album',  '2023-11-01'),
    (4, 'Blue Hour Sessions',   'album',  '2022-09-10'),
    (5, 'Barrio Alto',          'album',  '2024-04-18'),
    (5, 'Fuego',                'single', '2025-01-05'),
    (6, 'La Dorada Suena',      'album',  '2021-06-21'),
    (7, 'Fractura',             'album',  '2023-05-30'),
    (8, 'Aria',                 'album',  '2022-12-01'),
    (9, 'Concreto y Sueños',    'album',  '2024-08-15'),
    (10,'Raíces',               'album',  '2023-03-22'),
    (3, 'Drop Zone',            'ep',     '2024-06-10'),
    (4, 'After Hours',          'single', '2025-03-01');


-- ============================================================
--  4. CANCIONES (30 registros)
-- ============================================================
INSERT INTO cancion (id_album, id_genero, titulo, duracion_seg, numero_pista) VALUES
-- Noche Eterna (album 1, Rock)
    (1,  1, 'Oscuridad',            214, 1),
    (1,  1, 'Sin Retorno',          198, 2),
    (1,  1, 'El Último Tren',       241, 3),
    (1,  1, 'Tormenta Interior',    187, 4),
-- Caos y Orden EP (album 2, Rock)
    (2,  1, 'Caos',                 173, 1),
    (2,  9, 'Orden Metal',          205, 2),
-- Entre Luces (album 3, Pop)
    (3,  2, 'Luz de Día',           193, 1),
    (3,  2, 'Nube Rosa',            211, 2),
    (3,  8, 'Feeling Good',         224, 3),
    (3,  2, 'Primavera',            178, 4),
-- Despertar single (album 4, Pop)
    (4,  2, 'Despertar',            195, 1),
-- Pulsos (album 5, Electrónica)
    (5,  4, 'Pulso Alpha',          342, 1),
    (5,  4, 'Drifting',             298, 2),
    (5,  4, 'Neon Rain',            315, 3),
-- Blue Hour Sessions (album 6, Jazz)
    (6,  5, 'Blue Monday',          387, 1),
    (6,  5, 'Sax at Midnight',      412, 2),
    (6,  5, 'The Last Note',        356, 3),
-- Barrio Alto (album 7, Reggaeton)
    (7,  6, 'Calor de Barrio',      198, 1),
    (7,  6, 'La Calle Llama',       212, 2),
    (7,  6, 'Noche de Viernes',     187, 3),
-- La Dorada Suena (album 9, Salsa)
    (9, 10, 'Sabrosura',            264, 1),
    (9, 10, 'Paso a Paso',          248, 2),
-- Fractura (album 10, Metal)
    (10, 9, 'Fractura',             287, 1),
    (10, 9, 'Abyss',                312, 2),
-- Concreto y Sueños (album 12, Hip-Hop)
    (12, 3, 'Concreto',             214, 1),
    (12, 3, 'Barrio Libre',         198, 2),
    (12, 3, 'La Verdad',            223, 3),
-- Raíces (album 13, Pop)
    (13, 2, 'Raíces',               201, 1),
    (13, 2, 'Bossa Tarde',          234, 2),
-- Drop Zone EP (album 14, Electrónica)
    (14, 4, 'Drop Zone',            328, 1);


-- ============================================================
--  5. ARTISTA_GENERO (géneros por artista)
-- ============================================================
INSERT INTO artista_genero (id_artista, id_genero) VALUES
    (1, 1),   -- Los Oscuros: Rock
    (1, 9),   -- Los Oscuros: Metal
    (2, 2),   -- Valeria Reyes: Pop
    (2, 8),   -- Valeria Reyes: R&B
    (3, 4),   -- DJ Nexus: Electrónica
    (4, 5),   -- The Midnight Crew: Jazz
    (4, 8),   -- The Midnight Crew: R&B
    (5, 6),   -- El Barrio: Reggaeton
    (5, 3),   -- El Barrio: Hip-Hop
    (6, 10),  -- Orquesta Dorada: Salsa
    (7, 9),   -- Sombra Negra: Metal
    (7, 1),   -- Sombra Negra: Rock
    (8, 7),   -- Lena Russo: Clásica
    (9, 3),   -- FreakBeat: Hip-Hop
    (10, 2),  -- Marcos Silva: Pop
    (10, 5);  -- Marcos Silva: Jazz


-- ============================================================
--  6. USUARIOS (10 registros) + SUSCRIPCIÓN FREEMIUM
--     Equivale a: CALL sp_registrar_usuario(...)
--     El SP hacía: INSERT usuario → INSERT suscripcion freemium
--     Se usan IDs explícitos porque TRUNCATE RESTART IDENTITY
--     garantiza que los usuarios obtengan IDs 1-10 en orden,
--     pero el trigger trg_log_nuevo_usuario inserta en auditoria_log
--     (también SERIAL), lo que haría que lastval() devuelva el ID
--     de auditoria_log en lugar del de usuario.
-- ============================================================
INSERT INTO usuario (nombre, email, password_hash) VALUES
    ('Ricardo Carrero',  'ricardo@spoticlone.com',   '$2b$12$abc123hashricardo'),
    ('Anthony Vega',     'anthony@spoticlone.com',   '$2b$12$abc123hashanthony'),
    ('Samuel Mesa',      'samuel@spoticlone.com',    '$2b$12$abc123hashsamuel'),
    ('Laura Martínez',   'laura@spoticlone.com',     '$2b$12$abc123hashlauramt'),
    ('Andrés Torres',    'andres@spoticlone.com',    '$2b$12$abc123hashandrest'),
    ('Sofía Gómez',      'sofia@spoticlone.com',     '$2b$12$abc123hashsofiagm'),
    ('Camila Ruiz',      'camila@spoticlone.com',    '$2b$12$abc123hashcamilar'),
    ('Diego Herrera',    'diego@spoticlone.com',     '$2b$12$abc123hashdiegohm'),
    ('Valentina Cruz',   'valentina@spoticlone.com', '$2b$12$abc123hashvalenti'),
    ('Admin SpotiClone', 'admin@spoticlone.com',     '$2b$12$abc123hashadminsc');

INSERT INTO suscripcion (id_usuario, tipo, precio) VALUES
    (1,  'freemium', 0.00),
    (2,  'freemium', 0.00),
    (3,  'freemium', 0.00),
    (4,  'freemium', 0.00),
    (5,  'freemium', 0.00),
    (6,  'freemium', 0.00),
    (7,  'freemium', 0.00),
    (8,  'freemium', 0.00),
    (9,  'freemium', 0.00),
    (10, 'freemium', 0.00);


-- ============================================================
--  7. SUSCRIPCIONES PREMIUM (usuarios 1, 2, 3 y 4)
--     Equivale a: CALL sp_cambiar_suscripcion(id, 'premium')
--     El SP hacía: UPDATE suscripcion + INSERT auditoria_log
-- ============================================================
UPDATE suscripcion
SET    tipo         = 'premium',
       fecha_inicio = CURRENT_DATE,
       fecha_fin    = CURRENT_DATE + INTERVAL '30 days',
       precio       = 9.99,
       activa       = TRUE
WHERE  id_usuario IN (1, 2, 3, 4);

INSERT INTO auditoria_log (tabla, operacion, id_registro, descripcion) VALUES
    ('suscripcion', 'UPDATE', 1, 'Cambio de suscripción: freemium → premium'),
    ('suscripcion', 'UPDATE', 2, 'Cambio de suscripción: freemium → premium'),
    ('suscripcion', 'UPDATE', 3, 'Cambio de suscripción: freemium → premium'),
    ('suscripcion', 'UPDATE', 4, 'Cambio de suscripción: freemium → premium');


-- ============================================================
--  8. PLAYLISTS (8 registros)
--     Equivale a: CALL sp_crear_playlist(...)
--     El SP hacía: INSERT playlist
--     Nota: trg_log_playlist se crea en V3, no existe aún aquí.
-- ============================================================
INSERT INTO playlist (id_usuario, nombre, descripcion, es_publica) VALUES
    (1, 'Mis Favoritas de Rock', 'Lo mejor del rock en español',     TRUE),
    (1, 'Para Estudiar',          'Música instrumental y electrónica', FALSE),
    (2, 'Vibes Urbanos',          'Reggaeton y Hip-Hop del momento',   TRUE),
    (3, 'Jazz & Soul',            'Sesiones de jazz y R&B',            TRUE),
    (4, 'Mix Latino',             'Pop y salsa latina',                TRUE),
    (5, 'Workout',                'Energía para el gym',               TRUE),
    (6, 'Noche de Viernes',       'Para la noche del fin de semana',   FALSE),
    (7, 'Acústica',               'Solo guitarra y voz',               TRUE);


-- ============================================================
--  9. CANCIONES EN PLAYLISTS
--     Equivale a: CALL sp_agregar_cancion_playlist(...)
--     El SP hacía: calcular posicion = MAX+1, INSERT playlist_cancion
--     trg_contador_playlist (V1) actualiza total_canciones automáticamente.
-- ============================================================
-- Playlist 1: Mis Favoritas de Rock
INSERT INTO playlist_cancion (id_playlist, id_cancion, posicion) VALUES
    (1, 1,  1),
    (1, 2,  2),
    (1, 3,  3),
    (1, 5,  4),
    (1, 23, 5);

-- Playlist 2: Para Estudiar
INSERT INTO playlist_cancion (id_playlist, id_cancion, posicion) VALUES
    (2, 12, 1),
    (2, 13, 2),
    (2, 14, 3),
    (2, 15, 4),
    (2, 30, 5);

-- Playlist 3: Vibes Urbanos
INSERT INTO playlist_cancion (id_playlist, id_cancion, posicion) VALUES
    (3, 18, 1),
    (3, 19, 2),
    (3, 25, 3),
    (3, 26, 4);

-- Playlist 4: Jazz & Soul
INSERT INTO playlist_cancion (id_playlist, id_cancion, posicion) VALUES
    (4, 15, 1),
    (4, 16, 2),
    (4, 17, 3),
    (4, 9,  4);

-- Playlist 5: Mix Latino
INSERT INTO playlist_cancion (id_playlist, id_cancion, posicion) VALUES
    (5, 7,  1),
    (5, 11, 2),
    (5, 21, 3),
    (5, 22, 4);

-- Playlist 6: Workout
INSERT INTO playlist_cancion (id_playlist, id_cancion, posicion) VALUES
    (6, 12, 1),
    (6, 18, 2),
    (6, 20, 3),
    (6, 30, 4);


-- ============================================================
--  10. LIKES / FAVORITOS
-- ============================================================
INSERT INTO like_cancion (id_usuario, id_cancion) VALUES
    (1,  1), (1,  2), (1,  3), (1,  7), (1, 12),
    (2, 18), (2, 19), (2, 25), (2, 26), (2, 20),
    (3, 15), (3, 16), (3, 17), (3,  9), (3,  8),
    (4,  7), (4, 11), (4, 21), (4, 22), (4, 10),
    (5, 12), (5, 14), (5, 30), (5, 18), (5,  5),
    (6,  7), (6,  8), (6,  9), (6, 11), (6, 28),
    (7,  1), (7,  3), (7, 23), (7, 24), (7,  6),
    (8, 15), (8, 16), (8, 21), (8, 22), (8, 29),
    (9, 25), (9, 26), (9, 27), (9, 18), (9, 12),
    (10, 1), (10, 7), (10,15), (10,21), (10,28);


-- ============================================================
--  11. VERIFICACIONES POST-INSERCIÓN
-- ============================================================
SELECT 'genero'        AS tabla, COUNT(*) AS registros FROM genero
UNION ALL SELECT 'artista',      COUNT(*) FROM artista
UNION ALL SELECT 'album',        COUNT(*) FROM album
UNION ALL SELECT 'cancion',      COUNT(*) FROM cancion
UNION ALL SELECT 'usuario',      COUNT(*) FROM usuario
UNION ALL SELECT 'suscripcion',  COUNT(*) FROM suscripcion
UNION ALL SELECT 'playlist',     COUNT(*) FROM playlist
UNION ALL SELECT 'like_cancion', COUNT(*) FROM like_cancion
ORDER BY tabla;

SELECT fn_duracion_total_playlist(1) AS duracion_playlist1_seg;
SELECT fn_canciones_por_artista(1)   AS canciones_los_oscuros;
SELECT fn_tiene_suscripcion_activa(1) AS usuario1_premium;

-- ============================================================
--  FIN DEL SCRIPT DML
--  SpotiClone – Universidad El Bosque – 2026-1
-- ============================================================
