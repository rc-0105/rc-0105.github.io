/*
Ricardo Carrero
13/02/2026

Este script trae toda la informacion del departamento 80 

*/



DECLARE
v_department HR.departmentS%ROWTYPE;
   
BEGIN
    SELECT * INTO v_department
    FROM hr.DEPARTMENTS
    WHERE department_id = 80;
    DBMS_OUTPUT.PUT_LINE(v_department.department_id ||' '|| v_department.department_name ||' '|| v_department.manager_id ||' '||v_department.location_id );
END;
/

