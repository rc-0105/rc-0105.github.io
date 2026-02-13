/*
Ricardo Carrero
11/02/2026

Este script muestra el nombre de cada empleado y el número de trabajos que ha tenido, incluyendo su trabajo actual. Para obtener el número total de trabajos, se realiza una unión entre la tabla de empleados y la tabla de historial de trabajos, contando el número de registros en el historial y sumando uno para incluir el trabajo actual del empleado. El resultado se agrupa por el nombre del empleado para mostrar la información de manera clara.
*/
SELECT CONCAT (e.first_name,' ',e.LAST_NAME ) AS nombre, COUNT(jh.JOB_ID)+1 AS trabajos
FROM HR.EMPLOYEES e JOIN hr.JOB_HISTORY jh
ON e.EMPLOYEE_ID = jh.EMPLOYEE_ID
GROUP BY nombre;