SET SERVEROUTPUT ON SIZE UNLIMITED;

CREATE OR REPLACE TYPE t_liq_row AS OBJECT (
  id_empleado       NUMBER,
  id_quincena       VARCHAR2(15),
  salario_base_q    NUMBER,
  recargos          NUMBER,
  bonificacion      NUMBER,
  auxilio_transp    NUMBER,
  bono_sede         NUMBER,
  bruto             NUMBER,
  deduccion_salud   NUMBER,
  deduccion_pension NUMBER,
  fondo_solidaridad NUMBER,
  embargo           NUMBER,
  libranzas         NUMBER,
  aporte_voluntario NUMBER,
  total_deducciones NUMBER,
  neto              NUMBER
);
/

CREATE OR REPLACE TYPE t_liq_tab AS TABLE OF t_liq_row;
/

-- ============================================================
-- PUNTO 1 — Bloque anónimo: Liquidación individual
-- ============================================================
DECLARE

  v_id_empleado   EMPLEADOS.id_empleado%TYPE   := 1001; 
  v_nombre        EMPLEADOS.nombre%TYPE;
  v_tipo_contrato EMPLEADOS.tipo_contrato%TYPE;
  v_salario_base  EMPLEADOS.salario_base%TYPE;
  v_fecha_ingreso EMPLEADOS.fecha_ingreso%TYPE;
  v_cod_sede      EMPLEADOS.cod_sede%TYPE;
  v_acepta_vol    EMPLEADOS.acepta_aporte_vol%TYPE;

  v_ciudad        SEDES.ciudad%TYPE;

  c_quincena      CONSTANT VARCHAR2(15) := '2026-Q1-ENE';

  v_smlmv         PARAMETROS.valor_numerico%TYPE;
  v_pct_noct      PARAMETROS.valor_numerico%TYPE;
  v_pct_dom       PARAMETROS.valor_numerico%TYPE;
  v_pct_noct_dom  PARAMETROS.valor_numerico%TYPE;
  v_ret_serv      PARAMETROS.valor_numerico%TYPE;

  
  v_antiguedad    NUMBER;
  v_base_q        NUMBER(12,2) := 0;
  v_valor_hora    NUMBER(15,4) := 0;
  v_recargos      NUMBER(12,2) := 0;
  v_bonificacion  NUMBER(12,2) := 0;
  v_subtotal      NUMBER(12,2) := 0;
  v_num_sanciones NUMBER       := 0;

    CURSOR cur_horas(p_emp NUMBER, p_quin VARCHAR2) IS
    SELECT tipo_hora, cantidad_horas
    FROM   HORAS_TRABAJADAS
    WHERE  id_empleado = p_emp
      AND  id_quincena = p_quin;

BEGIN
  SELECT valor_numerico INTO v_smlmv        FROM PARAMETROS WHERE cod_parametro = 'SMLMV';
  SELECT valor_numerico INTO v_pct_noct     FROM PARAMETROS WHERE cod_parametro = 'RECARGO_NOCTURNO';
  SELECT valor_numerico INTO v_pct_dom      FROM PARAMETROS WHERE cod_parametro = 'RECARGO_DOMINICAL';
  SELECT valor_numerico INTO v_pct_noct_dom FROM PARAMETROS WHERE cod_parametro = 'RECARGO_NOCT_DOM';
  SELECT valor_numerico INTO v_ret_serv     FROM PARAMETROS WHERE cod_parametro = 'RET_SERVICIOS';


  SELECT e.id_empleado, e.nombre, e.tipo_contrato, e.salario_base,
         e.fecha_ingreso, e.cod_sede, e.acepta_aporte_vol,
         s.ciudad
  INTO   v_id_empleado, v_nombre, v_tipo_contrato, v_salario_base,
         v_fecha_ingreso, v_cod_sede, v_acepta_vol,
         v_ciudad
  FROM   EMPLEADOS e
  JOIN   SEDES     s ON s.cod_sede = e.cod_sede
  WHERE  e.id_empleado = v_id_empleado;


  v_antiguedad := TRUNC(MONTHS_BETWEEN(SYSDATE, v_fecha_ingreso) / 12);

  IF v_tipo_contrato = 'PLANTA' THEN
    v_base_q := v_salario_base / 2;
  ELSIF v_tipo_contrato = 'TEMPORAL' THEN
    SELECT NVL(SUM(CASE WHEN tipo_hora = 'NORMAL' THEN cantidad_horas ELSE 0 END), 0) * v_salario_base
    INTO   v_base_q
    FROM   HORAS_TRABAJADAS
    WHERE  id_empleado = v_id_empleado AND id_quincena = c_quincena;
  ELSIF v_tipo_contrato = 'SERVICIOS' THEN
    v_base_q := (v_salario_base - v_salario_base * v_ret_serv / 100) / 2;
  END IF;


  IF v_tipo_contrato <> 'SERVICIOS' THEN
    v_valor_hora := CASE v_tipo_contrato
                      WHEN 'PLANTA'   THEN v_salario_base / 240
                      WHEN 'TEMPORAL' THEN v_salario_base
                    END;
    FOR rec IN cur_horas(v_id_empleado, c_quincena) LOOP
      CASE rec.tipo_hora
        WHEN 'NOCTURNA'     THEN v_recargos := v_recargos + rec.cantidad_horas * v_valor_hora * v_pct_noct     / 100;
        WHEN 'DOMINICAL'    THEN v_recargos := v_recargos + rec.cantidad_horas * v_valor_hora * v_pct_dom      / 100;
        WHEN 'NOCTURNA_DOM' THEN v_recargos := v_recargos + rec.cantidad_horas * v_valor_hora * v_pct_noct_dom / 100;
        ELSE NULL;
      END CASE;
    END LOOP;
  END IF;

  IF v_tipo_contrato <> 'SERVICIOS' THEN

    SELECT COUNT(*) INTO v_num_sanciones
    FROM   SANCIONES
    WHERE  id_empleado  = v_id_empleado
      AND  fecha_sancion >= ADD_MONTHS(SYSDATE, -6);

    IF v_num_sanciones > 2 THEN
      v_bonificacion := 0; 
    ELSE
      v_bonificacion := v_base_q *
        CASE
          WHEN v_antiguedad BETWEEN 3 AND  5 THEN 0.03
          WHEN v_antiguedad BETWEEN 6 AND 10 THEN 0.06
          WHEN v_antiguedad > 10             THEN 0.10
          ELSE 0
        END;
    END IF;
  END IF;

  v_subtotal := v_base_q + v_recargos + v_bonificacion;


  DBMS_OUTPUT.PUT_LINE('=== LIQUIDACIÓN QUINCENAL ===');
  DBMS_OUTPUT.PUT_LINE('Empleado:       ' || v_nombre || ' (' || v_id_empleado || ')');
  DBMS_OUTPUT.PUT_LINE('Sede:           ' || v_ciudad);
  DBMS_OUTPUT.PUT_LINE('Tipo contrato:  ' || v_tipo_contrato);
  DBMS_OUTPUT.PUT_LINE('Antigüedad:     ' || v_antiguedad || ' años');
  DBMS_OUTPUT.PUT_LINE('-----------------------------');
  DBMS_OUTPUT.PUT_LINE('Salario base Q: ' || TO_CHAR(v_base_q,       'FM9,999,999,990.00'));
  DBMS_OUTPUT.PUT_LINE('Recargos:       ' || TO_CHAR(v_recargos,     'FM9,999,999,990.00'));
  DBMS_OUTPUT.PUT_LINE('Bonificación:   ' || TO_CHAR(v_bonificacion, 'FM9,999,999,990.00'));
  DBMS_OUTPUT.PUT_LINE('-----------------------------');
  DBMS_OUTPUT.PUT_LINE('SUBTOTAL:       ' || TO_CHAR(v_subtotal,     'FM9,999,999,990.00'));
  DBMS_OUTPUT.PUT_LINE('=============================');
END;
/

-- ============================================================
-- PUNTO 2 — Funciones standalone encadenadas
-- ============================================================

CREATE OR REPLACE FUNCTION fn_salario_base_q(
  p_id_empleado NUMBER,
  p_id_quincena VARCHAR2
) RETURN NUMBER IS
  v_tipo    EMPLEADOS.tipo_contrato%TYPE;
  v_sal     EMPLEADOS.salario_base%TYPE;
  v_ret     PARAMETROS.valor_numerico%TYPE;
  v_horas_n NUMBER;
BEGIN
  SELECT tipo_contrato, salario_base
  INTO   v_tipo, v_sal
  FROM   EMPLEADOS
  WHERE  id_empleado = p_id_empleado;

  IF v_tipo = 'PLANTA' THEN
    RETURN v_sal / 2;
  ELSIF v_tipo = 'TEMPORAL' THEN
    SELECT NVL(SUM(CASE WHEN tipo_hora = 'NORMAL' THEN cantidad_horas ELSE 0 END), 0)
    INTO   v_horas_n
    FROM   HORAS_TRABAJADAS
    WHERE  id_empleado = p_id_empleado AND id_quincena = p_id_quincena;
    RETURN v_sal * v_horas_n;
  ELSIF v_tipo = 'SERVICIOS' THEN
    SELECT valor_numerico INTO v_ret FROM PARAMETROS WHERE cod_parametro = 'RET_SERVICIOS';
    RETURN (v_sal - v_sal * v_ret / 100) / 2;
  END IF;
  RETURN 0;
END fn_salario_base_q;
/

CREATE OR REPLACE FUNCTION fn_recargos(
  p_id_empleado NUMBER,
  p_id_quincena VARCHAR2
) RETURN NUMBER IS
  v_tipo       EMPLEADOS.tipo_contrato%TYPE;
  v_sal        EMPLEADOS.salario_base%TYPE;
  v_valor_hora NUMBER;
  v_recargos   NUMBER := 0;
  v_pct_noct   PARAMETROS.valor_numerico%TYPE;
  v_pct_dom    PARAMETROS.valor_numerico%TYPE;
  v_pct_nd     PARAMETROS.valor_numerico%TYPE;

  -- Cursor con parámetro para recorrer horas del empleado
  CURSOR cur_horas(p_emp NUMBER, p_quin VARCHAR2) IS
    SELECT tipo_hora, cantidad_horas
    FROM   HORAS_TRABAJADAS
    WHERE  id_empleado = p_emp AND id_quincena = p_quin;
BEGIN
  SELECT tipo_contrato, salario_base INTO v_tipo, v_sal
  FROM   EMPLEADOS WHERE id_empleado = p_id_empleado;

  -- SERVICIOS nunca tiene recargos
  IF v_tipo = 'SERVICIOS' THEN RETURN 0; END IF;

  SELECT valor_numerico INTO v_pct_noct FROM PARAMETROS WHERE cod_parametro = 'RECARGO_NOCTURNO';
  SELECT valor_numerico INTO v_pct_dom  FROM PARAMETROS WHERE cod_parametro = 'RECARGO_DOMINICAL';
  SELECT valor_numerico INTO v_pct_nd   FROM PARAMETROS WHERE cod_parametro = 'RECARGO_NOCT_DOM';

  v_valor_hora := CASE v_tipo
                    WHEN 'PLANTA'   THEN v_sal / 240
                    WHEN 'TEMPORAL' THEN v_sal
                  END;

  FOR rec IN cur_horas(p_id_empleado, p_id_quincena) LOOP
    CASE rec.tipo_hora
      WHEN 'NOCTURNA'     THEN v_recargos := v_recargos + rec.cantidad_horas * v_valor_hora * v_pct_noct / 100;
      WHEN 'DOMINICAL'    THEN v_recargos := v_recargos + rec.cantidad_horas * v_valor_hora * v_pct_dom  / 100;
      WHEN 'NOCTURNA_DOM' THEN v_recargos := v_recargos + rec.cantidad_horas * v_valor_hora * v_pct_nd   / 100;
      ELSE NULL;
    END CASE;
  END LOOP;

  RETURN NVL(v_recargos, 0);
END fn_recargos;
/
CREATE OR REPLACE FUNCTION fn_bonificacion(
  p_id_empleado NUMBER,
  p_id_quincena VARCHAR2 DEFAULT '2026-Q1-ENE'
) RETURN NUMBER IS
  v_tipo          EMPLEADOS.tipo_contrato%TYPE;
  v_fecha_ingreso EMPLEADOS.fecha_ingreso%TYPE;
  v_antiguedad    NUMBER;
  v_base_q        NUMBER;
  v_num_sanciones NUMBER;
BEGIN
  SELECT tipo_contrato, fecha_ingreso INTO v_tipo, v_fecha_ingreso
  FROM   EMPLEADOS WHERE id_empleado = p_id_empleado;

  -- SERVICIOS nunca recibe bonificación
  IF v_tipo = 'SERVICIOS' THEN RETURN 0; END IF;

  v_antiguedad := TRUNC(MONTHS_BETWEEN(SYSDATE, v_fecha_ingreso) / 12);
  v_base_q     := fn_salario_base_q(p_id_empleado, p_id_quincena);

  -- Verificar sanciones últimos 6 meses
  SELECT COUNT(*) INTO v_num_sanciones
  FROM   SANCIONES
  WHERE  id_empleado  = p_id_empleado
    AND  fecha_sancion >= ADD_MONTHS(SYSDATE, -6);

  -- Más de 2 sanciones → pierde bonificación completa
  IF v_num_sanciones > 2 THEN RETURN 0; END IF;

  RETURN v_base_q *
    CASE
      WHEN v_antiguedad BETWEEN 3 AND  5 THEN 0.03
      WHEN v_antiguedad BETWEEN 6 AND 10 THEN 0.06
      WHEN v_antiguedad > 10             THEN 0.10
      ELSE 0
    END;
END fn_bonificacion;
/
CREATE OR REPLACE FUNCTION fn_bruto(
  p_id_empleado NUMBER,
  p_id_quincena VARCHAR2
) RETURN NUMBER IS
  v_tipo        EMPLEADOS.tipo_contrato%TYPE;
  v_sal         EMPLEADOS.salario_base%TYPE;
  v_cod_sede    EMPLEADOS.cod_sede%TYPE;
  v_acepta_vol  EMPLEADOS.acepta_aporte_vol%TYPE;
  v_base_q      NUMBER;
  v_recargos    NUMBER;
  v_bonif       NUMBER;
  v_aux_transp  NUMBER := 0;
  v_bono_sede   NUMBER := 0;
  v_smlmv       PARAMETROS.valor_numerico%TYPE;
  v_aux_valor   PARAMETROS.valor_numerico%TYPE;
  v_bono_clima  PARAMETROS.valor_numerico%TYPE;
  v_sal_mensual NUMBER;
  v_horas_n     NUMBER;
BEGIN
  SELECT tipo_contrato, salario_base, cod_sede, acepta_aporte_vol
  INTO   v_tipo, v_sal, v_cod_sede, v_acepta_vol
  FROM   EMPLEADOS WHERE id_empleado = p_id_empleado;

  v_base_q   := fn_salario_base_q(p_id_empleado, p_id_quincena);
  v_recargos := fn_recargos(p_id_empleado, p_id_quincena);
  v_bonif    := fn_bonificacion(p_id_empleado, p_id_quincena);

  -- Regla 4: Auxilio de transporte (solo PLANTA y TEMPORAL)
  IF v_tipo <> 'SERVICIOS' THEN
    SELECT valor_numerico INTO v_smlmv     FROM PARAMETROS WHERE cod_parametro = 'SMLMV';
    SELECT valor_numerico INTO v_aux_valor FROM PARAMETROS WHERE cod_parametro = 'AUX_TRANSPORTE';

    IF v_tipo = 'PLANTA' THEN
      v_sal_mensual := v_sal;
    ELSE
      SELECT NVL(SUM(CASE WHEN tipo_hora = 'NORMAL' THEN cantidad_horas ELSE 0 END), 0)
      INTO   v_horas_n
      FROM   HORAS_TRABAJADAS
      WHERE  id_empleado = p_id_empleado AND id_quincena = p_id_quincena;
      v_sal_mensual := v_sal * v_horas_n * 2;  -- equivalente mensual
    END IF;

    IF v_sal_mensual <= 2 * v_smlmv THEN
      v_aux_transp := v_aux_valor / 2;
    END IF;
  END IF;

  -- Regla 5: Bono por sede (solo PLANTA y TEMPORAL, solo SMA)
  IF v_tipo <> 'SERVICIOS' AND v_cod_sede = 'SMA' THEN
    SELECT valor_numerico INTO v_bono_clima FROM PARAMETROS WHERE cod_parametro = 'BONO_CLIMA_SMA';
    v_bono_sede := v_bono_clima;
  END IF;
  -- Nota: el aporte voluntario BOG es una DEDUCCIÓN, no entra en el bruto

  -- Regla 6: Bruto
  RETURN v_base_q + v_recargos + v_bonif + v_aux_transp + v_bono_sede;
END fn_bruto;
/
select fn_bruto(1001, '2026-Q1-ENE') from dual;
/
-- ============================================================
-- PUNTO 3 — Procedimiento con excepciones
-- ============================================================
CREATE OR REPLACE PROCEDURE sp_liquidar_empleado(
  p_id_empleado NUMBER,
  p_id_quincena VARCHAR2
) IS
  v_nombre        EMPLEADOS.nombre%TYPE;
  v_tipo          EMPLEADOS.tipo_contrato%TYPE;
  v_sal           EMPLEADOS.salario_base%TYPE;
  v_cod_sede      EMPLEADOS.cod_sede%TYPE;
  v_acepta_vol    EMPLEADOS.acepta_aporte_vol%TYPE;
  v_estado        EMPLEADOS.estado%TYPE;

  v_base_q        NUMBER(12,2);
  v_recargos      NUMBER(12,2);
  v_bonif         NUMBER(12,2);
  v_aux_transp    NUMBER(12,2) := 0;
  v_bono_sede     NUMBER(12,2) := 0;
  v_bruto         NUMBER(12,2);

  v_salud         NUMBER(12,2) := 0;
  v_pension       NUMBER(12,2) := 0;
  v_fondo_sol     NUMBER(12,2) := 0;
  v_embargo       NUMBER(12,2) := 0;
  v_libranzas     NUMBER(12,2) := 0;
  v_aporte_vol    NUMBER(12,2) := 0;
  v_total_ded     NUMBER(12,2);
  v_neto          NUMBER(12,2);

  v_smlmv         PARAMETROS.valor_numerico%TYPE;
  v_aux_valor     PARAMETROS.valor_numerico%TYPE;
  v_bono_clima    PARAMETROS.valor_numerico%TYPE;
  v_pct_salud     PARAMETROS.valor_numerico%TYPE;
  v_pct_pension   PARAMETROS.valor_numerico%TYPE;
  v_pct_fondo     PARAMETROS.valor_numerico%TYPE;
  v_umbral_fondo  PARAMETROS.valor_numerico%TYPE;
  v_aporte_bog    PARAMETROS.valor_numerico%TYPE;

  v_pct_embargo   NUMBER := 0;
  v_sal_mensual   NUMBER;
  v_horas_n       NUMBER;
  v_ya_existe     NUMBER;
BEGIN
  BEGIN
    SELECT nombre, tipo_contrato, salario_base, cod_sede, acepta_aporte_vol, estado
    INTO   v_nombre, v_tipo, v_sal, v_cod_sede, v_acepta_vol, v_estado
    FROM   EMPLEADOS WHERE id_empleado = p_id_empleado;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20001, 'Empleado no encontrado: ' || p_id_empleado);
  END;

  IF v_estado <> 'ACTIVO' THEN
    RAISE_APPLICATION_ERROR(-20002, 'Empleado no activo: estado = ' || v_estado);
  END IF;


  SELECT COUNT(*) INTO v_ya_existe
  FROM   LIQUIDACION
  WHERE  id_empleado = p_id_empleado AND id_quincena = p_id_quincena;

  IF v_ya_existe > 0 THEN
    RAISE_APPLICATION_ERROR(-20003,
      'Liquidación ya existe para empleado ' || p_id_empleado ||
      ' quincena ' || p_id_quincena);
  END IF;


  SELECT valor_numerico INTO v_smlmv        FROM PARAMETROS WHERE cod_parametro = 'SMLMV';
  SELECT valor_numerico INTO v_aux_valor    FROM PARAMETROS WHERE cod_parametro = 'AUX_TRANSPORTE';
  SELECT valor_numerico INTO v_pct_salud    FROM PARAMETROS WHERE cod_parametro = 'PCT_SALUD';
  SELECT valor_numerico INTO v_pct_pension  FROM PARAMETROS WHERE cod_parametro = 'PCT_PENSION';
  SELECT valor_numerico INTO v_pct_fondo    FROM PARAMETROS WHERE cod_parametro = 'PCT_FONDO_SOLIDARIDAD';
  SELECT valor_numerico INTO v_umbral_fondo FROM PARAMETROS WHERE cod_parametro = 'UMBRAL_FONDO_SMLMV';
  SELECT valor_numerico INTO v_aporte_bog   FROM PARAMETROS WHERE cod_parametro = 'APORTE_VOL_BOG';


  v_base_q   := fn_salario_base_q(p_id_empleado, p_id_quincena);
  v_recargos := fn_recargos(p_id_empleado, p_id_quincena);
  v_bonif    := fn_bonificacion(p_id_empleado, p_id_quincena);

  IF v_tipo <> 'SERVICIOS' THEN
    IF v_tipo = 'PLANTA' THEN
      v_sal_mensual := v_sal;
    ELSE
      SELECT NVL(SUM(CASE WHEN tipo_hora = 'NORMAL' THEN cantidad_horas ELSE 0 END), 0)
      INTO   v_horas_n
      FROM   HORAS_TRABAJADAS
      WHERE  id_empleado = p_id_empleado AND id_quincena = p_id_quincena;
      v_sal_mensual := v_sal * v_horas_n * 2;
    END IF;
    IF v_sal_mensual <= 2 * v_smlmv THEN
      v_aux_transp := v_aux_valor / 2;
    END IF;
  END IF;

  IF v_tipo <> 'SERVICIOS' AND v_cod_sede = 'SMA' THEN
    SELECT valor_numerico INTO v_bono_clima FROM PARAMETROS WHERE cod_parametro = 'BONO_CLIMA_SMA';
    v_bono_sede := v_bono_clima;
  END IF;


  v_bruto := v_base_q + v_recargos + v_bonif + v_aux_transp + v_bono_sede;

  v_salud   := ROUND(v_bruto * v_pct_salud   / 100, 2);
  v_pension := ROUND(v_bruto * v_pct_pension / 100, 2);

  IF v_bruto * 2 > v_umbral_fondo * v_smlmv THEN
    v_fondo_sol := ROUND(v_bruto * v_pct_fondo / 100, 2);
  END IF;

  SELECT NVL(SUM(porcentaje), 0) INTO v_pct_embargo
  FROM   EMBARGOS WHERE id_empleado = p_id_empleado AND estado = 'ACTIVO';
  v_embargo := ROUND((v_bruto - v_salud - v_pension - v_fondo_sol) * v_pct_embargo / 100, 2);

  SELECT NVL(SUM(cuota_mensual) / 2, 0) INTO v_libranzas
  FROM   LIBRANZAS WHERE id_empleado = p_id_empleado AND estado = 'ACTIVA';

  IF v_cod_sede = 'BOG' AND v_acepta_vol = 'S' THEN
    v_aporte_vol := v_aporte_bog;
  END IF;

  v_total_ded := v_salud + v_pension + v_fondo_sol + v_embargo + v_libranzas + v_aporte_vol;
  v_neto      := v_bruto - v_total_ded;

  IF v_neto < 0 THEN
    v_embargo   := 0;
    v_total_ded := v_salud + v_pension + v_fondo_sol + v_libranzas + v_aporte_vol;
    v_neto      := v_bruto - v_total_ded;
    IF v_neto < 0 THEN
      v_libranzas := 0;
      v_total_ded := v_salud + v_pension + v_fondo_sol + v_aporte_vol;
      v_neto      := v_bruto - v_total_ded;
    END IF;
  END IF;

  INSERT INTO LIQUIDACION (
    id_liquidacion, id_empleado, id_quincena,
    salario_base_q, recargos, bonificacion, auxilio_transp, bono_sede, bruto,
    deduccion_salud, deduccion_pension, fondo_solidaridad,
    embargo, libranzas, aporte_voluntario, total_deducciones, neto, fecha_liquidacion
  ) VALUES (
    SEQ_LIQUIDACION.NEXTVAL, p_id_empleado, p_id_quincena,
    v_base_q, v_recargos, v_bonif, v_aux_transp, v_bono_sede, v_bruto,
    v_salud, v_pension, v_fondo_sol,
    v_embargo, v_libranzas, v_aporte_vol, v_total_ded, v_neto, SYSDATE
  );

  COMMIT;
END sp_liquidar_empleado;
/

-- ============================================================
-- PUNTO 4 — Package PKG_NOMINA: Specification
-- ============================================================
CREATE OR REPLACE PACKAGE PKG_NOMINA AS

  gc_smlmv NUMBER;

  TYPE t_concepto_liq IS RECORD (
    id_empleado       LIQUIDACION.id_empleado%TYPE,
    id_quincena       LIQUIDACION.id_quincena%TYPE,
    salario_base_q    LIQUIDACION.salario_base_q%TYPE,
    recargos          LIQUIDACION.recargos%TYPE,
    bonificacion      LIQUIDACION.bonificacion%TYPE,
    auxilio_transp    LIQUIDACION.auxilio_transp%TYPE,
    bono_sede         LIQUIDACION.bono_sede%TYPE,
    bruto             LIQUIDACION.bruto%TYPE,
    deduccion_salud   LIQUIDACION.deduccion_salud%TYPE,
    deduccion_pension LIQUIDACION.deduccion_pension%TYPE,
    fondo_solidaridad LIQUIDACION.fondo_solidaridad%TYPE,
    embargo           LIQUIDACION.embargo%TYPE,
    libranzas         LIQUIDACION.libranzas%TYPE,
    aporte_voluntario LIQUIDACION.aporte_voluntario%TYPE,
    total_deducciones LIQUIDACION.total_deducciones%TYPE,
    neto              LIQUIDACION.neto%TYPE
  );


  TYPE t_lista_liq IS TABLE OF t_concepto_liq INDEX BY PLS_INTEGER;

 
  PROCEDURE sp_liquidar_quincena(p_id_empleado NUMBER, p_id_quincena VARCHAR2);

  PROCEDURE sp_liquidar_quincena(p_id_quincena VARCHAR2);

  FUNCTION fn_total_nomina_sede(p_cod_sede VARCHAR2, p_id_quincena VARCHAR2) RETURN NUMBER;

  FUNCTION fn_reporte_nomina(
    p_cod_sede      VARCHAR2 DEFAULT NULL,
    p_tipo_contrato VARCHAR2 DEFAULT NULL
  ) RETURN t_liq_tab PIPELINED;

END PKG_NOMINA;
/

CREATE OR REPLACE PACKAGE BODY PKG_NOMINA AS

  TYPE t_params IS RECORD (
    smlmv         NUMBER(15,2),
    aux_transp    NUMBER(15,2),
    pct_salud     NUMBER(5,2),
    pct_pension   NUMBER(5,2),
    pct_fondo     NUMBER(5,2),
    umbral_fondo  NUMBER(5,2),
    pct_noct      NUMBER(5,2),
    pct_dom       NUMBER(5,2),
    pct_noct_dom  NUMBER(5,2),
    ret_servicios NUMBER(5,2),
    bono_clima_sma NUMBER(12,2),
    aporte_vol_bog NUMBER(12,2)
  );
  gv_p t_params;

  TYPE t_ded_rec IS RECORD (
    salud      NUMBER(12,2) := 0,
    pension    NUMBER(12,2) := 0,
    fondo_sol  NUMBER(12,2) := 0,
    embargo    NUMBER(12,2) := 0,
    libranzas  NUMBER(12,2) := 0,
    aporte_vol NUMBER(12,2) := 0,
    total      NUMBER(12,2) := 0
  );

  PROCEDURE sp_log_nomina(
    p_operacion       VARCHAR2,
    p_detalle         VARCHAR2,
    p_empleados_ok    NUMBER DEFAULT 0,
    p_empleados_error NUMBER DEFAULT 0,
    p_monto_total     NUMBER DEFAULT 0
  ) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO LOG_NOMINA (
      id_log, fecha_hora, operacion, usuario, detalle,
      empleados_ok, empleados_error, monto_total
    ) VALUES (
      SEQ_LOG.NEXTVAL, SYSTIMESTAMP, p_operacion, USER, p_detalle,
      p_empleados_ok, p_empleados_error, p_monto_total
    );
    COMMIT; 
  END sp_log_nomina;

  FUNCTION fn_salario_base_q(p_id_empleado NUMBER, p_id_quincena VARCHAR2) RETURN NUMBER IS
    v_tipo  EMPLEADOS.tipo_contrato%TYPE;
    v_sal   EMPLEADOS.salario_base%TYPE;
    v_hn    NUMBER;
  BEGIN
    SELECT tipo_contrato, salario_base INTO v_tipo, v_sal
    FROM   EMPLEADOS WHERE id_empleado = p_id_empleado;

    IF    v_tipo = 'PLANTA'    THEN RETURN v_sal / 2;
    ELSIF v_tipo = 'SERVICIOS' THEN RETURN (v_sal - v_sal * gv_p.ret_servicios / 100) / 2;
    ELSE  -- TEMPORAL
      SELECT NVL(SUM(CASE WHEN tipo_hora = 'NORMAL' THEN cantidad_horas ELSE 0 END), 0)
      INTO   v_hn FROM HORAS_TRABAJADAS
      WHERE  id_empleado = p_id_empleado AND id_quincena = p_id_quincena;
      RETURN v_sal * v_hn;
    END IF;
  END fn_salario_base_q;

  FUNCTION fn_recargos(p_id_empleado NUMBER, p_id_quincena VARCHAR2) RETURN NUMBER IS
    v_tipo     EMPLEADOS.tipo_contrato%TYPE;
    v_sal      EMPLEADOS.salario_base%TYPE;
    v_vh       NUMBER;
    v_total    NUMBER := 0;
    CURSOR c(p_emp NUMBER, p_quin VARCHAR2) IS
      SELECT tipo_hora, cantidad_horas FROM HORAS_TRABAJADAS
      WHERE  id_empleado = p_emp AND id_quincena = p_quin;
  BEGIN
    SELECT tipo_contrato, salario_base INTO v_tipo, v_sal
    FROM   EMPLEADOS WHERE id_empleado = p_id_empleado;

    IF v_tipo = 'SERVICIOS' THEN RETURN 0; END IF;

    v_vh := CASE v_tipo WHEN 'PLANTA' THEN v_sal / 240 ELSE v_sal END;

    FOR r IN c(p_id_empleado, p_id_quincena) LOOP
      CASE r.tipo_hora
        WHEN 'NOCTURNA'     THEN v_total := v_total + r.cantidad_horas * v_vh * gv_p.pct_noct    / 100;
        WHEN 'DOMINICAL'    THEN v_total := v_total + r.cantidad_horas * v_vh * gv_p.pct_dom     / 100;
        WHEN 'NOCTURNA_DOM' THEN v_total := v_total + r.cantidad_horas * v_vh * gv_p.pct_noct_dom/ 100;
        ELSE NULL;
      END CASE;
    END LOOP;
    RETURN NVL(v_total, 0);
  END fn_recargos;

  FUNCTION fn_bonificacion(p_id_empleado NUMBER, p_id_quincena VARCHAR2) RETURN NUMBER IS
    v_tipo    EMPLEADOS.tipo_contrato%TYPE;
    v_fi      EMPLEADOS.fecha_ingreso%TYPE;
    v_anios   NUMBER;
    v_base_q  NUMBER;
    v_sanciones NUMBER;
  BEGIN
    SELECT tipo_contrato, fecha_ingreso INTO v_tipo, v_fi
    FROM   EMPLEADOS WHERE id_empleado = p_id_empleado;

    IF v_tipo = 'SERVICIOS' THEN RETURN 0; END IF;

    v_anios  := TRUNC(MONTHS_BETWEEN(SYSDATE, v_fi) / 12);
    v_base_q := fn_salario_base_q(p_id_empleado, p_id_quincena);

    SELECT COUNT(*) INTO v_sanciones FROM SANCIONES
    WHERE  id_empleado = p_id_empleado AND fecha_sancion >= ADD_MONTHS(SYSDATE, -6);

    IF v_sanciones > 2 THEN RETURN 0; END IF;

    RETURN v_base_q *
      CASE
        WHEN v_anios BETWEEN 3 AND  5 THEN 0.03
        WHEN v_anios BETWEEN 6 AND 10 THEN 0.06
        WHEN v_anios > 10             THEN 0.10
        ELSE 0
      END;
  END fn_bonificacion;

  FUNCTION fn_deducciones(
    p_bruto       NUMBER,
    p_id_empleado NUMBER,
    p_cod_sede    VARCHAR2,
    p_acepta_vol  VARCHAR2
  ) RETURN t_ded_rec IS
    v_d         t_ded_rec;
    v_pct_emb   NUMBER := 0;
  BEGIN
    v_d.salud   := ROUND(p_bruto * gv_p.pct_salud   / 100, 2);
    v_d.pension := ROUND(p_bruto * gv_p.pct_pension / 100, 2);

    IF p_bruto * 2 > gv_p.umbral_fondo * gv_p.smlmv THEN
      v_d.fondo_sol := ROUND(p_bruto * gv_p.pct_fondo / 100, 2);
    END IF;

    SELECT NVL(SUM(porcentaje), 0) INTO v_pct_emb
    FROM   EMBARGOS WHERE id_empleado = p_id_empleado AND estado = 'ACTIVO';
    v_d.embargo := ROUND((p_bruto - v_d.salud - v_d.pension - v_d.fondo_sol) * v_pct_emb / 100, 2);

    SELECT NVL(SUM(cuota_mensual) / 2, 0) INTO v_d.libranzas
    FROM   LIBRANZAS WHERE id_empleado = p_id_empleado AND estado = 'ACTIVA';

    IF p_cod_sede = 'BOG' AND p_acepta_vol = 'S' THEN
      v_d.aporte_vol := gv_p.aporte_vol_bog;
    END IF;

    v_d.total := v_d.salud + v_d.pension + v_d.fondo_sol +
                 v_d.embargo + v_d.libranzas + v_d.aporte_vol;
    RETURN v_d;
  END fn_deducciones;


  FUNCTION fn_calcular_liq(
    p_id_empleado NUMBER,
    p_id_quincena VARCHAR2
  ) RETURN t_concepto_liq IS
    v_emp   EMPLEADOS%ROWTYPE;
    v_rec   t_concepto_liq;
    v_ded   t_ded_rec;
    v_hn    NUMBER := 0;
    v_sm    NUMBER;
  BEGIN
    SELECT * INTO v_emp FROM EMPLEADOS WHERE id_empleado = p_id_empleado;

    v_rec.id_empleado := p_id_empleado;
    v_rec.id_quincena := p_id_quincena;

    v_rec.salario_base_q := fn_salario_base_q(p_id_empleado, p_id_quincena);
    v_rec.recargos       := fn_recargos(p_id_empleado, p_id_quincena);
    v_rec.bonificacion   := fn_bonificacion(p_id_empleado, p_id_quincena);

    v_rec.auxilio_transp := 0;
    IF v_emp.tipo_contrato <> 'SERVICIOS' THEN
      IF v_emp.tipo_contrato = 'PLANTA' THEN
        v_sm := v_emp.salario_base;
      ELSE
        SELECT NVL(SUM(CASE WHEN tipo_hora = 'NORMAL' THEN cantidad_horas ELSE 0 END), 0)
        INTO   v_hn FROM HORAS_TRABAJADAS
        WHERE  id_empleado = p_id_empleado AND id_quincena = p_id_quincena;
        v_sm := v_emp.salario_base * v_hn * 2;
      END IF;
      IF v_sm <= 2 * gv_p.smlmv THEN
        v_rec.auxilio_transp := gv_p.aux_transp / 2;
      END IF;
    END IF;


    v_rec.bono_sede := 0;
    IF v_emp.tipo_contrato <> 'SERVICIOS' AND v_emp.cod_sede = 'SMA' THEN
      v_rec.bono_sede := gv_p.bono_clima_sma;
    END IF;

    v_rec.bruto := v_rec.salario_base_q + v_rec.recargos + v_rec.bonificacion +
                   v_rec.auxilio_transp + v_rec.bono_sede;


    v_ded := fn_deducciones(v_rec.bruto, p_id_empleado, v_emp.cod_sede, v_emp.acepta_aporte_vol);

    v_rec.deduccion_salud    := v_ded.salud;
    v_rec.deduccion_pension  := v_ded.pension;
    v_rec.fondo_solidaridad  := v_ded.fondo_sol;
    v_rec.embargo            := v_ded.embargo;
    v_rec.libranzas          := v_ded.libranzas;
    v_rec.aporte_voluntario  := v_ded.aporte_vol;
    v_rec.total_deducciones  := v_ded.total;
    v_rec.neto               := v_rec.bruto - v_rec.total_deducciones;

    IF v_rec.neto < 0 THEN
      v_rec.embargo          := 0;
      v_rec.total_deducciones := v_rec.deduccion_salud + v_rec.deduccion_pension +
                                 v_rec.fondo_solidaridad + v_rec.libranzas + v_rec.aporte_voluntario;
      v_rec.neto := v_rec.bruto - v_rec.total_deducciones;
      IF v_rec.neto < 0 THEN
        v_rec.libranzas        := 0;
        v_rec.total_deducciones := v_rec.deduccion_salud + v_rec.deduccion_pension +
                                   v_rec.fondo_solidaridad + v_rec.aporte_voluntario;
        v_rec.neto := v_rec.bruto - v_rec.total_deducciones;
      END IF;
    END IF;

    RETURN v_rec;
  END fn_calcular_liq;


  PROCEDURE sp_liquidar_quincena(p_id_empleado NUMBER, p_id_quincena VARCHAR2) IS
    v_estado    EMPLEADOS.estado%TYPE;
    v_ya_existe NUMBER;
    v_rec       t_concepto_liq;
  BEGIN

    BEGIN
      SELECT estado INTO v_estado FROM EMPLEADOS WHERE id_empleado = p_id_empleado;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Empleado no encontrado: ' || p_id_empleado);
    END;


    IF v_estado <> 'ACTIVO' THEN
      RAISE_APPLICATION_ERROR(-20002, 'Empleado no activo: estado = ' || v_estado);
    END IF;

    SELECT COUNT(*) INTO v_ya_existe FROM LIQUIDACION
    WHERE  id_empleado = p_id_empleado AND id_quincena = p_id_quincena;
    IF v_ya_existe > 0 THEN
      RAISE_APPLICATION_ERROR(-20003,
        'Liquidación ya existe para empleado ' || p_id_empleado ||
        ' quincena ' || p_id_quincena);
    END IF;

    v_rec := fn_calcular_liq(p_id_empleado, p_id_quincena);

    INSERT INTO LIQUIDACION (
      id_liquidacion, id_empleado, id_quincena,
      salario_base_q, recargos, bonificacion, auxilio_transp, bono_sede, bruto,
      deduccion_salud, deduccion_pension, fondo_solidaridad,
      embargo, libranzas, aporte_voluntario, total_deducciones, neto
    ) VALUES (
      SEQ_LIQUIDACION.NEXTVAL, v_rec.id_empleado, v_rec.id_quincena,
      v_rec.salario_base_q, v_rec.recargos, v_rec.bonificacion,
      v_rec.auxilio_transp, v_rec.bono_sede, v_rec.bruto,
      v_rec.deduccion_salud, v_rec.deduccion_pension, v_rec.fondo_solidaridad,
      v_rec.embargo, v_rec.libranzas, v_rec.aporte_voluntario,
      v_rec.total_deducciones, v_rec.neto
    );

    sp_log_nomina('LIQUIDACION_INDIVIDUAL',
                  'Empleado ' || p_id_empleado || ' quincena ' || p_id_quincena,
                  1, 0, v_rec.neto);
    COMMIT;
  END sp_liquidar_quincena;

  -- ================================================================
  -- PUNTO 6 — sp_liquidar_quincena
  -- ================================================================
  PROCEDURE sp_liquidar_quincena(p_id_quincena VARCHAR2) IS
    TYPE t_ids IS TABLE OF EMPLEADOS.id_empleado%TYPE INDEX BY PLS_INTEGER;
    l_ids   t_ids;
    l_lista t_lista_liq;
    v_rec   t_concepto_liq;
    v_ok    NUMBER := 0;
    v_err   NUMBER := 0;
    v_monto NUMBER := 0;

    bulk_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT(bulk_errors, -24381);
  BEGIN
    SELECT e.id_empleado
    BULK COLLECT INTO l_ids
    FROM   EMPLEADOS e
    WHERE  e.estado = 'ACTIVO'
      AND  NOT EXISTS (
        SELECT 1 FROM LIQUIDACION l
        WHERE  l.id_empleado = e.id_empleado AND l.id_quincena = p_id_quincena
      );

    IF l_ids.COUNT = 0 THEN
      DBMS_OUTPUT.PUT_LINE('No hay empleados pendientes para ' || p_id_quincena);
      RETURN;
    END IF;

    FOR i IN 1..l_ids.COUNT LOOP
      BEGIN
        v_rec      := fn_calcular_liq(l_ids(i), p_id_quincena);
        l_lista(i) := v_rec;
      EXCEPTION
        WHEN OTHERS THEN
          v_err := v_err + 1;
          DBMS_OUTPUT.PUT_LINE('Error calculando emp ' || l_ids(i) || ': ' || SQLERRM);

      END;
    END LOOP;

    BEGIN
      FORALL i IN INDICES OF l_lista SAVE EXCEPTIONS
        INSERT INTO LIQUIDACION (
          id_liquidacion, id_empleado, id_quincena,
          salario_base_q, recargos, bonificacion, auxilio_transp, bono_sede, bruto,
          deduccion_salud, deduccion_pension, fondo_solidaridad,
          embargo, libranzas, aporte_voluntario, total_deducciones, neto
        ) VALUES (
          SEQ_LIQUIDACION.NEXTVAL,
          l_lista(i).id_empleado,   l_lista(i).id_quincena,
          l_lista(i).salario_base_q, l_lista(i).recargos, l_lista(i).bonificacion,
          l_lista(i).auxilio_transp, l_lista(i).bono_sede, l_lista(i).bruto,
          l_lista(i).deduccion_salud, l_lista(i).deduccion_pension, l_lista(i).fondo_solidaridad,
          l_lista(i).embargo, l_lista(i).libranzas, l_lista(i).aporte_voluntario,
          l_lista(i).total_deducciones, l_lista(i).neto
        );
      v_ok := SQL%ROWCOUNT;
    EXCEPTION
      WHEN bulk_errors THEN
        
        FOR j IN 1..SQL%BULK_EXCEPTIONS.COUNT LOOP
          v_err := v_err + 1;
          DBMS_OUTPUT.PUT_LINE('FORALL error índice ' || SQL%BULK_EXCEPTIONS(j).ERROR_INDEX ||
                               ': ' || SQLERRM(-SQL%BULK_EXCEPTIONS(j).ERROR_CODE));
        END LOOP;
        v_ok := l_lista.COUNT - SQL%BULK_EXCEPTIONS.COUNT;
    END;

    SELECT NVL(SUM(neto), 0) INTO v_monto FROM LIQUIDACION WHERE id_quincena = p_id_quincena;

    DBMS_OUTPUT.PUT_LINE('Procesados OK: ' || v_ok || ' | Errores: ' || v_err);

    sp_log_nomina('LIQUIDACION_MASIVA',
                  'Quincena ' || p_id_quincena || ' procesada',
                  v_ok, v_err, v_monto);
    COMMIT;
  END sp_liquidar_quincena;

  FUNCTION fn_total_nomina_sede(p_cod_sede VARCHAR2, p_id_quincena VARCHAR2) RETURN NUMBER IS
    v_total NUMBER := 0;
  BEGIN
    SELECT NVL(SUM(l.neto), 0)
    INTO   v_total
    FROM   LIQUIDACION l
    JOIN   EMPLEADOS   e ON e.id_empleado = l.id_empleado
    WHERE  e.cod_sede   = p_cod_sede
      AND  l.id_quincena = p_id_quincena;
    RETURN v_total;
  END fn_total_nomina_sede;

  -- ================================================================
  -- PUNTO 7 — fn_reporte_nomina: Pipelined + SQL Dinámico
  -- ================================================================
  FUNCTION fn_reporte_nomina(
    p_cod_sede      VARCHAR2 DEFAULT NULL,
    p_tipo_contrato VARCHAR2 DEFAULT NULL
  ) RETURN t_liq_tab PIPELINED IS
    TYPE t_rc IS REF CURSOR;
    v_cur   t_rc;
    v_sql   VARCHAR2(4000);

    v_emp   NUMBER; v_quin VARCHAR2(15);
    v_sbq   NUMBER; v_rec  NUMBER; v_bon  NUMBER;
    v_aux   NUMBER; v_bsede NUMBER; v_bruto NUMBER;
    v_sal   NUMBER; v_pen  NUMBER; v_fon  NUMBER;
    v_emb   NUMBER; v_lib  NUMBER; v_avol NUMBER;
    v_tded  NUMBER; v_neto NUMBER;
  BEGIN
    v_sql :=
      'SELECT l.id_empleado, l.id_quincena, ' ||
      '       l.salario_base_q, l.recargos, l.bonificacion, l.auxilio_transp, l.bono_sede, ' ||
      '       l.bruto, l.deduccion_salud, l.deduccion_pension, l.fondo_solidaridad, ' ||
      '       l.embargo, l.libranzas, l.aporte_voluntario, l.total_deducciones, l.neto ' ||
      'FROM LIQUIDACION l ' ||
      'JOIN EMPLEADOS   e ON e.id_empleado = l.id_empleado ' ||
      'WHERE 1=1';

    IF p_cod_sede IS NOT NULL THEN
      v_sql := v_sql || ' AND e.cod_sede = :sede';
    END IF;
    IF p_tipo_contrato IS NOT NULL THEN
      v_sql := v_sql || ' AND e.tipo_contrato = :tipo';
    END IF;

    IF    p_cod_sede IS NOT NULL AND p_tipo_contrato IS NOT NULL THEN
      OPEN v_cur FOR v_sql USING p_cod_sede, p_tipo_contrato;
    ELSIF p_cod_sede IS NOT NULL THEN
      OPEN v_cur FOR v_sql USING p_cod_sede;
    ELSIF p_tipo_contrato IS NOT NULL THEN
      OPEN v_cur FOR v_sql USING p_tipo_contrato;
    ELSE
      OPEN v_cur FOR v_sql;
    END IF;

    LOOP
      FETCH v_cur INTO
        v_emp, v_quin, v_sbq, v_rec, v_bon, v_aux, v_bsede,
        v_bruto, v_sal, v_pen, v_fon, v_emb, v_lib, v_avol, v_tded, v_neto;
      EXIT WHEN v_cur%NOTFOUND;
      PIPE ROW(t_liq_row(
        v_emp, v_quin, v_sbq, v_rec, v_bon, v_aux, v_bsede,
        v_bruto, v_sal, v_pen, v_fon, v_emb, v_lib, v_avol, v_tded, v_neto
      ));
    END LOOP;
    CLOSE v_cur;
    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      IF v_cur%ISOPEN THEN CLOSE v_cur; END IF;
      RAISE;
  END fn_reporte_nomina;

BEGIN
  SELECT valor_numerico INTO gv_p.smlmv         FROM PARAMETROS WHERE cod_parametro = 'SMLMV';
  SELECT valor_numerico INTO gv_p.aux_transp     FROM PARAMETROS WHERE cod_parametro = 'AUX_TRANSPORTE';
  SELECT valor_numerico INTO gv_p.pct_salud      FROM PARAMETROS WHERE cod_parametro = 'PCT_SALUD';
  SELECT valor_numerico INTO gv_p.pct_pension    FROM PARAMETROS WHERE cod_parametro = 'PCT_PENSION';
  SELECT valor_numerico INTO gv_p.pct_fondo      FROM PARAMETROS WHERE cod_parametro = 'PCT_FONDO_SOLIDARIDAD';
  SELECT valor_numerico INTO gv_p.umbral_fondo   FROM PARAMETROS WHERE cod_parametro = 'UMBRAL_FONDO_SMLMV';
  SELECT valor_numerico INTO gv_p.pct_noct       FROM PARAMETROS WHERE cod_parametro = 'RECARGO_NOCTURNO';
  SELECT valor_numerico INTO gv_p.pct_dom        FROM PARAMETROS WHERE cod_parametro = 'RECARGO_DOMINICAL';
  SELECT valor_numerico INTO gv_p.pct_noct_dom   FROM PARAMETROS WHERE cod_parametro = 'RECARGO_NOCT_DOM';
  SELECT valor_numerico INTO gv_p.ret_servicios  FROM PARAMETROS WHERE cod_parametro = 'RET_SERVICIOS';
  SELECT valor_numerico INTO gv_p.bono_clima_sma FROM PARAMETROS WHERE cod_parametro = 'BONO_CLIMA_SMA';
  SELECT valor_numerico INTO gv_p.aporte_vol_bog FROM PARAMETROS WHERE cod_parametro = 'APORTE_VOL_BOG';
  -- Inicializar la constante pública gc_smlmv
  gc_smlmv := gv_p.smlmv;
END PKG_NOMINA;
/

-- ============================================================
-- PUNTO 5 — Compound Trigger sobre LIQUIDACION
-- ============================================================
CREATE OR REPLACE TRIGGER trg_liquidacion_ins
FOR INSERT ON LIQUIDACION
COMPOUND TRIGGER

  lv_ajuste_embargo  BOOLEAN := FALSE;
  lv_ajuste_libranza BOOLEAN := FALSE;

  -- ----------------------------------------------------------------
  BEFORE EACH ROW IS
  BEGIN
    IF :NEW.salario_base_q < 0 THEN
      RAISE_APPLICATION_ERROR(-20010, 'Salario base no puede ser negativo');
    END IF;

    lv_ajuste_embargo  := FALSE;
    lv_ajuste_libranza := FALSE;

  
    IF :NEW.neto < 0 THEN
      :NEW.total_deducciones := :NEW.total_deducciones - :NEW.embargo;
      :NEW.embargo           := 0;
      :NEW.neto              := :NEW.bruto - :NEW.total_deducciones;
      lv_ajuste_embargo      := TRUE;

      IF :NEW.neto < 0 THEN
        :NEW.total_deducciones := :NEW.total_deducciones - :NEW.libranzas;
        :NEW.libranzas         := 0;
        :NEW.neto              := :NEW.bruto - :NEW.total_deducciones;
        lv_ajuste_libranza     := TRUE;
      END IF;
    END IF;
  END BEFORE EACH ROW;

  -- ----------------------------------------------------------------
  AFTER EACH ROW IS
  BEGIN

    IF lv_ajuste_embargo OR lv_ajuste_libranza THEN
      INSERT INTO LOG_NOMINA (id_log, fecha_hora, operacion, usuario, detalle, empleados_ok)
      VALUES (
        SEQ_LOG.NEXTVAL, SYSTIMESTAMP, 'ALERTA_NETO_NEGATIVO', USER,
        'Emp ' || :NEW.id_empleado ||
        ' — embargo ajustado: ' || :NEW.embargo ||
        ', libranzas ajustadas: ' || :NEW.libranzas ||
        ', neto final: ' || :NEW.neto,
        1
      );
    END IF;

   
    IF :NEW.libranzas > 0 THEN
      UPDATE LIBRANZAS
      SET    saldo_pendiente = saldo_pendiente - cuota_mensual / 2
      WHERE  id_empleado = :NEW.id_empleado AND estado = 'ACTIVA';

      UPDATE LIBRANZAS
      SET    estado = 'PAGADA'
      WHERE  id_empleado = :NEW.id_empleado
        AND  estado      = 'ACTIVA'
        AND  saldo_pendiente <= 0;
    END IF;
  END AFTER EACH ROW;

  -- ----------------------------------------------------------------
  AFTER STATEMENT IS
  BEGIN
    -- Log del lote completo
    INSERT INTO LOG_NOMINA (id_log, fecha_hora, operacion, usuario, detalle)
    VALUES (
      SEQ_LOG.NEXTVAL, SYSTIMESTAMP, 'INSERT_LIQUIDACION', USER,
      'Lote procesado a las ' || TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS.FF3')
    );
  END AFTER STATEMENT;

END trg_liquidacion_ins;
/

BEGIN
 
  PKG_NOMINA.sp_liquidar_quincena('2026-Q1-ENE');
END;
/

SELECT
  e.id_empleado,
  e.nombre,
  e.tipo_contrato,
  e.cod_sede,
  l.salario_base_q,
  l.recargos,
  l.bonificacion,
  l.auxilio_transp,
  l.bono_sede,
  l.bruto,
  l.deduccion_salud,
  l.deduccion_pension,
  l.fondo_solidaridad,
  l.embargo,
  l.libranzas,
  l.aporte_voluntario,
  l.total_deducciones,
  l.neto
FROM LIQUIDACION l
JOIN EMPLEADOS   e ON e.id_empleado = l.id_empleado
WHERE l.id_quincena = '2026-Q1-ENE'
ORDER BY l.id_empleado;

SELECT * FROM LOG_NOMINA ORDER BY fecha_hora;

SELECT
  s.cod_sede,
  s.nombre_sede,
  PKG_NOMINA.fn_total_nomina_sede(s.cod_sede, '2026-Q1-ENE') AS total_neto
FROM SEDES s
ORDER BY s.cod_sede;
