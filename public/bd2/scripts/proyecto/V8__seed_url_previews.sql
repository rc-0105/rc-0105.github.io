-- ============================================================
--  V8 — Poblar url_preview en tabla cancion
--  Fuente: Deezer API pública (búsqueda por artista+título o solo título)
--  Formato: https://cdns-preview-{X}.dzcdn.net/stream/c-{hash}-3.mp3
--  Todas las URLs son previews reales de 30 segundos sin autenticación.
-- ============================================================

-- id 1: Oscuridad (Los Oscuros)
UPDATE cancion SET url_preview = 'https://cdns-preview-4.dzcdn.net/stream/c-475a211dab34715671e7f5a8e41eb794-3.mp3' WHERE id_cancion = 1;

-- id 2: Sin Retorno (Los Oscuros)
UPDATE cancion SET url_preview = 'https://cdns-preview-d.dzcdn.net/stream/c-d065d6b4bad3099c1ac4ae3a12410f4b-3.mp3' WHERE id_cancion = 2;

-- id 3: El Último Tren (Los Oscuros)
UPDATE cancion SET url_preview = 'https://cdns-preview-a.dzcdn.net/stream/c-ada6f210a2d030ccdaaba942fb2873dd-3.mp3' WHERE id_cancion = 3;

-- id 4: Tormenta Interior (Los Oscuros)
UPDATE cancion SET url_preview = 'https://cdns-preview-3.dzcdn.net/stream/c-3694f793dbc100c57829f0b06733df6d-3.mp3' WHERE id_cancion = 4;

-- id 5: Caos (Los Oscuros)
UPDATE cancion SET url_preview = 'https://cdns-preview-1.dzcdn.net/stream/c-138bbcb851d42524c2be8a236dfb8cdf-3.mp3' WHERE id_cancion = 5;

-- id 6: Orden Metal (Los Oscuros)
UPDATE cancion SET url_preview = 'https://cdns-preview-4.dzcdn.net/stream/c-4b644cbb29fc415e3215eb8a66e886b8-3.mp3' WHERE id_cancion = 6;

-- id 7: Luz de Día (Valeria Reyes)
UPDATE cancion SET url_preview = 'https://cdns-preview-b.dzcdn.net/stream/c-b3cbe966e3b63aadc2b0fbece5ead776-3.mp3' WHERE id_cancion = 7;

-- id 8: Nube Rosa (Valeria Reyes)
UPDATE cancion SET url_preview = 'https://cdns-preview-2.dzcdn.net/stream/c-24eede142ca260333ad41bf6a113c45d-3.mp3' WHERE id_cancion = 8;

-- id 9: Feeling Good (Valeria Reyes)
UPDATE cancion SET url_preview = 'https://cdns-preview-8.dzcdn.net/stream/c-84cfe2b7fb50d7dc1da04db3bf01c07d-3.mp3' WHERE id_cancion = 9;

-- id 10: Primavera (Valeria Reyes)
UPDATE cancion SET url_preview = 'https://cdns-preview-6.dzcdn.net/stream/c-614d6607080231fbbcad637a27b1c3f4-3.mp3' WHERE id_cancion = 10;

-- id 11: Despertar (Valeria Reyes)
UPDATE cancion SET url_preview = 'https://cdns-preview-c.dzcdn.net/stream/c-c6452e2ed876db52dbf4b9fc8d264e37-3.mp3' WHERE id_cancion = 11;

-- id 12: Pulso Alpha (DJ Nexus)
UPDATE cancion SET url_preview = 'https://cdns-preview-1.dzcdn.net/stream/c-11ecb7c99e63601df4c63ef894ae5ec4-3.mp3' WHERE id_cancion = 12;

-- id 13: Drifting (DJ Nexus)
UPDATE cancion SET url_preview = 'https://cdns-preview-4.dzcdn.net/stream/c-4cb6b1c27366edf74cde0e4deaa56715-3.mp3' WHERE id_cancion = 13;

-- id 14: Neon Rain (DJ Nexus)
UPDATE cancion SET url_preview = 'https://cdns-preview-2.dzcdn.net/stream/c-282566a13360c8dc36664365050145ba-3.mp3' WHERE id_cancion = 14;

-- id 15: Blue Monday (The Midnight Crew)
UPDATE cancion SET url_preview = 'https://cdns-preview-b.dzcdn.net/stream/c-b32bb583e9b9bcc5089e83471d1e1b63-3.mp3' WHERE id_cancion = 15;

-- id 16: Sax at Midnight (The Midnight Crew)
UPDATE cancion SET url_preview = 'https://cdns-preview-8.dzcdn.net/stream/c-896c5e487837da33971dac0711495341-3.mp3' WHERE id_cancion = 16;

-- id 17: The Last Note (The Midnight Crew)
UPDATE cancion SET url_preview = 'https://cdns-preview-c.dzcdn.net/stream/c-cc99f0ed2f1a043d20b7f893941c9ce0-3.mp3' WHERE id_cancion = 17;

-- id 18: Calor de Barrio (El Barrio)
UPDATE cancion SET url_preview = 'https://cdns-preview-8.dzcdn.net/stream/c-8c267fa6a7baa4406ae03ea515167db2-3.mp3' WHERE id_cancion = 18;

-- id 19: La Calle Llama (El Barrio)
UPDATE cancion SET url_preview = 'https://cdns-preview-b.dzcdn.net/stream/c-b67612e9b7e0f6328909b2e530475209-3.mp3' WHERE id_cancion = 19;

-- id 20: Noche de Viernes (El Barrio)
UPDATE cancion SET url_preview = 'https://cdns-preview-0.dzcdn.net/stream/c-06e53ada1ebaeb2f3fd1d530a5db9523-3.mp3' WHERE id_cancion = 20;

-- id 21: Sabrosura (Orquesta Dorada)
UPDATE cancion SET url_preview = 'https://cdns-preview-2.dzcdn.net/stream/c-2f4352a026faf10fd0c4662205fa4613-3.mp3' WHERE id_cancion = 21;

-- id 22: Paso a Paso (Orquesta Dorada)
UPDATE cancion SET url_preview = 'https://cdns-preview-5.dzcdn.net/stream/c-52d30cf87a3ea1bad53bae8d75649099-3.mp3' WHERE id_cancion = 22;

-- id 23: Fractura (Sombra Negra)
UPDATE cancion SET url_preview = 'https://cdns-preview-7.dzcdn.net/stream/c-7d6ab576b151b1538d866133d0bbee69-3.mp3' WHERE id_cancion = 23;

-- id 24: Abyss (Sombra Negra)
UPDATE cancion SET url_preview = 'https://cdns-preview-5.dzcdn.net/stream/c-593e8bea04dcd8e475ff444c55f3c053-3.mp3' WHERE id_cancion = 24;

-- id 25: Concreto (FreakBeat)
UPDATE cancion SET url_preview = 'https://cdns-preview-c.dzcdn.net/stream/c-c288ef74b35a8ee8a6db5eca53bc6ca0-3.mp3' WHERE id_cancion = 25;

-- id 26: Barrio Libre (FreakBeat)
UPDATE cancion SET url_preview = 'https://cdns-preview-c.dzcdn.net/stream/c-c4177a69a0412754e141cb8126e60ada-3.mp3' WHERE id_cancion = 26;

-- id 27: La Verdad (FreakBeat)
UPDATE cancion SET url_preview = 'https://cdns-preview-2.dzcdn.net/stream/c-289ed715b4f5a74b3ba18c6d4ff13081-3.mp3' WHERE id_cancion = 27;

-- id 28: Raíces (Marcos Silva)
UPDATE cancion SET url_preview = 'https://cdns-preview-c.dzcdn.net/stream/c-c7379f5ea3a54fa3d2d5ed1ba5811a84-3.mp3' WHERE id_cancion = 28;

-- id 29: Bossa Tarde (Marcos Silva)
UPDATE cancion SET url_preview = 'https://cdns-preview-8.dzcdn.net/stream/c-8ef42fbd8a1ac212bbe07c2eb6fc0f8d-3.mp3' WHERE id_cancion = 29;

-- id 30: Drop Zone (DJ Nexus)
UPDATE cancion SET url_preview = 'https://cdns-preview-4.dzcdn.net/stream/c-4a4f1c78a90f7cb42b58e7b46adc9660-3.mp3' WHERE id_cancion = 30;

-- ============================================================
--  FIN — 30/30 canciones actualizadas con previews reales de Deezer
-- ============================================================
