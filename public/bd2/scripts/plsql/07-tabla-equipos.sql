/*
Creacion de tabla equipos einsertar equipos de 
*/
CREATE TABLE equipo(
    codigo number primary key, 
    nombre VARCHAR2(100),
    pais NUMBER);

BEGIN
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (1, 'Real Madrid', 'España');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (2, 'Barcelona', 'España');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (3, 'Atlético de Madrid', 'España');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (4, 'Manchester United', 'Inglaterra');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (5, 'Manchester City', 'Inglaterra');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (6, 'Liverpool', 'Inglaterra');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (7, 'Chelsea', 'Inglaterra');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (8, 'Arsenal', 'Inglaterra');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (9, 'Bayern Múnich', 'Alemania');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (10, 'Borussia Dortmund', 'Alemania');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (11, 'Juventus', 'Italia');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (12, 'AC Milan', 'Italia');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (13, 'Inter de Milán', 'Italia');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (14, 'Napoli', 'Italia');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (15, 'Paris Saint-Germain', 'Francia');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (16, 'Olympique de Marsella', 'Francia');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (17, 'Ajax', 'Países Bajos');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (18, 'PSV Eindhoven', 'Países Bajos');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (19, 'Porto', 'Portugal');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (20, 'Benfica', 'Portugal');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (21, 'Sporting Lisboa', 'Portugal');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (22, 'Boca Juniors', 'Argentina');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (23, 'River Plate', 'Argentina');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (24, 'Racing Club', 'Argentina');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (25, 'Independiente', 'Argentina');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (26, 'Flamengo', 'Brasil');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (27, 'Palmeiras', 'Brasil');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (28, 'Santos', 'Brasil');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (29, 'Corinthians', 'Brasil');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (30, 'São Paulo', 'Brasil');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (31, 'América', 'México');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (32, 'Chivas Guadalajara', 'México');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (33, 'Cruz Azul', 'México');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (34, 'Pumas UNAM', 'México');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (35, 'LA Galaxy', 'Estados Unidos');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (36, 'New York City FC', 'Estados Unidos');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (37, 'Al Hilal', 'Arabia Saudita');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (38, 'Al Nassr', 'Arabia Saudita');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (39, 'Galatasaray', 'Turquía');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (40, 'Fenerbahçe', 'Turquía');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (41, 'Celtic', 'Escocia');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (42, 'Rangers', 'Escocia');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (43, 'Shakhtar Donetsk', 'Ucrania');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (44, 'Dynamo Kyiv', 'Ucrania');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (45, 'Olympiacos', 'Grecia');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (46, 'Red Bull Salzburg', 'Austria');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (47, 'Club Brugge', 'Bélgica');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (48, 'Monterrey', 'México');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (49, 'Atlético Nacional', 'Colombia');
        INSERT INTO rcarrero.equipo (codigo, nombre, pais) VALUES (50, 'Universidad de Chile', 'Chile');
END;
/

DROP table equipo;

