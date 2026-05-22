/*
Ricardo Carrero
16/02/2026
Crear un procedimiento que reciba un parametro de entrada el cual va a ser de tipo numerico,
va a recibir de codigo, pais y el procedimiento lo que va a realizar es poner el nombre del pais a minusculas

La convencion para prodecimientos almacenados sp_

El procedimiento se debe llamar sp_actualizapais
*/

CREATE OR REPLACE 
PROCEDURE sp_actualizaPais (codigo number, paisN varchar2)
IS
BEGIN
    UPDATE rcarrero.pais
    SET nombre = LOWER(paisN)
    WHERE codigo_pais = codigo;
    COMMIT;
END sp_actualizapais;
/
