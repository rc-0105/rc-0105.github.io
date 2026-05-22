/*
Ricardo Carrero
16/02/2026
Imprimir por consola el nombre del pais que mas equipos tenga en mi base de datos
*/

DECLARE
    vc_nombre rcarrero.equipo.pais%TYPE;
BEGIN
    SELECT pais
    INTO vc_nombre
    FROM rcarrero.equipo ON P.ID_PAIS = E.ID_PAIS
    GROUP BY P.NOMBRE
    ORDER BY 1 DESC
    FETCH FIRST 1 ROW ONLY;

    DBMS_OUTPUT.PUT_LINE(vc_nombre);
END;
/

SELECT pais
    INTO vc_nombre
    FROM rcarrero.equipo
    GROUP BY pais
    ORDER BY COUNT(*) DESC
;

