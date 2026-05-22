/*
Ricardo Carrero
13/02/2026
Este script trae el salario del empleado 109
Para declarar una variable se tienen las siguientes convenciones:
DECLARE
    vn_ --> Variable de tipo numerica
    vv_ --> Variable de tipo cadena
    vd_ --> Variable de tipo fecha
    vc_ --> Variable de tipo char
    vdo_ --> Variable de tipo double
    vt_ --> Variable de tipo 
    vb_ --> Variable de tipo byte
BEGIN
    Aqui va toda la logica de programacion
    Pueden ir sentencias:
    SQL y PL/SQL
END;
*/

DECLARE
    vn_salario HR.EMPLOYEES.salary%TYPE;
BEGIN
    SELECT salary INTO vn_salario 
    FROM hr.EMPLOYEES
    WHERE employee_id = 109;
    DBMS_OUTPUT.PUT_LINE(vn_salario);
END;
/


