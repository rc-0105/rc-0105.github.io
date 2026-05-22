/*
Ricardo Carrero
13/02/2026

Este script trae el salario, el nombre y la fecha de contratación del empleado 109 pero guardando al empleado en una variable rowtype

to_char() --> permite cambiar los valores de tipo numerico a char
*/


DECLARE
v_empleado HR.EMPLOYEES%ROWTYPE;
   
BEGIN
    SELECT * INTO v_empleado
    FROM hr.EMPLOYEES
    WHERE employee_id = 109;
    DBMS_OUTPUT.PUT_LINE(v_empleado.salary ||' '|| v_empleado.first_name ||' '|| v_empleado.hire_date);
END;
/