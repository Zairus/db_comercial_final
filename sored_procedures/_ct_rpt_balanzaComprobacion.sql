USE db_comercial_final
GO
IF OBJECT_ID('_ct_rpt_balanzaComprobacion') IS NOT NULL
BEGIN
	DROP PROCEDURE _ct_rpt_balanzaComprobacion
END
GO
-- ========================================================
-- Autor		: Laurence Saavedra
-- Fecha		: 20080501
-- Descripcion	: 
-- Modifcado	: Arvin Valenzuela  200811
-- Ejemplo      :EXEC _ct_rpt_balanzaComprobacion '','',2010, 1, 5, 0,-1
-- ========================================================
CREATE PROCEDURE [dbo].[_ct_rpt_balanzaComprobacion]
	@cuenta1 AS VARCHAR(20)
	, @cuenta2 AS VARCHAR(20)
	, @ejercicio AS SMALLINT
	, @periodo AS INT
	, @idsucursal AS SMALLINT
	, @saldoCero AS BIT = '1'
	, @mayor AS BIT = '0'
AS

SET NOCOUNT ON

DECLARE 
	@sql AS VARCHAR(8000)
	, @filtro_cuentas AS VARCHAR(1000)
	, @filtro_saldoCero AS VARCHAR(1000)
	, @filtro_mayor AS VARCHAR(1000)
	, @nivel AS TINYINT

--- VALIDACIONES

IF @cuenta2 = ''
BEGIN
	SELECT 
		@cuenta2 = MAX(cuenta)
	FROM 
		ew_ct_cuentas
END

IF @periodo < 1 
BEGIN
	SELECT @periodo = 1
END

IF @periodo > 14
BEGIN
	SELECT @periodo = 14
END

-- Filtro para el rango de cuentas
SELECT @filtro_cuentas = ''

IF @cuenta1 != ''
BEGIN
	SELECT @filtro_cuentas=' AND (a.cuenta BETWEEN ''' + @cuenta1 + ''' AND ''' + @cuenta2 + ''') '
END

SELECT @nivel = MIN(nivel)
FROM
	ew_ct_cuentas a
WHERE 
	idcuenta > 10
	AND a.cuenta BETWEEN @cuenta1 AND @cuenta2

-- Filtro para incluir cuentas unicamente con saldo != 0
SELECT @filtro_saldoCero = ''

IF @saldoCero = 1
BEGIN
	SELECT @filtro_saldoCero = ' AND ([dbo].[fn_ct_cuentaSaldo](a.cuenta, @ejercicio, @periodo, @idsucursal) != 0)'
END

-- Filtro para incluir unicamente cuentas de mayor
SELECT @filtro_mayor = ''

IF @mayor = 0
BEGIN
	SELECT @filtro_mayor = ' AND (a.ctamayor = 1) '	
END

--------------------------------------------------------------------------------
-- GENERAMOS EL SCRIPT
--------------------------------------------------------------------------------
SELECT @sql='DECLARE 
	@ejercicio AS SMALLINT
	, @periodo AS TINYINT
	, @idsucursal AS SMALLINT
	, @perant AS SMALLINT	
	, @nivel AS SMALLINT

SELECT 
	@ejercicio = ' + CONVERT(VARCHAR(4),@ejercicio) + '
	, @periodo = ' + CONVERT(VARCHAR(2),@periodo) + '
	, @idsucursal = ' + CONVERT(VARCHAR(3),@idsucursal) + '
	, @nivel = ' + CONVERT(VARCHAR(2),@nivel) + '

SELECT @perant = @periodo - 1

SELECT
	[objlevel] = 0
	, [nivel] = 0
	, [tipocta] = ''''
	, [tipo] = ''''
	, [tipo_nombre] = ''G l o b a l''
	, [cuenta] = ''_GLOBAL''
	, [nombre] = ''Totales Globales''
	, [saldoini] = (
		CASE 
			WHEN @periodo = 1 THEN 
				[dbo].[fn_ct_cuentaSaldoInicialEx](''_GLOBAL'', @ejercicio, @idsucursal, 1) 
			ELSE 
				[dbo].[fn_ct_cuentaSaldo](''_GLOBAL'', @ejercicio, @perant, @idsucursal) 
		END
	)
	, [cargos] = [dbo].[_ct_fnc_cuentasaldoTipo](''_GLOBAL'', @ejercicio, @periodo, @idsucursal, 2)
	, [abonos] = [dbo].[_ct_fnc_cuentasaldoTipo](''_GLOBAL'', @ejercicio, @periodo, @idsucursal, 3)
	, [saldo] = [dbo].[fn_ct_cuentaSaldo](''_GLOBAL'', @ejercicio, @periodo, @idsucursal)
	, [llave] = ''''

UNION ALL

SELECT
	[objlevel] = (
		1 
		+ (
			CASE 
				WHEN a.nivel > CONVERT(TINYINT, dbo._ct_fnc_cuentaTipo(a.cuenta, 3)) THEN 
					a.nivel - CONVERT(TINYINT, dbo._ct_fnc_cuentaTipo(a.cuenta, 3)) 
				ELSE 0 
			END
		)
	)
	, [nivel] = a.nivel
	, [tipocta] = a.tipo
	, [tipo] = (
		CASE (
			CASE dbo._ct_fnc_cuentaTipo(a.cuenta, 5) 
				WHEN '''' THEN dbo._ct_fnc_cuentaTipo(a.cuenta,2) 
				ELSE dbo._ct_fnc_cuentaTipo(a.cuenta,5) 
			END
		) 
			WHEN ''Activo'' THEN 1
			WHEN ''Pasivo'' THEN 2
			WHEN ''Capital'' THEN 3
			WHEN ''Ingresos'' THEN 4
			WHEN ''Egresos'' THEN 5
		END
	)
	, [tipo_nombre] = (
		CASE dbo._ct_fnc_cuentaTipo(a.cuenta,5) 
			WHEN '''' THEN dbo._ct_fnc_cuentaTipo(a.cuenta, 2) 
			ELSE dbo._ct_fnc_cuentaTipo(a.cuenta, 5)
		END
	)
	, [cuenta] = a.cuenta
	, [nombre] = a.nombre
	, [saldoini] = (
		CASE 
			WHEN @periodo = 1 THEN 
				[dbo].[fn_ct_cuentaSaldoInicialEx](a.cuenta, @ejercicio, @idsucursal, 1) 
			ELSE 
				[dbo].[fn_ct_cuentaSaldo](a.cuenta, @ejercicio, @perant, @idsucursal) 
		END
	)
	, [cargos] = [dbo].[_ct_fnc_cuentasaldoTipo](a.cuenta, @ejercicio, @periodo, @idsucursal,2)
	, [abonos] = [dbo].[_ct_fnc_cuentasaldoTipo](a.cuenta, @ejercicio, @periodo, @idsucursal,3)
	, [saldo] = [dbo].[fn_ct_cuentaSaldo](a.cuenta, @ejercicio, @periodo, @idsucursal)
	, [llave] = a.llave
FROM
	ew_ct_cuentas AS a
WHERE 
	idcuenta > 10 
	AND a.tipo NOT IN (6, 7)
	' + @filtro_cuentas + ' 
	' + @filtro_saldoCero + '
	' + @filtro_mayor + '
ORDER BY	
	[tipo]
	, [llave]'

EXEC (@sql)
GO
