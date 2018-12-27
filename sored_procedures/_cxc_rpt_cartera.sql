USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20100504
-- Description:	Auxiliar de cartera
-- =============================================
ALTER PROCEDURE [dbo].[_cxc_rpt_cartera]
	@codcliente AS VARCHAR(30) = ''
	, @idmoneda AS SMALLINT = -1
	, @fecha1 AS SMALLDATETIME = NULL
	, @fecha2 AS SMALLDATETIME = NULL
AS

SET NOCOUNT ON

DECLARE
	@ejercicio AS SMALLINT = NULL
	, @periodo AS SMALLINT = NULL

SELECT @fecha1 = CONVERT(VARCHAR(8), ISNULL(@fecha1, DATEADD(MONTH, -1, GETDATE())), 3) + ' 00:00'
SELECT @fecha2 = CONVERT(VARCHAR(8), ISNULL(@fecha2, GETDATE()), 3) + ' 23:59'

SELECT @ejercicio = YEAR(@fecha1)
SELECT @periodo = MONTH(@fecha1)

CREATE TABLE #_tmp_cartera (
	idr INT IDENTITY
	, moneda VARCHAR(100) NOT NULL DEFAULT ''
	, idcliente INT
	, codigo VARCHAR(30)
	, nombre VARCHAR(1000)
	, saldo_inicial DECIMAL(18,6) NOT NULL DEFAULT 0
	, cargos DECIMAL(18,6) NOT NULL DEFAULT 0
	, abonos DECIMAL(18,6) NOT NULL DEFAULT 0
	, saldo_final DECIMAL(18,6) NOT NULL DEFAULT 0

	, CONSTRAINT [PK__tmp_cartera] PRIMARY KEY CLUSTERED (
		moneda ASC
		, idcliente ASC
	) ON [PRIMARY]
) ON [PRIMARY]

INSERT INTO #_tmp_cartera (
	moneda
	, idcliente
	, codigo
	, nombre
	, saldo_inicial
	, cargos
	, abonos
	, saldo_final
)

SELECT
	[moneda] = bm.codigo
	, [idcliente] = ct.idcliente
	, [codigo] = c.codigo
	, [nombre] = c.nombre
	, [saldo_inicial] = 0
	, [cargos] = SUM(CASE WHEN ct.tipo = 1 THEN ct.total ELSE 0 END)
	, [abonos] = SUM(CASE WHEN ct.tipo = 2 THEN ct.total ELSE 0 END)
	, [saldo_final] = 0
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_ban_monedas AS bm
		ON bm.idmoneda = ct.idmoneda
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = ct.idcliente
WHERE
	ct.cancelado = 0
	AND ct.tipo IN (1,2)
	AND CONVERT(SMALLDATETIME, (CONVERT(VARCHAR(8), ct.fecha, 3) + ' 00:00')) BETWEEN @fecha1 AND @fecha2
GROUP BY
	bm.codigo
	, ct.idcliente
	, c.codigo
	, c.nombre

UPDATE tc SET
	tc.saldo_inicial = ISNULL(si.saldo_inicial, 0)
FROM
	#_tmp_cartera AS tc
	LEFT JOIN (
		SELECT 
			csg.idcliente
			, csg.saldo_inicial
		FROM 
			ew_cxc_saldosGlobales AS csg
			LEFT JOIN ew_clientes AS c
				ON c.idcliente = csg.idcliente
		WHERE
			csg.moneda_sistema = 0
			AND ABS(csg.saldo_inicial) > 0
			AND c.codigo = (CASE @codcliente WHEN '' THEN c.codigo ELSE @codcliente END)
			AND csg.idmoneda = (CASE @idmoneda WHEN -1 THEN csg.idmoneda ELSE @idmoneda END)
			AND csg.ejercicio = @ejercicio
			AND csg.periodo = @periodo
	) AS si
		ON si.idcliente = tc.idcliente

INSERT INTO #_tmp_cartera (
	moneda
	, idcliente
	, codigo
	, nombre
	, saldo_inicial
)

SELECT 
	[moneda] = (bm.nombre + ' (' + bm.codigo + ')')
	, [idcliente] = csg.idcliente
	, [codigo] = c.codigo
	, [nombre] = c.nombre
	, [saldo_inicial] = csg.saldo_inicial
FROM 
	ew_cxc_saldosGlobales AS csg
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = csg.idcliente
	LEFT JOIN ew_ban_monedas AS bm
		ON bm.idmoneda = csg.idmoneda
WHERE
	csg.moneda_sistema = 0
	AND ABS(csg.saldo_inicial) > 0
	AND c.codigo = (CASE @codcliente WHEN '' THEN c.codigo ELSE @codcliente END)
	AND csg.idmoneda = (CASE @idmoneda WHEN -1 THEN csg.idmoneda ELSE @idmoneda END)
	AND csg.ejercicio = @ejercicio
	AND csg.periodo = @periodo
	AND csg.idcliente NOT IN (SELECT tc.idcliente FROM #_tmp_cartera AS tc)

UPDATE tc SET
	tc.saldo_inicial = (
		tc.saldo_inicial
		+ ISNULL((
			SELECT
				SUM(CASE WHEN ct.tipo = 1 THEN ct.total ELSE ct.total * -1 END)
			FROM
				ew_cxc_transacciones AS ct
			WHERE
				ct.cancelado = 0
				AND ct.tipo IN (1,2)
				AND ct.idcliente = tc.idcliente
				AND ct.fecha BETWEEN CONVERT(SMALLDATETIME, '1/' + LTRIM(RTRIM(STR(MONTH(@fecha1)))) + '/' + LTRIM(RTRIM(STR(YEAR(@fecha1)))) + ' 00:00') AND DATEADD(DAY, -1, @fecha1)
		), 0)
	)
FROM
	#_tmp_cartera AS tc

UPDATE tc SET
	tc.saldo_final = (
		tc.saldo_inicial
		+ tc.cargos
		- tc.abonos
	)
FROM
	#_tmp_cartera AS tc

SELECT
	tc.*
	, [titulo] = ro.nombre
	, [titulo_subtitulo] = UPPER(
		'DEL '
		+ LTRIM(RTRIM(STR(DAY(@fecha1))))
		+ ' DE '
		+ (SELECT spd.descripcion FROM ew_sys_periodos_datos AS spd WHERE spd.grupo = 'meses' AND spd.id = MONTH(@fecha1))
		+ '-'
		+ LTRIM(RTRIM(STR(YEAR(@fecha1))))
		+ ' AL '
		+ LTRIM(RTRIM(STR(DAY(@fecha2))))
		+ ' DE '
		+ (SELECT spd.descripcion FROM ew_sys_periodos_datos AS spd WHERE spd.grupo = 'meses' AND spd.id = MONTH(@fecha2))
		+ '-'
		+ LTRIM(RTRIM(STR(YEAR(@fecha2))))
	)
	, [titulo_fecha] = 'Fecha: ' + CONVERT(VARCHAR(8), GETDATE(), 3)
	, [titulo_ruta] = [dbo].[_sys_fnc_objetoRuta](ro.objeto)
FROM 
	#_tmp_cartera AS tc
	LEFT JOIN objetos AS ro
		ON ro.tipo = 'AUX'
		AND ro.codigo = 'AUX93'
WHERE
	tc.cargos > 0 
	OR tc.abonos > 0
ORDER BY
	tc.nombre

DROP TABLE #_tmp_cartera
GO
