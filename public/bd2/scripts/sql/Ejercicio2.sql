/*
Ricardo Alberto Carrero Bator
6/02/2026
De los empleados se muestran son nombre empleado, país y salario que vivan o trabajen en Europa y que ganen entre 7000 y 9000 dólares
*/


SELECT CONCAT (e.first_name,' ',e.LAST_NAME ) AS nombre,e.salary,c.COUNTRY_NAME
FROM HR.EMPLOYEES e JOIN hr.DEPARTMENTS d
ON e.DEPARTMENT_ID = d.DEPARTMENT_ID
JOIN HR.LOCATIONS L
ON d.location_ID = l.location_ID
JOIN hr.countries c
ON l.country_ID = c.country_ID
WHERE c.REGION_ID = 10 AND SALARY BETWEEN 7000 AND 9000