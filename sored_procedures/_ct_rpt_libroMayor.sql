USE db_comercial_final
GO
IF OBJECT_ID('_ct_rpt_libroMayor') IS NOT NULL
BEGIN
	DROP PROCEDURE _ct_rpt_libroMayor
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091003
-- Description:	Libro de Mayor
-- =============================================
CREATE PROCEDURE [dbo].[_ct_rpt_libroMayor]
	@cuenta1 AS VARCHAR(20) = ''
	, @cuenta2 AS VARCHAR(20) = ''
	, @fecha1 DATETIME = NULL
	, @fecha2 DATETIME = NULL
	, @origen AS SMALLINT = -1
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACION DE VARIABLES ####################################################

DECLARE
	@cuenta AS VARCHAR(20)
	, @cuenta_superior AS VARCHAR(20)
	, @saldo_inicial AS DECIMAL(15,2)
	, @cargos AS DECIMAL(15,2)
	, @abonos AS DECIMAL(15,2)
	, @saldo_final AS DECIMAL(15,2)

DECLARE
	@ejercicio1 AS SMALLINT
	, @periodo1 AS TINYINT
	, @dia1 AS TINYINT
	, @ejercicio2 AS SMALLINT
	, @periodo2 AS TINYINT
	, @dia2 AS TINYINT

--------------------------------------------------------------------------------
-- INICIALIZAR VARIABLES #######################################################
SELECT @fecha1 = CONVERT(DATETIME, CONVERT(VARCHAR(10), ISNULL(@fecha1, DATEADD(MONTH, -1, GETDATE())), 103) + ' 00:00')
SELECT @fecha2 = CONVERT(DATETIME, CONVERT(VARCHAR(10), ISNULL(@fecha2, GETDATE()), 103) + ' 23:59')

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
IF OBJECT_ID('tempdb..#_tmp_ct_libroMayor') IS NOT NULL
BEGIN
	DROP TABLE #_tmp_ct_libroMayor
END

IF OBJECT_ID('tempdb..#_tmp_ct_libroSaldosIniciales') IS NOT NULL
BEGIN
	DROP TABLE #_tmp_ct_libroSaldosIniciales
END

CREATE TABLE #_tmp_ct_libroMayor (
	idr INT IDENTITY
	, objlevel SMALLINT
	, cuenta VARCHAR(20)
	, nombre VARCHAR(200)
	, afectable BIT
	, naturaleza TINYINT
	, fecha SMALLDATETIME
	, tipo VARCHAR(50)
	, folio VARCHAR(15)
	, referencia VARCHAR(200)
	, saldo_inicial DECIMAL(15,2)
	, cargos DECIMAL(15,2)
	, abonos DECIMAL(15,2)
	, saldo_final DECIMAL(15,2)
	, concepto VARCHAR(4000)
	, idtran INT

	, poliza_idr INT
	, cp_cuenta VARCHAR(20)
	, cp_nombre VARCHAR(200)
	, cp_importe VARCHAR(200)
	, cp_movimiento VARCHAR(500)
	, cp_folio VARCHAR(20)
) ON [PRIMARY]

CREATE TABLE #_tmp_ct_libroSaldosIniciales (
	cuenta VARCHAR(20)
	, saldo_inicial DECIMAL(15,2)
	, saldo_final DECIMAL(15,2)
) ON [PRIMARY]

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

INSERT INTO #_tmp_ct_libroMayor (
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
	, poliza_idr
)
SELECT
	[objlevel] = cc.nivel
	, [cuenta ] = cc.cuenta
	, [nombre] = cc.nombre
	, [afectable] = cc.afectable
	, [naturaleza] = cc.naturaleza
	, [fecha] = mov.fecha
	, [tipo] = ISNULL(ctt.nombre, '')
	, [folio] = ISNULL(mov.folio, '')
	, [referencia] = ISNULL(mov.referencia, '')
	, [saldo_inicial] = 0
	, [cargos] = ISNULL(mov.cargos, 0)
	, [abonos] = ISNULL(mov.abonos, 0)
	, [saldo_final] = 0
	, [concepto] = ISNULL(mov.concepto, '')
	, [idtran] = mov.idtran
	, [poliza_idr] = mov.idr
FROM 
	ew_ct_cuentas AS cc
	LEFT JOIN (
		SELECT
			pol.fecha
			, pol.idtipo
			, pol.folio
			, pm.cuenta
			, pm.consecutivo
			, pm.referencia
			, pm.cargos
			, pm.abonos
			, [concepto] = (
				ISNULL(ste.entidad, '')
				+ ' - '
				+ pm.concepto
			)
			, pm.idtran
			, pm.idr
		FROM 
			ew_ct_poliza_mov AS pm
			LEFT JOIN ew_ct_poliza AS pol 
				ON pol.idtran = pm.idtran
			LEFT JOIN [dbo].[ew_sys_transaccionesEntidades] AS ste
				ON ste.idtran = pm.idtran2
		WHERE
			pol.fecha BETWEEN @fecha1 AND @fecha2
			AND pol.origen = ISNULL(NULLIF(@origen, -1), pol.origen)
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

INSERT INTO #_tmp_ct_libroSaldosIniciales (
	cuenta
	, saldo_inicial
	, saldo_final
)
SELECT DISTINCT
	[cuenta] = tcl.cuenta
	, [saldo_inicial] = (
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
	, [saldo_final] = (
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
	#_tmp_ct_libroMayor AS tcl
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
	#_tmp_ct_libroSaldosIniciales AS tcls
	LEFT JOIN #_tmp_ct_libroMayor AS tcl
		ON tcl.cuenta = tcls.cuenta
		AND tcl.idr = (
			SELECT
				MIN(tcl_idr.idr)
			FROM #_tmp_ct_libroMayor AS tcl_idr
			WHERE
				tcl_idr.cuenta = tcls.cuenta
		)

--------------------------------------------------------------------------------
-- ACUMULAR SALDOS EN CUENTAS SUPERIORES #######################################

DECLARE cur_movimientos CURSOR FOR
	SELECT
		[cuenta] = tcl.cuenta
		, [saldo_inicial] = SUM(tcl.saldo_inicial)
		, [cargos] = SUM(tcl.cargos)
		, [abonos] = SUM(tcl.abonos)
		, [saldo_final] = SUM(tcl.saldo_final)
	FROM 
		#_tmp_ct_libroMayor AS tcl
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
		UPDATE #_tmp_ct_libroMayor SET
			saldo_inicial = (saldo_inicial + @saldo_inicial)
			, cargos = (cargos + @cargos)
			, abonos = (abonos + @abonos)
			, saldo_final = (saldo_final + @saldo_final)
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
-- AGREGAR DATOS DE AUDITORIA ##################################################

UPDATE tcl SET
	tcl.cp_cuenta = ISNULL(pm2.cuenta, '')
	, tcl.cp_nombre = ISNULL(cc.nombre, '')
	, tcl.cp_importe = ISNULL(IIF(tcl.cargos <> 0, pm2.abonos, pm2.cargos), 0)
	, tcl.cp_movimiento = ISNULL(o.nombre + ' [' + st.transaccion + ']', '')
	, tcl.cp_folio = ISNULL(st.folio, '')
FROM
	#_tmp_ct_libroMayor AS tcl
	LEFT JOIN ew_ct_poliza_mov AS pm1
		ON pm1.idr = tcl.poliza_idr
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = pm1.idtran2
	LEFT JOIN objetos AS o
		ON o.codigo = st.transaccion
	LEFT JOIN ew_ct_poliza_mov AS pm2
		ON pm2.idr = (
			SELECT TOP 1
				pcp.idr
			FROM
				ew_ct_poliza_mov AS pcp
			WHERE
				pcp.idtran = pm1.idtran
				AND pcp.cuenta <> pm1.cuenta
			ORDER BY
				ABS ((tcl.cargos - tcl.abonos) - (pcp.abonos - pcp.cargos)) ASC
		)
	LEFT JOIN ew_ct_cuentas AS cc
		ON cc.cuenta = pm2.cuenta

--------------------------------------------------------------------------------
-- PRESENTAR DATOS #############################################################

SELECT
	[descripcion] = tcl.nombre + ' (' + tcl.cuenta + ')'
	, [cuenta] = tcl.cuenta
	, [nombre] = tcl.nombre
	, [fecha] = tcl.fecha
	, [tipo] = tcl.tipo
	, [folio] = tcl.folio
	, [referencia] = tcl.referencia
	, [saldo_inicial] = tcl.saldo_inicial
	, [cargos] = tcl.cargos
	, [abonos] = tcl.abonos
	, [saldo_final] = tcl.saldo_final
	, [conceptos] = tcl.concepto
	, [idtran] = tcl.idtran

	--, [poliza_idr] = tcl.poliza_idr
	, [cp_cuenta] = tcl.cp_cuenta
	, [cp_nombre] = tcl.cp_nombre
	, [cp_importe] = tcl.cp_importe
	, [cp_movimiento] = tcl.cp_movimiento
	, [cp_folio] = tcl.cp_folio
FROM 
	#_tmp_ct_libroMayor AS tcl

--------------------------------------------------------------------------------
-- LIMPIAR REGISTROS TEMPORALES ################################################

DROP TABLE #_tmp_ct_libroMayor
GO
