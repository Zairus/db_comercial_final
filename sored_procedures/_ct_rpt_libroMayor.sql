USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091003
-- Description:	Libro de Mayor
-- =============================================
ALTER PROCEDURE [dbo].[_ct_rpt_libroMayor]
	@cuenta1 AS VARCHAR(20)
	,@cuenta2 AS VARCHAR(20)
	,@f1 VARCHAR(8)
	,@f2 VARCHAR(8)
	,@origen AS SMALLINT
AS

SET NOCOUNT ON
SET DATEFORMAT DMY

--------------------------------------------------------------------------------
-- DECLARACION DE VARIABLES ####################################################

DECLARE
	@cuenta AS VARCHAR(20)
	,@cuenta_superior AS VARCHAR(20)
	,@saldo_inicial AS DECIMAL(15,2)
	,@cargos AS DECIMAL(15,2)
	,@abonos AS DECIMAL(15,2)
	,@saldo_final AS DECIMAL(15,2)
	,@fecha1 SMALLDATETIME
	,@fecha2 SMALLDATETIME

DECLARE
	@ejercicio1 AS SMALLINT
	,@periodo1 AS TINYINT
	,@dia1 AS TINYINT
	,@ejercicio2 AS SMALLINT
	,@periodo2 AS TINYINT
	,@dia2 AS TINYINT

--------------------------------------------------------------------------------
-- INICIALIZAR VARIABLES #######################################################
SELECT @fecha1 = CONVERT(SMALLDATETIME, @f1, 3) + ' 00:00'
SELECT @fecha2 = CONVERT(SMALLDATETIME, @f2, 3) + ' 23:59'

SELECT @dia1 = DAY(@fecha1)
SELECT @periodo1 = MONTH(@fecha1)
SELECT @ejercicio1 = YEAR(@fecha1)

SELECT @dia2 = DAY(@fecha2)
SELECT @periodo2 = MONTH(@fecha2)
SELECT @ejercicio2 = YEAR(@fecha2)

IF @cuenta2 = ''
BEGIN
	SELECT 
		@cuenta2 = MAX(cuenta) 
	FROM 
		ew_ct_cuentas
END

IF @cuenta2 < @cuenta1
BEGIn
	RAISERROR('Error: La cuenta final debe ser posterior a la cuenta inicial.', 16, 1)
	RETURN
END

IF @fecha2 < @fecha1
BEGIN
	RAISERROR('Error: No se puede solicitar un periodo cuya fecha final es menor a la fecha inicial.', 16, 1)
	RETURN
END

--------------------------------------------------------------------------------
-- CREAR REGISTROS TEMPORALES ##################################################
IF OBJECT_ID('tempdb..##_tmp_ct_libroMayor') IS NOT NULL
BEGIN
	DROP TABLE ##_tmp_ct_libroMayor
END

IF OBJECT_ID('tempdb..##_tmp_ct_libroSaldosIniciales') IS NOT NULL
BEGIN
	DROP TABLE ##_tmp_ct_libroSaldosIniciales
END

CREATE TABLE ##_tmp_ct_libroMayor (
	idr BIGINT IDENTITY
	,objlevel SMALLINT
	,cuenta VARCHAR(20)
	,nombre VARCHAR(200)
	,afectable BIT
	,naturaleza TINYINT
	,fecha SMALLDATETIME
	,tipo VARCHAR(50)
	,folio VARCHAR(15)
	,referencia VARCHAR(200)
	,saldo_inicial DECIMAL(15,2)
	,cargos DECIMAL(15,2)
	,abonos DECIMAL(15,2)
	,saldo_final DECIMAL(15,2)
	,concepto VARCHAR(4000)
	,idtran BIGINT
)

CREATE TABLE ##_tmp_ct_libroSaldosIniciales (
	cuenta VARCHAR(20)
	,saldo_inicial DECIMAL(15,2)
	,saldo_final DECIMAL(15,2)
)

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

INSERT INTO ##_tmp_ct_libroMayor (
	objlevel
	, cuenta
	, nombre
	, afectable
	, naturaleza
	, fecha
	, tipo
	, folio
	, referencia
	, saldo_inicial
	, cargos
	, abonos
	, saldo_final
	, concepto
	, idtran
)
SELECT
	[objlevel] = cc.nivel
	,cc.cuenta
	,cc.nombre
	,cc.afectable
	,cc.naturaleza
	,mov.fecha
	,[tipo] = ISNULL(ctt.nombre, '')
	,[folio] = ISNULL(mov.folio, '')
	,[referencia] = ISNULL(mov.referencia, '')
	,[saldo_inicial] = 0
	,[cargos] = ISNULL(mov.cargos, 0)
	,[abonos] = ISNULL(mov.abonos, 0)
	,[saldo_final] = 0
	,[concepto] = ISNULL(mov.concepto, '')
	,mov.idtran
FROM 
	ew_ct_cuentas AS cc
	LEFT JOIN (
		SELECT
			pol.fecha
			,pol.idtipo
			,pol.folio
			,pm.cuenta
			,pm.consecutivo
			,pm.referencia
			,pm.cargos
			,pm.abonos
			,pm.concepto
			,pm.idtran
		FROM 
			ew_ct_poliza_mov AS pm
			LEFT JOIN ew_ct_poliza AS pol 
				ON pol.idtran = pm.idtran
		WHERE
			pol.fecha BETWEEN @fecha1 AND @fecha2
			AND pol.origen = (CASE @origen WHEN -1 THEN pol.origen ELSE @origen END)
	) AS mov
		ON mov.cuenta = cc.cuenta
	LEFT JOIN ew_ct_tipos AS ctt
		ON ctt.idtipo = mov.idtipo
WHERE
	cc.cuenta BETWEEN @cuenta1 AND @cuenta2
ORDER BY
	cc.llave
	,mov.fecha
	,mov.consecutivo

--------------------------------------------------------------------------------
-- OBTENER SALDOS INICIALES ####################################################
INSERT INTO ##_tmp_ct_libroSaldosIniciales (
	cuenta
	, saldo_inicial
	, saldo_final
)
SELECT DISTINCT
	tcl.cuenta
	,[saldo_inicial] = (
		csg1.saldo_inicial
		+ ISNULL((
			CASE @dia1
				WHEN 1 THEN 0
				ELSE (
					SELECT
						CASE tcl.naturaleza
							WHEN 0 THEN SUM(pm.cargos - pm.abonos)
							WHEN 1 THEN SUM(pm.abonos - pm.cargos)
						END
					FROM 
						ew_ct_poliza_mov AS pm
						LEFT JOIN ew_ct_poliza AS pol
							ON pol.idtran = pm.idtran
					WHERE
						pm.cuenta = tcl.cuenta
						AND pol.fecha BETWEEN 
							'01/' + CONVERT(VARCHAR(2), @periodo1) + '/' + CONVERT(VARCHAR(4), @ejercicio1) + ' 00:00' 
							AND CONVERT(VARCHAR(2), (@dia1 - 1)) + '/' + CONVERT(VARCHAR(2), @periodo1) + '/' + CONVERT(VARCHAR(4), @ejercicio1) + ' 23:59'
				)
			END
		), 0)
	)
	,[saldo_final] = (
		csg2.saldo_inicial
		+ ISNULL((
			CASE @dia2
				WHEN 1 THEN 0
				ELSE (
					SELECT
						CASE tcl.naturaleza
							WHEN 0 THEN SUM(pm.cargos - pm.abonos)
							WHEN 1 THEN SUM(pm.abonos - pm.cargos)
						END
					FROM 
						ew_ct_poliza_mov AS pm
						LEFT JOIN ew_ct_poliza AS pol
							ON pol.idtran = pm.idtran
					WHERE
						pm.cuenta = tcl.cuenta
						AND pol.fecha BETWEEN 
							'01/' + CONVERT(VARCHAR(2), @periodo2) + '/' + CONVERT(VARCHAR(4), @ejercicio2) + ' 00:00' 
							AND CONVERT(VARCHAR(2), @dia2) + '/' + CONVERT(VARCHAR(2), @periodo2) + '/' + CONVERT(VARCHAR(4), @ejercicio2) + ' 23:59'
				)
			END
		), 0)
	)
FROM 
	##_tmp_ct_libroMayor AS tcl
	LEFT JOIN ew_ct_saldosGlobales AS csg1
		ON csg1.cuenta = tcl.cuenta
		AND csg1.idsucursal = 0
		AND csg1.ejercicio = @ejercicio1
		AND csg1.periodo = @periodo1
	LEFT JOIN ew_ct_saldosGlobales AS csg2
		ON csg2.cuenta = tcl.cuenta
		AND csg2.idsucursal = 0
		AND csg2.ejercicio = @ejercicio2
		AND csg2.periodo = @periodo2
WHERE
	tcl.afectable = 1
ORDER BY
	tcl.cuenta

UPDATE tcl SET
	tcl.saldo_inicial = tcls.saldo_inicial
	,tcl.saldo_final = tcls.saldo_final
FROM 
	##_tmp_ct_libroSaldosIniciales AS tcls
	LEFT JOIN ##_tmp_ct_libroMayor AS tcl
		ON tcl.cuenta = tcls.cuenta
		AND tcl.idr = (
			SELECT
				MIN(tcl_idr.idr)
			FROM ##_tmp_ct_libroMayor AS tcl_idr
			WHERE
				tcl_idr.cuenta = tcls.cuenta
		)

--------------------------------------------------------------------------------
-- ACUMULAR SALDOS EN CUENTAS SUPERIORES #######################################

DECLARE cur_movimientos CURSOR FOR
	SELECT
		tcl.cuenta
		,[saldo_inicial] = SUM(tcl.saldo_inicial)
		,[cargos] = SUM(tcl.cargos)
		,[abonos] = SUM(tcl.abonos)
		,[saldo_final] = SUM(tcl.saldo_final)
	FROM 
		##_tmp_ct_libroMayor AS tcl
	WHERE
		tcl.afectable = 1
	GROUP BY
		tcl.cuenta

OPEN cur_movimientos

FETCH NEXT FROM cur_movimientos INTO
	@cuenta
	, @saldo_inicial
	, @cargos
	, @abonos
	, @saldo_final

WHILE @@FETCH_STATUS = 0
BEGIN
	DECLARE cur_arbol CURSOR FOR
		SELECT
			cfa.cuenta
		FROM dbo._ct_fnc_arbol(@cuenta) AS cfa
		WHERE
			cfa.cuenta <> @cuenta
	
	OPEN cur_arbol
	
	FETCH NEXT FROM cur_arbol INTO
		@cuenta_superior
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE ##_tmp_ct_libroMayor SET
			saldo_inicial = (saldo_inicial + @saldo_inicial)
			,cargos = (cargos + @cargos)
			,abonos = (abonos + @abonos)
			,saldo_final = (saldo_final + @saldo_final)
		WHERE
			cuenta = @cuenta_superior
		
		FETCH NEXT FROM cur_arbol INTO
			@cuenta_superior
	END
	
	CLOSE cur_arbol
	DEALLOCATE cur_arbol
	
	FETCH NEXT FROM cur_movimientos INTO
		@cuenta
		, @saldo_inicial
		, @cargos
		, @abonos
		, @saldo_final
END

CLOSE cur_movimientos
DEALLOCATE cur_movimientos

--------------------------------------------------------------------------------
-- PRESENTAR DATOS #############################################################
SELECT
	[descripcion] = tcl.nombre + ' (' + tcl.cuenta + ')'
	,tcl.cuenta
	,tcl.nombre
	,tcl.fecha
	,tcl.tipo
	,tcl.folio
	,tcl.referencia
	,tcl.saldo_inicial
	,tcl.cargos
	,tcl.abonos
	,tcl.saldo_final
	,tcl.concepto
	,tcl.idtran
FROM 
	##_tmp_ct_libroMayor AS tcl

--------------------------------------------------------------------------------
-- LIMPIAR REGISTROS TEMPORALES ################################################

DROP TABLE ##_tmp_ct_libroMayor
GO
