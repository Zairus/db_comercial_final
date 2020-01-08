USE db_comercial_final
GO
IF OBJECT_ID('_ct_rpt_balanceGeneral') IS NOT NULL
BEGIN
	DROP PROCEDURE _ct_rpt_balanceGeneral
END
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 20080501
-- Description:	Balance General
-- =============================================
CREATE PROCEDURE [dbo].[_ct_rpt_balanceGeneral]
	@ejercicio AS SMALLINT = NULL
	, @per1 AS SMALLINT = NULL
	, @idsucursal AS SMALLINT = 0
	, @ceros AS INT = 0
	, @detallado AS INT = 0
AS

SET NOCOUNT ON

DECLARE 
	@per2 AS TINYINT
	, @per0 AS TINYINT
	, @p1 AS VARCHAR(20)
	, @p0 AS VARCHAR(20)
	, @sql AS VARCHAR(8000)
	, @sucursal AS VARCHAR(50)
	, @cont AS SMALLINT

DECLARE 
	@ceros2 AS VARCHAR(1000)
	, @d AS VARCHAR(100)

CREATE TABLE ##tmp_balance (
	idr SMALLINT IDENTITY
	, columna TINYINT
	, grupo TINYINT
	, renglon SMALLINT
	, llave VARCHAR(100)
	, cuenta VARCHAR(20)
	, nombre VARCHAR(100)
	, saldo DECIMAL(15,2)
)

SELECT @sql = ''
SELECT @ejercicio = ISNULL(@ejercicio, YEAR(GETDATE()))
SELECT @per1 = ISNULL(@per1, MONTH(GETDATE()))

IF @per1 < 1
BEGIN
	SELECT @per1 = 1
END

SELECT @sucursal = 'idsucursal = ' + CONVERT(VARCHAR(2),@idsucursal)

IF @idsucursal = -1
BEGIN
	SELECT @sucursal = 'idsucursal > (-1)'
END

SELECT @p1 = 'periodo' + RTRIM(CONVERT(VARCHAR(2), @per1))
SELECT @p0 = 'periodo' + RTRIM(CONVERT(VARCHAR(2), @per1 - 1))

SELECT 
	@ceros2 = (CASE WHEN @ceros='1' THEN '' ELSE '
AND [dbo].[fn_ct_cuentaSaldo](a.cuenta, @ejercicio, @per, @idsucursal) <> 0' END )

SELECT @d = 'AND a.ctamayor <> 2'

IF @detallado = 1
BEGIN
	SELECT @d = '  '
END

SELECT @sql =
'SET NOCOUNT ON

DECLARE 
	@per AS TINYINT
	, @idsucursal AS SMALLINT
	, @ejercicio AS SMALLINT

SELECT
	@per = ' + CONVERT(VARCHAR(2),@per1) + '
	, @idsucursal = ' + RTRIM(CONVERT(VARCHAR(3),@idsucursal)) + '
	, @ejercicio = ' + RTRIM(CONVERT(VARCHAR(4),@ejercicio)) + '

INSERT INTO ##tmp_balance (
	columna
	, grupo
	, renglon
	, llave
	, cuenta
	, nombre
	, saldo
)

-- Cuentas de Activo
SELECT 
	columna = 1
	, grupo = 1
	, renglon = 0
	, a.llave
	, a.cuenta
	, nombre = REPLICATE(''. '', a.nivel-2) + RTRIM(a.nombre)
	, saldo = [dbo].[fn_ct_cuentaSaldo](a.cuenta,@ejercicio,@per, @idsucursal) * (CASE WHEN a.naturaleza = 1 THEN (-1) ELSE (1) END)
FROM 
	ew_ct_cuentas AS a 
WHERE 
	a.tipo = 1 
	AND a.idcuenta > 10 ' + @d + @ceros2 + '

UNION ALL

SELECT 
	columna = 1
	, grupo = 2
	, renglon = 10000
	, llave = ''10001''
	, cuenta = ''_ACTIVO''
	, nombre = ''Suma del Activo''
	, saldo = [dbo].[fn_ct_cuentaSaldo](a.cuenta, @ejercicio, @per, @idsucursal)
FROM 
	ew_ct_cuentas AS a 
WHERE 
	a.cuenta = ''_ACTIVO''

UNION ALL

-- Cuentas de Pasivo
SELECT 
	columna = 2
	, grupo = 2
	, renglon = 0
	, a.llave
	, a.cuenta
	, nombre = REPLICATE(''. '', a.nivel-2) + RTRIM(a.nombre)
	, saldo = [dbo].[fn_ct_cuentaSaldo](a.cuenta, @ejercicio, @per, @idsucursal) * (CASE WHEN a.naturaleza = 0 THEN (-1) ELSE (1) END)
FROM 
	ew_ct_cuentas AS a 
WHERE 
	a.tipo = 2
	AND a.idcuenta > 10 ' + @d + @ceros2 + '

UNION ALL

SELECT 
	columna = 2
	, grupo = 3
	, renglon = 0
	, llave = ''10002''
	, cuenta = ''_BPASIVO''
	, nombre = ''Suma del Pasivo''
	, saldo = [dbo].[fn_ct_cuentaSaldo](a.cuenta, @ejercicio, @per, @idsucursal) * (CASE WHEN a.naturaleza = 0 THEN (-1) ELSE (1) END)
FROM 
	ew_ct_cuentas AS a 
WHERE 
	a.cuenta = ''_BPASIVO''

UNION ALL

-- Cuentas de Capital
SELECT 
	columna = 2
	, grupo = 4
	, renglon = 0
	, a.llave
	, a.cuenta
	, nombre = REPLICATE(''. '', a.nivel-2) + RTRIM(a.nombre)
	, saldo = [dbo].[fn_ct_cuentaSaldo](a.cuenta, @ejercicio, @per, @idsucursal) * (CASE WHEN a.naturaleza = 0 THEN (-1) ELSE (1) END)
FROM 
	ew_ct_cuentas AS a 
WHERE
	a.tipo = 3
	AND a.idcuenta > 10 ' + @d + @ceros2 + '

UNION ALL

-- UTILIDAD EJERCICIO ANTERIOR
SELECT 
	columna = 2
	, grupo = 5
	, renglon = 0
	, llave = ''10003''
	, cuenta = ''_UTILIDAD''
	, nombre = ''. GANANCIA O PERDIDA EJERCICIO '' + ''' + CONVERT(VARCHAR(4),@ejercicio-1)  + '''
	, saldo = [dbo].[fn_ct_cuentaSaldoInicialEx](''_UTILIDAD'', @ejercicio, @idsucursal, 1)

UNION ALL

-- UTILIDAD EJERCICIO ACTUAL
SELECT 
	columna = 2
	, grupo = 5
	, renglon = 0
	, llave = ''10003''
	, cuenta = ''_UTILIDAD''
	, nombre = ''. GANANCIA O PERDIDA EJERCICIO '' + ''' + CONVERT(VARCHAR(4),@ejercicio)  + '''
	, saldo = [dbo].[fn_ct_cuentaSaldo](''_UTILIDAD'', @ejercicio, @per, @idsucursal) - dbo._ct_fnc_cuentasaldoInicial(''_UTILIDAD'', @ejercicio, @idsucursal, 1)

UNION ALL

SELECT 
	columna = 2
	, grupo = 5
	, renglon = 0
	, llave = ''10003''
	, cuenta = ''_CAPITAL''
	, nombre = ''Suma del Capital''
	, saldo = [dbo].[fn_ct_cuentaSaldo](a.cuenta, @ejercicio, @per, @idsucursal) * (CASE WHEN a.naturaleza = 0 THEN (-1) ELSE (1) END)
FROM 
	ew_ct_cuentas AS a 
WHERE 
	a.cuenta = ''_CAPITAL''

UNION ALL

SELECT
	columna = 2
	, grupo = 3
	, renglon = 10000
	, llave = ''''
	, cuenta = ''''
	, nombre = ''Suma Pasivo + Capital''
	, saldo = (
		[dbo].[fn_ct_cuentaSaldo](''_BPASIVO'',@ejercicio,@per, @idsucursal) +
		[dbo].[fn_ct_cuentaSaldo](''_CAPITAL'',@ejercicio,@per, @idsucursal)
	)

ORDER BY
	columna
	, grupo
	, renglon
	, llave
'

EXEC (@sql)

SELECT @cont = COUNT(*) 
FROM 
	##tmp_balance 
WHERE 
	columna = 1

INSERT INTO ##tmp_balance (
	columna
	, grupo
	, renglon
) 
VALUES (
	1
	, 2
	, @cont
)

UPDATE a SET 
	renglon = (
		SELECT COUNT(b.cuenta) 
		FROM 
			##tmp_balance AS b
		WHERE 
			b.columna = a.columna 
			AND b.idr < a.idr
	)
FROM 
	##tmp_balance AS a
WHERE 
	renglon = 0

SELECT 
	[renglon] = a.renglon
	, [cuenta1] = (
		SELECT x.cuenta 
		FROM ##tmp_balance AS x
		WHERE 
			x.columna = 1 
			AND x.renglon = a.renglon
	)
	, [nombre1] = (
		SELECT x.nombre 
		FROM ##tmp_balance AS x 
		WHERE 
			x.columna = 1
			AND x.renglon = a.renglon
	)
	, [saldo1] = (
		SELECT x.saldo 
		FROM ##tmp_balance AS x 
		WHERE 
			x.columna = 1 
			AND x.renglon = a.renglon
	)
	, [cuenta2] = (
		SELECT x.cuenta 
		FROM ##tmp_balance AS x 
		WHERE 
			x.columna = 2
			AND x.renglon = a.renglon
	)
	, [nombre2] = (
		SELECT x.nombre 
		FROM ##tmp_balance AS x 
		WHERE 
			x.columna = 2 
			AND x.renglon = a.renglon
	)
	, [saldo2] = (
		SELECT x.saldo 
		FROM ##tmp_balance AS x
		WHERE 
			x.columna = 2 
			AND x.renglon = a.renglon
	)
	, [fecha] = (
		DATEADD(
			dd
			, -DAY(DATEADD(m, 1, ('01/' + CONVERT(VARCHAR(02),@per1,3) + '/' + CONVERT(VARCHAR(04),@ejercicio,3))))
			, DATEADD(m, 1, ('01/' + CONVERT(VARCHAR(02),@per1,3) + '/' + CONVERT(VARCHAR(04),@ejercicio,3)))
		)
	)
FROM 
	##tmp_balance AS a

GROUP BY 
	a.renglon

DROP TABLE ##tmp_balance
GO
