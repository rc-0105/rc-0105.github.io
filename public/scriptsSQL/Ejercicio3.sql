/*
Ricardo Alberto Carrero Bator
6/02/2026
De los empleados se muestran son nombre empleado y nombre del gerente
*/

SELECT CONCAT (e.first_name,' ',e.LAST_NAME ) AS nombre, CONCAT (m.first_name,' ',m.LAST_NAME ) AS manager
FROM HR.EMPLOYEES e JOIN hr.EMPLOYEES m 
ON e.manager_id = m.employee_id
ORDER BY manager;