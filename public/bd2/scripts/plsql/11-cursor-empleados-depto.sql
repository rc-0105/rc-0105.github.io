
DECLARE 
    CURSOR c_empleados(p_departamento NUMBER) IS 
        SELECT * 
        FROM samesa.EMPLOYEES
        WHERE department_id = p_departamento;
    v_empleado samesa.EMPLOYEES%ROWTYPE;
BEGIN
    OPEN c_empleados(&departamento);
    LOOP
        FETCH c_empleados INTO v_empleado;
        EXIT WHEN c_empleados%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(
            'ID: ' || v_empleado.employee_id ||
            ' | FIRST_NAME: ' || v_empleado.first_name ||
            ' | LAST_NAME: ' || v_empleado.last_name ||
            ' | EMAIL: ' || v_empleado.email ||
            ' | PHONE: ' || v_empleado.phone_number ||
            ' | HIRE_DATE: ' || v_empleado.hire_date ||
            ' | JOB_ID: ' || v_empleado.job_id ||
            ' | SALARY: ' || v_empleado.salary ||
            ' | COMMISSION: ' || v_empleado.commission_pct ||
            ' | MANAGER_ID: ' || v_empleado.manager_id ||
            ' | DEPARTMENT_ID: ' || v_empleado.department_id
        );
    END LOOP;
    CLOSE c_empleados;
    commit;
END;
/
