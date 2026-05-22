/*
Ricardo Carrero
13/02/2026

Este script trae el salario, el nombre y la fecha de contratación del empleado 109.

*/

DECLARE
    v_salario HR.EMPLOYEES.salary%TYPE;
    v_nombre  HR.EMPLOYEES.FIRST_NAME%TYPE;
    v_fecha_contratacion HR.EMPLOYEES.HIRE_DATE%TYPE;
    
BEGIN
    SELECT salary, first_name, hire_date INTO v_salario, v_nombre, v_fecha_contratacion
    FROM hr.EMPLOYEES
    WHERE employee_id = 109;
    DBMS_OUTPUT.PUT_LINE(v_salario ||' '|| v_nombre ||' '|| v_fecha_contratacion);
END;
/


