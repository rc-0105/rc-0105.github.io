CREATE OR REPLACE PROCEDURE sp_nomina
IS
    CURSOR c_emp IS
        SELECT employee_id,
               first_name,
               last_name,
               salary,
               NVL(commission_pct,0) commission_pct
        FROM samesa.employees;

    v_id          samesa.employees.employee_id%TYPE;
    v_nombre      samesa.employees.first_name%TYPE;
    v_apellido    samesa.employees.last_name%TYPE;
    v_salario     samesa.employees.salary%TYPE;
    v_comision    samesa.employees.commission_pct%TYPE;

    v_descuento   NUMBER;
    v_total       NUMBER;

BEGIN

    OPEN c_emp;

    FETCH c_emp INTO
        v_id,
        v_nombre,
        v_apellido,
        v_salario,
        v_comision;

    WHILE c_emp%FOUND LOOP

        v_descuento := (v_salario + v_comision) * 0.10;

        v_total := (v_salario + v_comision) - v_descuento;

        DBMS_OUTPUT.PUT_LINE('Empleado: ' || v_nombre || ' ' || v_apellido);
        DBMS_OUTPUT.PUT_LINE('Total a pagar Febrero: ' || v_total);
        DBMS_OUTPUT.PUT_LINE('-----------------------------');

        FETCH c_emp INTO
            v_id,
            v_nombre,
            v_apellido,
            v_salario,
            v_comision;

    END LOOP;

    CLOSE c_emp;

END;
/


BEGIN
    sp_nomina;
END;
/