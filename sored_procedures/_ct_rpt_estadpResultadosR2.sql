USE db_comercial_final
GO
ALTER PROCEDURE [dbo].[_ct_rpt_estadpResultadosR2]
	@ejercicio AS INT = NULL
	,@periodo1 AS INT = NULL
	,@periodo2 AS INT = NULL
	,@idsucursal AS INT = 0
	,@detallado AS BIT = 0
	,@opcion AS TINYINT = 0
AS

SET NOCOUNT ON

DECLARE
	@ventas_periodo AS DECIMAL(18, 6)
	,@ventas_final AS DECIMAL(18, 6)

SELECT @ejercicio = ISNULL(@ejercicio, YEAR(GETDATE()))
SELECT @periodo1 = ISNULL(@periodo1, MONTH(GETDATE()))
SELECT @periodo2 = ISNULL(@periodo2, MONTH(GETDATE()))

CREATE TABLE #_tmp_estado_resultados_formato (
	id INT IDENTITY
	,cuenta VARCHAR(20)
	,nombre VARCHAR(500) NOT NULL DEFAULT ''
	,objlevel INT NOT NULL DEFAULT 0
	,afectable BIT NOT NULL DEFAULT 0
	,saldo_periodo DECIMAL(18,6) NOT NULL DEFAULT 0
	,saldo_final DECIMAL(18,6) NOT NULL DEFAULT 0

	,CONSTRAINT [PK_tmp_estado_resultados_formato] PRIMARY KEY CLUSTERED (
		[cuenta]
	)
) ON [PRIMARY]

INSERT INTO #_tmp_estado_resultados_formato (
	cuenta
	,nombre
	,objlevel
	,afectable
)
SELECT
	cc.cuenta
	,[nombre] = REPLICATE('. ', cc.nivel - 4) + '' + cc.nombre
	,[objlevel] = cc.nivel - 4
	,afectable
FROM
	ew_ct_cuentas AS cc
WHERE
	cc.tipo = 4
	AND cc.nivel > 3
	AND cc.nivel < (CASE WHEN @detallado = 0 THEN 6 ELSE 999 END)
ORDER BY cc.llave

INSERT INTO #_tmp_estado_resultados_formato (
	cuenta
	,nombre
	,objlevel
	,afectable
)
SELECT
	cc.cuenta
	,[nombre] = REPLICATE('. ', cc.nivel - 4) + '' + cc.nombre
	,[objlevel] = cc.nivel - 4
	,afectable
FROM
	ew_ct_cuentas AS cc
WHERE
	cc.tipo = 5
	AND cc.nivel > 3
	AND cc.nivel < (CASE WHEN @detallado = 0 THEN 6 ELSE 999 END)
ORDER BY cc.llave

INSERT INTO #_tmp_estado_resultados_formato (
	cuenta
	,nombre
	,objlevel
	,afectable
)
SELECT
	cc.cuenta
	,[nombre] = cc.nombre
	,[objlevel] = 0
	,afectable
FROM
	ew_ct_cuentas AS cc
WHERE
	cc.cuenta = '_UTILIDAD'
ORDER BY cc.llave

UPDATE erf SET
	erf.saldo_periodo = ISNULL((
		SELECT
			SUM(CASE WHEN cc.naturaleza = 0 THEN csg.cargos - csg.abonos ELSE csg.abonos - csg.cargos END)
		FROM
			ew_ct_saldosGlobales AS csg
			LEFT JOIN ew_ct_cuentas AS cc
				ON cc.cuenta = csg.cuenta
		WHERE
			csg.cuenta = erf.cuenta
			AND csg.ejercicio = @ejercicio
			AND csg.periodo BETWEEN @periodo1 AND @periodo2
			AND csg.idsucursal = @idsucursal
	), 0)
	,erf.saldo_final = ISNULL((
		SELECT
			csg.saldo_final
		FROM
			ew_ct_saldosGlobales AS csg
			LEFT JOIN ew_ct_cuentas AS cc
				ON cc.cuenta = csg.cuenta
		WHERE
			csg.cuenta = erf.cuenta
			AND csg.ejercicio = @ejercicio
			AND csg.periodo = @periodo2
			AND csg.idsucursal = @idsucursal
	), 0)
FROM
	#_tmp_estado_resultados_formato AS erf
	
SELECT @ventas_periodo = (SELECT erft.saldo_periodo FROM #_tmp_estado_resultados_formato AS erft WHERE erft.id = 2)
SELECT @ventas_final = (SELECT erft.saldo_final FROM #_tmp_estado_resultados_formato AS erft WHERE erft.id = 2)

SELECT @ventas_periodo = ISNULL(@ventas_periodo, 0)
SELECT @ventaS_final = ISNULL(@ventas_final, 0)

SELECT
	[cuenta] = erf.cuenta
	,[nombre] = erf.nombre
	,[saldo_periodo] = erf.saldo_periodo
	,[porc_periodo] = (
		erf.saldo_periodo
		/ (
			CASE
				WHEN @ventas_periodo = 0 THEN 1
				ELSE @ventas_periodo
			END
		)
	)
	,[saldo_final] = erf.saldo_final
	,[porc_final] = (
		erf.saldo_final
		/ (
			CASE
				WHEN @ventas_final = 0 THEN 1
				ELSE @ventas_final
			END
		)
	)
	,[objlevel] = erf.objlevel
FROM 
	#_tmp_estado_resultados_formato AS erf
WHERE
	ABS(erf.saldo_periodo) > (CASE WHEN @opcion = 0 THEN 0 ELSE -1 END)
	
ORDER BY erf.id

DROP TABLE #_tmp_estado_resultados_formato
GO
