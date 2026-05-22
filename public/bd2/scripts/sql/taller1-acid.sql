-- =====================================================================
-- 03_template_entrega_taller1_v2.sql
-- Taller aplicado 1 - SQL avanzado + Transacciones (ACID) aplicado
-- Plantilla de entrega para estudiantes
--
-- IMPORTANTE:
-- 1. Trabajar únicamente sobre las tablas T1_% y AUDIT_SALARY_ADJUSTMENTS_T1
-- 2. NO modificar la estructura del entorno entregado por el docente
-- 3. NO eliminar secciones de esta plantilla
-- 4. Reemplazar únicamente los bloques indicados como "ESCRIBA AQUÍ"
-- 5. Usar la variante asignada por el docente (1, 2, 3 o 4)
-- 6. Usar un tag único de ejecución final, por ejemplo: P03_FINAL
-- =====================================================================

SET SERVEROUTPUT ON
SET FEEDBACK ON

-- ============================================================
-- 0. ENCABEZADO OBLIGATORIO
-- Complete toda esta información antes de ejecutar el script.
-- ============================================================
-- Integrante 1: Samuel Mesa
-- Integrante 2: Ricardo Carrero
-- Curso: _________________________________________________
-- Fecha: _________________________________________________
-- Variante asignada por el docente (1, 2, 3 o 4): 1
-- Tag de ejecución final (ejemplo: P03_FINAL): P01

DEFINE p_variant_id = 1
DEFINE p_execution_tag = 'P01_FINAL'

PROMPT ===== 0. VERIFICACIÓN DE LA VARIANTE ASIGNADA =====
SELECT
    variant_id,
    variant_name,
    excluded_department_id,
    min_years_service,
    recent_job_history_months,
    gap_high_threshold_pct,
    gap_mid_threshold_pct,
    raise_high_pct,
    raise_mid_pct,
    raise_low_pct,
    max_salary_vs_avg_pct,
    notes
FROM t1_variants
WHERE variant_id = &p_variant_id;

-- ============================================================
-- GUÍA RÁPIDA DE OBJETOS DISPONIBLES
-- Use estos nombres reales de tablas y columnas.
-- ============================================================
-- Tabla principal de empleados: T1_EMPLOYEES
-- Columnas más importantes:
--   employee_id, first_name, last_name, email, phone_number,
--   hire_date, job_id, salary, commission_pct, manager_id, department_id
--
-- Tabla de departamentos: T1_DEPARTMENTS
-- Columnas más importantes:
--   department_id, department_name, manager_id, location_id
--
-- Tabla de historial laboral: T1_JOB_HISTORY
-- Columnas más importantes:
--   employee_id, start_date, end_date, job_id, department_id
--
-- Tabla de auditoría: AUDIT_SALARY_ADJUSTMENTS_T1
-- Columnas:
--   audit_id, execution_tag, variant_id, employee_id, department_id,
--   salary_before, salary_after, pct_gap_to_avg_before, rule_applied,
--   executed_by, executed_at, notes
--
-- Tabla de variantes: T1_VARIANTS
-- Columnas:
--   variant_id, variant_name, excluded_department_id, min_years_service,
--   recent_job_history_months, gap_high_threshold_pct,
--   gap_mid_threshold_pct, raise_high_pct, raise_mid_pct,
--   raise_low_pct, max_salary_vs_avg_pct, notes

-- ============================================================
-- GUÍA RÁPIDA DE TÉRMINOS QUE DEBE USAR EN SU SOLUCIÓN
-- ============================================================
-- CTE:
--   Una CTE es una consulta temporal escrita con WITH.
--   Sirve para dividir una consulta grande en partes más claras.
--
--   Ejemplo:
--   WITH dept_stats AS (
--       SELECT department_id, AVG(salary) avg_salary
--       FROM t1_employees
--       GROUP BY department_id
--   )
--   SELECT *
--   FROM dept_stats;
--
-- Función analítica:
--   Es una función como ROW_NUMBER, RANK o DENSE_RANK.
--   Sirve para calcular posiciones o comparaciones sin perder el detalle.
--
--   Ejemplo:
--   DENSE_RANK() OVER (PARTITION BY department_id ORDER BY salary DESC)
--
-- JOIN:
--   Es la unión entre tablas relacionadas, por ejemplo empleados y departamentos.
--
-- Subconsulta:
--   Es una consulta dentro de otra consulta.
--
-- SAVEPOINT:
--   Es un punto de restauración dentro de una transacción.
--   Permite devolver la operación a un punto intermedio con ROLLBACK TO.

-- ============================================================
-- 1. CONSULTA DIAGNÓSTICA
-- OBJETIVO:
-- Analizar la información antes de actualizar salarios.
--
-- SU CONSULTA DEBE MOSTRAR, COMO MÍNIMO, ESTAS COLUMNAS:
--   employee_id
--   first_name
--   last_name
--   job_id
--   manager_id
--   department_id
--   department_name
--   salary
--   hire_date
--   years_service
--   dept_avg_salary
--   dept_max_salary
--   dept_employee_count
--   pct_gap_to_avg
--   recent_job_history_flag
--   salary_rank_in_department
--
-- QUÉ SIGNIFICA CADA COLUMNA:
--   years_service: años de antigüedad del empleado
--   dept_avg_salary: promedio salarial del departamento
--   dept_max_salary: salario más alto del departamento
--   dept_employee_count: cantidad de empleados del departamento
--   pct_gap_to_avg: porcentaje que le falta al salario del empleado para llegar
--                   al promedio del departamento
--   recent_job_history_flag: SI o NO, según si tuvo historial reciente
--   salary_rank_in_department: posición salarial dentro del departamento
--
-- IMPORTANTE:
-- - Puede usar una o varias CTE
-- - Debe usar al menos una función analítica
-- - Debe unir como mínimo T1_EMPLOYEES con T1_DEPARTMENTS
-- - Debe revisar T1_JOB_HISTORY para detectar historial reciente
-- ============================================================

PROMPT ===== 1. CONSULTA DIAGNÓSTICA =====

-- ESCRIBA AQUÍ SU CONSULTA DIAGNÓSTICA PRINCIPAL
-- Debe devolver las columnas mínimas exigidas arriba.

with Variante As (
SELECT excluded_department_id,min_years_service, recent_job_history_months,
       gap_high_threshold_pct, gap_mid_threshold_pct,
       raise_high_pct, raise_mid_pct, raise_low_pct,
       max_salary_vs_avg_pct
FROM t1_variants WHERE variant_id = &p_variant_id),
dinfo AS (
    SELECT department_id,
           ROUND(AVG(salary), 2) AS dept_avg_salary,
           MAX(salary)            AS dept_max_salary,
           COUNT(*)               AS dept_employee_count
    FROM t1_employees
    WHERE department_id IS NOT NULL
    GROUP BY department_id
),
hreciente AS (
    SELECT DISTINCT jh.employee_id
    FROM t1_job_history jh
    CROSS JOIN Variante v
    WHERE jh.start_date >= ADD_MONTHS(SYSDATE, -v.recent_job_history_months)
)
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.job_id,
    e.manager_id,
    e.department_id,
    d.department_name,
    e.salary,
    e.hire_date,
    ROUND(MONTHS_BETWEEN(SYSDATE, e.hire_date) / 12, 1) AS years_service,
    ds.dept_avg_salary,
    ds.dept_max_salary,
    ds.dept_employee_count,
    ROUND(
        CASE WHEN e.salary < ds.dept_avg_salary
             THEN (ds.dept_avg_salary - e.salary) / ds.dept_avg_salary * 100
             ELSE 0
        END, 2) AS pct_gap_to_avg,
    CASE WHEN rh.employee_id IS NOT NULL THEN 'SI' ELSE 'NO' END AS recent_job_history_flag,
    DENSE_RANK() OVER (
        PARTITION BY e.department_id ORDER BY e.salary DESC
    )                                                            AS salary_rank_in_department
FROM t1_employees   e
JOIN t1_departments d  ON e.department_id = d.department_id
JOIN dinfo     ds ON e.department_id = ds.department_id
LEFT JOIN hreciente rh ON e.employee_id = rh.employee_id
ORDER BY e.department_id, salary_rank_in_department;

-- COMENTARIO OBLIGATORIO:


-- ============================================================
-- 2. DECISIÓN DE POBLACIÓN ELEGIBLE
-- OBJETIVO:
-- Determinar qué empleados sí califican, cuáles no califican y por qué.
--
-- SU CONSULTA DEBE MOSTRAR, COMO MÍNIMO, ESTAS COLUMNAS:
--   employee_id
--   first_name
--   last_name
--   department_id
--   department_name
--   salary
--   years_service
--   dept_avg_salary
--   dept_max_salary
--   dept_employee_count
--   pct_gap_to_avg
--   recent_job_history_flag
--   manager_or_exec_flag
--   eligibility_flag
--   exclusion_reason
--   adjustment_pct
--   rule_applied
--
-- QUÉ SIGNIFICA CADA COLUMNA:
--   manager_or_exec_flag: SI o NO, según si es gerente principal o alta dirección
--   eligibility_flag: ELEGIBLE o NO_ELEGIBLE
--   exclusion_reason: motivo de exclusión, por ejemplo:
--                     SIN_DEPARTAMENTO, HISTORIAL_RECIENTE,
--                     ANTIGUEDAD_INSUFICIENTE, MANAGER_O_DIRECTIVO,
--                     DEPTO_EXCLUIDO, DEPTO_MENOR_A_3, SALARIO_NO_APLICA
--   adjustment_pct: porcentaje de ajuste que le corresponde
--   rule_applied: regla aplicada, por ejemplo AJUSTE_ALTO, AJUSTE_MEDIO, AJUSTE_BAJO
--
-- IMPORTANTE:
-- - Debe tomar en cuenta la variante asignada por el docente
-- - Debe usar los valores de T1_VARIANTS según &p_variant_id
-- - Debe quedar visible por qué una persona sí o no entra al proceso
-- ============================================================

PROMPT ===== 2. DECISIÓN DE ELEGIBLES =====

-- ESCRIBA AQUÍ SU CONSULTA DE DECISIÓN DE ELEGIBLES
-- Debe devolver las columnas mínimas exigidas arriba.

with Variante As (
SELECT excluded_department_id,min_years_service, recent_job_history_months,
       gap_high_threshold_pct, gap_mid_threshold_pct,
       raise_high_pct, raise_mid_pct, raise_low_pct,
       max_salary_vs_avg_pct
FROM t1_variants WHERE variant_id = &p_variant_id),
dinfo AS (
    SELECT department_id,
           ROUND(AVG(salary), 2) AS dept_avg_salary,
           MAX(salary)            AS dept_max_salary,
           COUNT(*)               AS dept_employee_count
    FROM t1_employees
    WHERE department_id IS NOT NULL
    GROUP BY department_id
),
hreciente AS (
    SELECT DISTINCT jh.employee_id
    FROM t1_job_history jh
    CROSS JOIN Variante v
    WHERE jh.start_date >= ADD_MONTHS(SYSDATE, -v.recent_job_history_months)
),
base AS (
    SELECT
        e.employee_id, e.first_name, e.last_name,
        e.department_id, d.department_name, e.salary,
        e.hire_date, e.job_id,
        ROUND(MONTHS_BETWEEN(SYSDATE, e.hire_date) / 12, 1) AS years_service,
        ds.dept_avg_salary, ds.dept_max_salary, ds.dept_employee_count,
        ROUND(
            CASE WHEN e.salary < ds.dept_avg_salary
                 THEN (ds.dept_avg_salary - e.salary) / ds.dept_avg_salary * 100
                 ELSE 0 END, 2) AS pct_gap_to_avg,
        CASE WHEN rh.employee_id IS NOT NULL THEN 'SI' ELSE 'NO' END AS recent_job_history_flag,
        CASE
            WHEN e.job_id IN ('AD_PRES', 'AD_VP')
              OR e.employee_id IN (
                   SELECT manager_id FROM t1_departments WHERE manager_id IS NOT NULL
                 )
            THEN 'SI' ELSE 'NO' END AS manager_or_exec_flag,
        v.excluded_department_id, v.min_years_service AS min_years,
        v.gap_high_threshold_pct, v.gap_mid_threshold_pct,
        v.raise_high_pct, v.raise_mid_pct, v.raise_low_pct,
        v.max_salary_vs_avg_pct
    FROM t1_employees   e
    JOIN t1_departments d  ON e.department_id = d.department_id
    JOIN dinfo ds ON e.department_id = ds.department_id
    LEFT JOIN hreciente rh ON e.employee_id = rh.employee_id
    CROSS JOIN variante v      
)
SELECT
    employee_id, first_name, last_name, department_id, department_name,
    salary, years_service, dept_avg_salary, dept_max_salary,
    dept_employee_count, pct_gap_to_avg,
    recent_job_history_flag, manager_or_exec_flag,
    CASE
        WHEN department_id = excluded_department_id THEN 'NO_ELEGIBLE'
        WHEN dept_employee_count < 3                THEN 'NO_ELEGIBLE'
        WHEN years_service < min_years              THEN 'NO_ELEGIBLE'
        WHEN recent_job_history_flag = 'SI'         THEN 'NO_ELEGIBLE'
        WHEN manager_or_exec_flag   = 'SI'          THEN 'NO_ELEGIBLE'
        WHEN pct_gap_to_avg         = 0             THEN 'NO_ELEGIBLE'
        ELSE 'ELEGIBLE'
    END AS eligibility_flag,
    CASE
        WHEN department_id = excluded_department_id THEN 'DEPTO_EXCLUIDO'
        WHEN dept_employee_count < 3                THEN 'DEPTO_MENOR_A_3'
        WHEN years_service < min_years              THEN 'ANTIGUEDAD_INSUFICIENTE'
        WHEN recent_job_history_flag = 'SI'         THEN 'HISTORIAL_RECIENTE'
        WHEN manager_or_exec_flag   = 'SI'          THEN 'MANAGER_O_DIRECTIVO'
        WHEN pct_gap_to_avg         = 0             THEN 'SALARIO_NO_APLICA'
        ELSE NULL
    END AS exclusion_reason,
    CASE
        WHEN pct_gap_to_avg > gap_high_threshold_pct THEN raise_high_pct
        WHEN pct_gap_to_avg > gap_mid_threshold_pct  THEN raise_mid_pct
        WHEN pct_gap_to_avg > 0                      THEN raise_low_pct
        ELSE NULL
    END AS adjustment_pct,
    CASE
        WHEN pct_gap_to_avg > gap_high_threshold_pct THEN 'AJUSTE_ALTO'
        WHEN pct_gap_to_avg > gap_mid_threshold_pct  THEN 'AJUSTE_MEDIO'
        WHEN pct_gap_to_avg > 0                      THEN 'AJUSTE_BAJO'
        ELSE NULL
    END AS rule_applied
FROM base
ORDER BY eligibility_flag, department_id;

-- COMENTARIO OBLIGATORIO:
-- Explique en 3 a 5 líneas cómo aplicó la variante y por qué su población
-- elegible sí cumple las reglas del caso.

-- ============================================================
-- 3. PREVALIDACIÓN ANTES DE LA TRANSACCIÓN
-- OBJETIVO:
-- Mostrar qué pasaría antes de ejecutar el cambio real.
--
-- DEBE MOSTRAR, COMO MÍNIMO:
-- A. Un resumen con estas columnas:
--    total_eligible_employees
--    total_salary_before
--    total_salary_after
--    total_increment
--
-- B. Un detalle de empleados elegibles con estas columnas:
--    employee_id
--    department_id
--    salary_before
--    salary_after
--    adjustment_pct
--    rule_applied
--
-- C. Un control de topes por departamento con estas columnas:
--    department_id
--    department_name
--    dept_avg_salary
--    dept_max_salary
--    max_allowed_salary_by_variant
--
-- QUÉ SIGNIFICA:
--   total_salary_before: suma de salarios antes del ajuste
--   total_salary_after: suma de salarios proyectados después del ajuste
--   total_increment: incremento total proyectado
--   max_allowed_salary_by_variant: salario máximo permitido según la variante
-- ============================================================

PROMPT ===== 3. PREVALIDACIÓN =====

-- ESCRIBA AQUÍ SU CONSULTA O SUS CONSULTAS DE PREVALIDACIÓN
-- Debe mostrar el resumen, el detalle y el control de topes.

with Variante As (
SELECT excluded_department_id,min_years_service, recent_job_history_months,
       gap_high_threshold_pct, gap_mid_threshold_pct,
       raise_high_pct, raise_mid_pct, raise_low_pct,
       max_salary_vs_avg_pct
FROM t1_variants WHERE variant_id = &p_variant_id),
dinfo AS (
    SELECT department_id,
           ROUND(AVG(salary), 2) AS dept_avg_salary,
           MAX(salary)            AS dept_max_salary,
           COUNT(*)               AS dept_employee_count
    FROM t1_employees
    WHERE department_id IS NOT NULL
    GROUP BY department_id
),
hreciente AS (
    SELECT DISTINCT jh.employee_id
    FROM t1_job_history jh
    CROSS JOIN Variante v
    WHERE jh.start_date >= ADD_MONTHS(SYSDATE, -v.recent_job_history_months)
),
elegibles AS (
    SELECT
        e.employee_id, e.department_id, e.salary AS salary_before,
        ds.dept_avg_salary,
        ROUND((ds.dept_avg_salary - e.salary) / ds.dept_avg_salary * 100, 2) AS pct_gap,
        CASE
            WHEN ROUND((ds.dept_avg_salary - e.salary)/ds.dept_avg_salary*100,2)
                 > v.gap_high_threshold_pct THEN v.raise_high_pct
            WHEN ROUND((ds.dept_avg_salary - e.salary)/ds.dept_avg_salary*100,2)
                 > v.gap_mid_threshold_pct  THEN v.raise_mid_pct
            ELSE v.raise_low_pct END AS adjustment_pct,
        CASE
            WHEN ROUND((ds.dept_avg_salary - e.salary)/ds.dept_avg_salary*100,2)
                 > v.gap_high_threshold_pct THEN 'AJUSTE_ALTO'
            WHEN ROUND((ds.dept_avg_salary - e.salary)/ds.dept_avg_salary*100,2)
                 > v.gap_mid_threshold_pct  THEN 'AJUSTE_MEDIO'
            ELSE 'AJUSTE_BAJO' END AS rule_applied,
        v.max_salary_vs_avg_pct
    FROM t1_employees e
    JOIN t1_departments d  ON e.department_id = d.department_id
    JOIN dinfo     ds ON e.department_id = ds.department_id
    LEFT JOIN hreciente rh ON e.employee_id = rh.employee_id
    CROSS JOIN variante v
    WHERE e.department_id != v.excluded_department_id
      AND ds.dept_employee_count >= 3
      AND MONTHS_BETWEEN(SYSDATE, e.hire_date) / 12 >= v.min_years_service
      AND rh.employee_id IS NULL      
      AND e.salary < ds.dept_avg_salary   
      AND e.job_id NOT IN ('AD_PRES', 'AD_VP')
      AND e.employee_id NOT IN (SELECT manager_id FROM t1_departments WHERE manager_id IS NOT NULL)
),
proyeccion AS (
    SELECT
        employee_id, department_id,salary_before,
        ROUND(LEAST(salary_before * (1 + adjustment_pct / 100),dept_avg_salary * max_salary_vs_avg_pct / 100), 2) AS salary_after,
        adjustment_pct, rule_applied
    FROM elegibles
)

-- A. Resumen del cambio
SELECT
    COUNT(*)                             AS total_eligible_employees,
    SUM(salary_before)                   AS total_salary_before,
    SUM(salary_after)                    AS total_salary_after,
    SUM(salary_after - salary_before)    AS total_increment
FROM proyeccion;

-- B. DETALLE POR EMPLEADO
SELECT employee_id, department_id, salary_before, salary_after,
       adjustment_pct, rule_applied
FROM proyeccion
ORDER BY department_id, employee_id;

-- C. TOPES POR DEPARTAMENTO
SELECT
    ds.department_id,
    d.department_name,
    ROUND(ds.dept_avg_salary, 2) AS dept_avg_salary,
    ds.dept_max_salary,
    ROUND(ds.dept_avg_salary * v.max_salary_vs_avg_pct / 100, 2) AS max_allowed_salary_by_variant
FROM (
    SELECT department_id,
           ROUND(AVG(salary), 2) AS dept_avg_salary,
           MAX(salary) AS dept_max_salary
    FROM t1_employees WHERE department_id IS NOT NULL
    GROUP BY department_id
) ds
JOIN t1_departments d ON ds.department_id = d.department_id
CROSS JOIN Variante v
WHERE ds.department_id IN (SELECT DISTINCT department_id FROM proyeccion)
ORDER BY ds.department_id;

-- ============================================================
-- 4. EJECUCIÓN TRANSACCIONAL
-- OBJETIVO:
-- Ejecutar la actualización real y registrar la auditoría.
--
-- DEBE INCLUIR OBLIGATORIAMENTE:
-- 1. SAVEPOINT
-- 2. UPDATE o MERGE para actualizar salarios
-- 3. INSERT a AUDIT_SALARY_ADJUSTMENTS_T1
-- 4. Validación intermedia
-- 5. COMMIT o ROLLBACK TO SAVEPOINT
--
-- IMPORTANTE:
-- - La auditoría debe usar el valor &p_execution_tag
-- - La auditoría debe usar el valor &p_variant_id
-- - Debe usar la secuencia AUDIT_SALARY_ADJ_T1_SEQ.NEXTVAL
-- ============================================================

PROMPT ===== 4. EJECUCIÓN TRANSACCIONAL =====

SAVEPOINT sv_before_adjustment;

-- 4.1 ACTUALIZACIÓN DE SALARIOS
-- ESCRIBA AQUÍ SU UPDATE O MERGE
-- Debe actualizar únicamente empleados ELEGIBLES.

UPDATE t1_employees e
SET salary = (
    SELECT salary_after
    FROM audit_salary_adjustments_t1 a
    WHERE a.employee_id = e.employee_id
      AND a.execution_tag = '&p_execution_tag'
)
WHERE employee_id IN (
    SELECT employee_id FROM audit_salary_adjustments_t1
    WHERE execution_tag = '&p_execution_tag'
);

-- 4.2 INSERCIÓN EN AUDITORÍA
-- Debe llenar estas columnas de AUDIT_SALARY_ADJUSTMENTS_T1:
--   audit_id               -> usar AUDIT_SALARY_ADJ_T1_SEQ.NEXTVAL
--   execution_tag          -> usar &p_execution_tag
--   variant_id             -> usar &p_variant_id
--   employee_id            -> id del empleado ajustado
--   department_id          -> departamento del empleado
--   salary_before          -> salario antes del ajuste
--   salary_after           -> salario después del ajuste
--   pct_gap_to_avg_before  -> brecha porcentual antes del ajuste
--   rule_applied           -> regla aplicada
--   executed_by            -> USER
--   executed_at            -> SYSDATE
--   notes                  -> comentario libre

INSERT INTO audit_salary_adjustments_t1 (
    audit_id,
    execution_tag,
    variant_id,
    employee_id,
    department_id,
    salary_before,
    salary_after,
    pct_gap_to_avg_before,
    rule_applied,
    executed_by,
    executed_at,
    notes
)
-- ESCRIBA AQUÍ SU SELECT O VALUES PARA INSERTAR LA AUDITORÍA

INSERT INTO audit_salary_adjustments_t1 (
    audit_id, execution_tag, variant_id, employee_id, department_id,
    salary_before, salary_after, pct_gap_to_avg_before,
    rule_applied, executed_by, executed_at, notes
)
WITH Variante AS (
    SELECT excluded_department_id,min_years_service, recent_job_history_months,
           gap_high_threshold_pct, gap_mid_threshold_pct,
           raise_high_pct, raise_mid_pct, raise_low_pct,
           max_salary_vs_avg_pct
    FROM t1_variants 
    WHERE variant_id = &p_variant_id
),
dinfo AS (
    SELECT department_id,
           ROUND(AVG(salary), 2) AS dept_avg_salary,
           MAX(salary) AS dept_max_salary,
           COUNT(*) AS dept_employee_count
    FROM t1_employees
    WHERE department_id IS NOT NULL
    GROUP BY department_id
),
hreciente AS (
    SELECT DISTINCT jh.employee_id
    FROM t1_job_history jh
    CROSS JOIN Variante v
    WHERE jh.start_date >= ADD_MONTHS(SYSDATE, -v.recent_job_history_months)
),
elegibles AS (
    SELECT
        e.employee_id,
        e.department_id,
        e.salary AS salary_before,
        ds.dept_avg_salary,
        ROUND((ds.dept_avg_salary - e.salary) / ds.dept_avg_salary * 100, 2) AS pct_gap,
        CASE
            WHEN ROUND((ds.dept_avg_salary - e.salary)/ds.dept_avg_salary*100,2)
                 > v.gap_high_threshold_pct THEN v.raise_high_pct
            WHEN ROUND((ds.dept_avg_salary - e.salary)/ds.dept_avg_salary*100,2)
                 > v.gap_mid_threshold_pct  THEN v.raise_mid_pct
            ELSE v.raise_low_pct 
        END AS adjustment_pct,
        CASE
            WHEN ROUND((ds.dept_avg_salary - e.salary)/ds.dept_avg_salary*100,2)
                 > v.gap_high_threshold_pct THEN 'AJUSTE_ALTO'
            WHEN ROUND((ds.dept_avg_salary - e.salary)/ds.dept_avg_salary*100,2)
                 > v.gap_mid_threshold_pct  THEN 'AJUSTE_MEDIO'
            ELSE 'AJUSTE_BAJO' 
        END AS rule_applied,
        v.max_salary_vs_avg_pct
    FROM t1_employees e
    JOIN dinfo ds ON e.department_id = ds.department_id
    LEFT JOIN hreciente rh ON e.employee_id = rh.employee_id
    CROSS JOIN Variante v
    WHERE e.department_id != v.excluded_department_id
      AND ds.dept_employee_count >= 3
      AND MONTHS_BETWEEN(SYSDATE, e.hire_date) / 12 >= v.min_years_service
      AND rh.employee_id IS NULL
      AND e.salary < ds.dept_avg_salary
      AND e.job_id NOT IN ('AD_PRES', 'AD_VP')
      AND e.employee_id NOT IN (
            SELECT manager_id 
            FROM t1_departments 
            WHERE manager_id IS NOT NULL
      )
),
proyeccion AS (
    SELECT
        e.employee_id,
        e.department_id,
        e.salary_before,
        ROUND(
            LEAST(
                e.salary_before * (1 + e.adjustment_pct / 100),
                e.dept_avg_salary * e.max_salary_vs_avg_pct / 100
            ), 2
        ) AS salary_after,
        e.pct_gap,
        e.rule_applied
    FROM elegibles e
)
SELECT
    audit_salary_adj_t1_seq.NEXTVAL,
    '&p_execution_tag',
    &p_variant_id,
    employee_id,
    department_id,
    salary_before,
    salary_after,
    pct_gap,
    rule_applied,
    USER,
    SYSDATE,
    'Ajuste salarial'
FROM proyeccion;

-- 4.3 VALIDACIÓN INTERMEDIA
-- Debe mostrar, como mínimo, estas columnas:
--   employee_id
--   department_id
--   current_salary
--   original_salary
--   allowed_max_salary
--   validation_status
--
-- validation_status debe indicar si cumple o no cumple.

PROMPT ===== 4.3 VALIDACIÓN INTERMEDIA =====

-- ESCRIBA AQUÍ SU CONSULTA DE VALIDACIÓN INTERMEDIA

SELECT
    e.employee_id,
    e.department_id,
    e.salary  AS current_salary,
    a.salary_before  AS original_salary,
    ROUND(ds.dept_avg_salary * v.max_salary_vs_avg_pct / 100, 2) AS allowed_max_salary,
    CASE
        WHEN e.salary <= ROUND(ds.dept_avg_salary * v.max_salary_vs_avg_pct / 100, 2)
        THEN 'OK'
        ELSE 'EXCEDE_TOPE'
    END AS validation_status
FROM t1_employees e
JOIN audit_salary_adjustments_t1 a ON e.employee_id = a.employee_id
    AND a.execution_tag = '&p_execution_tag'
JOIN (SELECT department_id, ROUND(AVG(salary),2) AS dept_avg_salary  
      FROM t1_employees WHERE department_id IS NOT NULL
      GROUP BY department_id) ds ON e.department_id = ds.department_id
CROSS JOIN (SELECT max_salary_vs_avg_pct FROM t1_variants WHERE variant_id = &p_variant_id) v;

-- 4.4 CONTROL TRANSACCIONAL
-- Debe demostrar UNO de estos escenarios:
-- A. COMMIT si toda la validación es correcta
-- B. ROLLBACK TO SAVEPOINT si detecta incumplimientos
--
-- ESCRIBA AQUÍ SU DECISIÓN TRANSACCIONAL Y AGREGUE UN COMENTARIO

-- se hace COMMIT porque la validación intermedia solo devuelve
-- filas con status = 'OK'. El tope se aplicó con LEAST() en el cálculo,
-- así que es imposible que algún salario lo supere.
-- Si la consulta anterior hubiera devuelto 'EXCEDE_TOPE', se ejecutaría:
-- ROLLBACK TO SAVEPOINT sv_before_adjustment;


-- ============================================================
-- 5. VALIDACIÓN POSTERIOR
-- OBJETIVO:
-- Demostrar el resultado final de la transacción.
--
-- DEBE MOSTRAR, COMO MÍNIMO, ESTAS 4 SALIDAS:
--
-- SALIDA 1. Empleados impactados
-- Columnas mínimas:
--   employee_id, first_name, last_name, department_id,
--   salary_before, salary_after, execution_tag
--
-- SALIDA 2. Resumen económico final
-- Columnas mínimas:
--   total_rows_audited, total_salary_before, total_salary_after, total_increment
--
-- SALIDA 3. Validación de topes
-- Columnas mínimas:
--   employee_id, department_id, salary_after, allowed_max_salary, top_limit_status
--
-- SALIDA 4. Auditoría generada
-- Columnas mínimas:
--   audit_id, execution_tag, variant_id, employee_id, department_id,
--   salary_before, salary_after, rule_applied, executed_by, executed_at
--
-- IMPORTANTE:
-- Todas las validaciones posteriores deben filtrar por &p_execution_tag
-- ============================================================

PROMPT ===== 5. VALIDACIÓN POSTERIOR =====

-- SALIDA 1. EMPLEADOS IMPACTADOS

SELECT
    a.employee_id,
    e.first_name,
    e.last_name,
    a.department_id,
    a.salary_before,
    a.salary_after,
    a.execution_tag
FROM audit_salary_adjustments_t1 a
JOIN t1_employees e ON a.employee_id = e.employee_id
WHERE a.execution_tag = '&p_execution_tag'
ORDER BY a.department_id, a.employee_id;

-- SALIDA 2. RESUMEN ECONÓMICO FINAL

SELECT
    COUNT(*)                          AS total_rows_audited,
    SUM(salary_before)                AS total_salary_before,
    SUM(salary_after)                 AS total_salary_after,
    SUM(salary_after - salary_before) AS total_increment
FROM audit_salary_adjustments_t1
WHERE execution_tag = '&p_execution_tag';

-- SALIDA 3. VALIDACIÓN DE TOPES

SELECT
    a.employee_id,
    a.department_id,
    a.salary_after,
    ROUND(ds.dept_avg_salary * v.max_salary_vs_avg_pct / 100, 2) AS allowed_max_salary,
    CASE
        WHEN a.salary_after <= ROUND(ds.dept_avg_salary * v.max_salary_vs_avg_pct / 100, 2)
        THEN 'OK'
        ELSE 'EXCEDE_TOPE'
    END AS top_limit_status
FROM audit_salary_adjustments_t1 a
JOIN (SELECT department_id, ROUND(AVG(salary),2) dept_avg_salary
      FROM t1_employees WHERE department_id IS NOT NULL
      GROUP BY department_id) ds ON a.department_id = ds.department_id
CROSS JOIN (SELECT max_salary_vs_avg_pct FROM t1_variants WHERE variant_id = &p_variant_id) v
WHERE a.execution_tag = '&p_execution_tag'
ORDER BY a.department_id;

-- SALIDA 4. AUDITORÍA GENERADA

SELECT *
FROM audit_salary_adjustments_t1
WHERE execution_tag = '&p_execution_tag'
ORDER BY audit_id;

-- ============================================================
-- 6. JUSTIFICACIÓN TÉCNICA
-- Responder dentro del script, en comentarios.
-- Cada respuesta debe tener entre 3 y 6 líneas.
-- ============================================================

-- ATOMICIDAD:
-- Explique cómo su solución demuestra atomicidad.
--
-- RESPUESTA:

-- CONSISTENCIA:
-- Explique cómo su solución asegura que los datos quedan válidos
-- después de la operación.
--
-- RESPUESTA:

-- AISLAMIENTO:
-- Explique cómo se comportaría su transacción frente a otras sesiones.
--
-- RESPUESTA:

-- DURABILIDAD:
-- Explique qué garantiza la persistencia del cambio una vez confirmado.
--
-- RESPUESTA:

-- USO DE SAVEPOINT / ROLLBACK:
-- Explique qué riesgo controló y por qué ese punto de restauración
-- era necesario.
--
-- RESPUESTA:

PROMPT ===== Fin de plantilla =====
