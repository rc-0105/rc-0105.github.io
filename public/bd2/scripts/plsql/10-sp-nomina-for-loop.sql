


CREATE OR REPLACE PROCEDURE sp_nomina
IS
    v_comision   NUMBER;
    v_descuento  NUMBER;
    v_total      NUMBER;
BEGIN
    FOR emp IN (
        SELECT id,
               first_name,
               last_name,
               salary,
               NVL(commission,0) commission
        FROM samusa.employees
    )
    LOOP
        
        v_descuento := (emp.salary + emp.commission) * 0.10;

        v_total := (emp.salary + emp.commission) - v_descuento;

        DBMS_OUTPUT.PUT_LINE('Empleado: ' || emp.first_name || ' ' || emp.last_name);
        DBMS_OUTPUT.PUT_LINE('Salario Base: ' || emp.salary);
        DBMS_OUTPUT.PUT_LINE('Comisión: ' || emp.commission);
        DBMS_OUTPUT.PUT_LINE('Descuento (10%): ' || v_descuento);
        DBMS_OUTPUT.PUT_LINE('Total a pagar Febrero: ' || v_total);
        DBMS_OUTPUT.PUT_LINE('-----------------------------');
        
    END LOOP;
END;
/