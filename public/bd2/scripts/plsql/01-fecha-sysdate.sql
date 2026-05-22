/*
Ricardo Carrero
13/02/2026
Este script sirve para asignar la fecha actual en una variable.
*/
-- SET SERVEROUTPUT ON;

DECLARE
    fecha timestamp;
BEGIN
    SELECT sysdate INTO fecha FROM dual;
    dbms_output.put_line('La fecha es: '||fecha);
END;
/

