USE db_comercial_final
GO
IF OBJECT_ID('_cxc_rpt_estadoCuenta') IS NOT NULL
BEGIN
	DROP PROCEDURE _cxc_rpt_estadoCuenta
END
GO
-- =============================================
-- Author:		Fernanda Corona
-- Create date: 20191108
-- Description:	Estado de Cuenta del cliente
-- =============================================
CREATE PROCEDURE [dbo].[_cxc_rpt_estadoCuenta]
	@idsucursal AS SMALLINT = 0
	, @codcliente AS VARCHAR(30) = ''
	, @fecha1 AS VARCHAR (50) = NULL
	, @fecha2 AS VARCHAR (50)= NULL
	, @idmoneda AS INT = -1
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- VALIDAR DATOS ###############################################################

DECLARE 
	@dia SMALLINT

SELECT @dia = DAY(@fecha1) - 1

SELECT 
	@fecha1 = CONVERT(
		SMALLDATETIME
		, CONVERT(
			VARCHAR(10)
			,ISNULL(@fecha1, GETDATE()), 103
		) + ' 00:00'
	)

SELECT 
	@fecha2 = CONVERT(
		SMALLDATETIME
		, CONVERT(
			VARCHAR(10)
			,ISNULL(@fecha2, GETDATE()), 103
		) + ' 23:59'
	)

--------------------------------------------------------------------------------
-- CREAR REGISTRO TEMPORAL #####################################################

CREATE TABLE #_cxc_edocta (
	idr BIGINT IDENTITY
	, codigo VARCHAR (50)
	, cliente VARCHAR(300) NOT NULL DEFAULT ''
	, moneda VARCHAR(100) NOT NULL DEFAULT ''
	, idsucur SMALLINT
	, sucursal VARCHAR(200) NOT NULL DEFAULT ''
	, fecha SMALLDATETIME NOT NULL
	, folio VARCHAR(40) NOT NULL DEFAULT ''
	, idcliente SMALLINT NOT NULL DEFAULT 1
	, movimiento VARCHAR(200) NOT NULL DEFAULT ''
	, idmoneda TINYINT NOT NULL DEFAULT ''
	, saldo_inicial DECIMAL(18,6) NOT NULL DEFAULT 0
	, importemovimiento DECIMAL(18,6) NOT NULL DEFAULT 0
	, tipocambio DECIMAL(18,6) NOT NULL DEFAULT 0
	, cargos DECIMAL(18,6) NOT NULL DEFAULT 0
	, abonos DECIMAL(18,6) NOT NULL DEFAULT 0
	, saldo_final DECIMAL(18,6) NOT NULL DEFAULT 0
	, idtran BIGINT NOT NULL DEFAULT 0
)

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

INSERT INTO #_cxc_edocta (
	codigo
	, cliente
	, moneda
	, idsucur
	, sucursal
	, fecha
	, folio
	, idcliente
	, movimiento
	, idmoneda
	, importemovimiento
	, tipocambio
	, cargos
	, abonos
	, idtran
)
SELECT
	[codigo]   = c.codigo
	, [cliente] = c.nombre +' '+  c.nombre_corto 
	, [moneda] = bm.nombre
	, [idsucur] = ISNULL(ct.idsucursal,'')
	, [sucursal] = ISNULL(s.nombre,'')
	, [fecha] = CONVERT(DATE, ISNULL(ct.fecha, @fecha1), 103)
	, [folio] = (
		ISNULL(ct.folio, '')
		+ ISNULL((
			'('
			+ (
				SELECT TOP 1
					efa4.folio
				FROM
					ew_cxc_transacciones_rel AS ctrl
					LEFT JOIN ew_cxc_transacciones AS efa4
						ON efa4.idtran = ctrl.idtran
				WHERE
					ctrl.idtran2 = ct.idtran
					AND efa4.transaccion = 'EFA4'
			)
			+ ')'
		), '')
	)
	, [idcliente] = c.idcliente
	, [movimiento] = ISNULL(t.nombre, '-Sin Movimientos-')
	, [idmoneda] = bm.idmoneda
	, [importemovimiento] = ISNULL(ct.total,0)
	, [tipocambio] = ISNULL(ct.tipocambio,1)
	, [cargos] = ISNULL((CASE WHEN ct.tipo = 1 THEN (ct.total * ct.tipocambio) ELSE 0 END), 0)
	, [abonos] = ISNULL((CASE WHEN ct.tipo = 2 THEN (ct.total * ct.tipocambio) ELSE 0 END), 0)
	, [idtran] = ISNULL(ct.idtran, 0)
FROM 
	ew_clientes AS c
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idcliente = c.idcliente
		AND ct.cancelado = 0
		AND ct.tipo IN (1,2)
		AND ct.aplicado = 1
		AND ct.acumula = 1
		AND ct.fecha BETWEEN @fecha1 AND @fecha2
	LEFT JOIN ew_ban_monedas AS bm
		ON ct.idmoneda = bm.idmoneda
	LEFT JOIN sucursales AS s 
		ON s.idsucursal = ct.idsucursal
	LEFT JOIN objetos AS t 
		ON t.codigo = ct.transaccion
WHERE 
	(
		(
			SELECT
				csg.saldo_inicial
			FROM
				ew_cxc_saldosGlobales AS csg
			WHERE
				csg.idcliente = c.idcliente
				AND csg.idmoneda = bm.idmoneda
				AND csg.moneda_sistema = 0
				AND csg.ejercicio = YEAR(@fecha1)
				AND csg.periodo = MONTH(@fecha1)
		) <> 0
		OR ct.total IS NOT NULL
	)
	AND c.codigo = (CASE WHEN @codcliente IN('Todos','') THEN c.codigo ELSE @codcliente END)
	AND ct.idmoneda = (CASE WHEN @idmoneda=-1 THEN ct.idmoneda ELSE @idmoneda END)
ORDER BY 
	ct.idsucursal
	,c.codigo
	,c.nombre
	,ct.fecha

--------------------------------------------------------------------------------
-- CALCULAR SALDOS EL PERIODO ##################################################

UPDATE ce SET
	ce.saldo_inicial = ISNULL((
		SELECT
			csg.saldo_inicial
		FROM
			ew_cxc_saldosGlobales AS csg
		WHERE
			csg.idcliente = ce.idcliente
			AND csg.idmoneda = ce.idmoneda
			AND csg.moneda_sistema = 0
			AND csg.ejercicio = YEAR(@fecha1)
			AND csg.periodo = MONTH(@fecha1)
	), 0)
FROM
	#_cxc_edocta AS ce
WHERE
	ce.idr = (
		SELECT
			MIN(ce0.idr)
		FROM
			#_cxc_edocta AS ce0
		WHERE
			ce0.idcliente = ce.idcliente
			AND ce0.idmoneda = ce.idmoneda
	)
	
IF DAY(@fecha1) <> 1
BEGIN
	UPDATE ce SET
		ce.saldo_inicial = (
			ce.saldo_inicial
			+ISNULL((
				SELECT
					SUM(CASE ct.tipo WHEN 1 THEN ct.total ELSE (ct.total * -1) END)
				FROM
					ew_cxc_transacciones AS ct
				WHERE
					ct.tipo IN(1,2)
					AND ct.cancelado = 0
					AND ct.idcliente = ce.idcliente
					AND ct.idmoneda = ce.idmoneda
					AND ct.fecha BETWEEN 
						'01/' + CONVERT(VARCHAR(2), MONTH(@fecha1)) + '/' + CONVERT(VARCHAR(4), YEAR(@fecha1)) + ' 00:00'
						AND CONVERT(VARCHAR(2),@dia)+'/' + CONVERT(VARCHAR(2), MONTH(@fecha1)) + '/' + CONVERT(VARCHAR(4), YEAR(@fecha1)) + ' 00:00' --CONVERT(VARCHAR(8), @fecha1, 3) + ' 00:00'
			), 0)
		)
	FROM
		#_cxc_edocta AS ce
	WHERE
		ce.idr = (
			SELECT
				MIN(ce0.idr)
			FROM
				#_cxc_edocta AS ce0
			WHERE
				ce0.idcliente = ce.idcliente
				AND ce0.idmoneda = ce.idmoneda
		)
END

UPDATE ce SET
	ce.saldo_final = (
		ce.saldo_inicial
		+ (
			SELECT
				SUM(ce1.cargos)
			FROM
				#_cxc_edocta AS ce1
			WHERE
				ce1.idcliente = ce.idcliente
				AND ce1.idmoneda = ce.idmoneda
		)
		- (
			SELECT
				SUM(ce2.abonos)
			FROM
				#_cxc_edocta AS ce2
			WHERE
				ce2.idcliente = ce.idcliente
				AND ce2.idmoneda = ce.idmoneda
		)
	)
FROM
	#_cxc_edocta AS ce
WHERE
	ce.idr = (
		SELECT
			MIN(ce0.idr)
		FROM
			#_cxc_edocta AS ce0
		WHERE
			ce0.idcliente = ce.idcliente
	)

--------------------------------------------------------------------------------
-- MOSTRAR DATOS ###############################################################

SELECT
	ted.idr
	, ted.idsucur
	, [sucursal] = ted.sucursal +' (' + ted.moneda + ')'
	, ted.codigo
	, ted.cliente
	, ted.moneda
	, ted.fecha
	, ted.folio
	, ted.idcliente
	, ted.movimiento
	, ted.idmoneda
	, ted.saldo_inicial
	, ted.importemovimiento
	, ted.tipocambio
	, ted.cargos
	, ted.abonos
	, ted.saldo_final
	, ted.idtran

	, [tractor] = (
		SELECT 
			mt.mm_nombre
		FROM 
			ew_ven_transacciones AS d
			LEFT JOIN mm_cat_vehiculos AS mt 
				ON mt.mm_idvehiculo = d.mm_idvehiculo
		WHERE 
			d.idtran = ted.idtran
	)
	, [remolque] = (
		SELECT 
			mr.mm_nombre
		FROM 
			ew_ven_transacciones AS d
			LEFT JOIN mm_cat_vehiculos AS mr 
				ON mr.mm_idvehiculo = d.mm_idvehiculo_remolque1
		WHERE 
			d.idtran = ted.idtran
	)
	, [comentario] = CONVERT(VARCHAR(8000), t.comentario)
FROM
	#_cxc_edocta AS ted
	LEFT JOIN ew_cxc_transacciones AS t 
		ON t.idtran = ted.idtran
WHERE 
	ted.idsucur = (CASE @idsucursal WHEN 0 THEN ted.idsucur ELSE @idsucursal END)
ORDER BY 
	ted.idsucur
	, ted.moneda
	, ted.cliente
	, ted.fecha
	, ted.folio

DROP TABLE #_cxc_edocta
GO
