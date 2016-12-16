USE [db_comercial_final]
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: yyyymmdd
-- Description:	Acumular saldos de bancos
-- =============================================
ALTER PROCEDURE [dbo].[_ban_prc_acumularSaldos]
	@idcuenta AS SMALLINT
	,@ejercicio AS SMALLINT
	,@periodo AS TINYINT
	,@tipo AS BIT = '0'
	,@ingresos AS DECIMAL(15,2) = 0
	,@egresos AS DECIMAL(15,2) = 0
	,@importe AS DECIMAL(15,2) = 0
	,@error AS VARCHAR(100) OUTPUT
AS

SET NOCOUNT ON

DECLARE
	@id AS INT
	,@msg AS VARCHAR(500)
	,@activo AS BIT
	,@per AS VARCHAR(20)
	,@sql AS VARCHAR(4000)
	,@sql2 AS VARCHAR(4000)
	,@simporte AS VARCHAR(15)
	,@listado AS VARCHAR(4000)
	,@listado2 AS VARCHAR(4000)
	,@separador AS VARCHAR(1)
	,@p AS VARCHAR(100)
	,@cont AS INT

IF @periodo Not Between 1 And 12
BEGIN
	SELECT @error  ='Periodo No Válido.'
	
	RAISERROR(@error, 16, 1)
	RETURN
END

SELECT @per = 'periodo' + RTRIM(CONVERT(VARCHAR(2), @periodo))

SELECT @activo = null
SELECT @error = ''

SELECT 
	@activo = activo
FROM ew_ct_cierres 
WHERE 
	ejercicio = @ejercicio 
	AND periodo = @periodo

IF @activo Is Null
BEGIN
	INSERT INTO ew_ct_cierres 
		(ejercicio, periodo) 
	VALUES
		(@ejercicio, @periodo)
	
	SELECT 
		@activo = activo 
	FROM ew_ct_cierres 
	WHERE 
		ejercicio = @ejercicio 
		AND periodo = @periodo
END

IF @activo = '0'
BEGIN
	SELECT @error = 'Periodo Inactivo, no se permiten movimientos.'
	
	RAISERROR(@error, 16, 1)
	RETURN
END

SELECT @simporte = '(' + RTRIM(CONVERT(VARCHAR(15), @importe)) + ')'

SELECT @listado = '', @separador = '', @cont = @periodo

WHILE @cont < 13
BEGIN
	SELECT @p = 'periodo' + RTRIM(CONVERT(VARCHAR(2), @cont)) 
	
	SELECT @listado = @listado + @separador + @p +  ' = (' + @p + ') + (' + CONVERT(VARCHAR(15),@ingresos) + ') - (' + CONVERT(VARCHAR(15),@egresos) + ')'
	
	SELECT @cont = @cont + 1
	SELECT @separador = ','
END

IF Not Exists(
	SELECT TOP 1 
		idcuenta 
	FROM ew_ban_saldos 
	WHERE 
		idcuenta = @idcuenta 
		AND ejercicio = @ejercicio
)
BEGIN
	INSERT INTO ew_ban_saldos (idcuenta, ejercicio, tipo) VALUES (@idcuenta, @ejercicio, 1)
	INSERT INTO ew_ban_saldos (idcuenta, ejercicio, tipo) VALUES (@idcuenta, @ejercicio, 2)
	INSERT INTO ew_ban_saldos (idcuenta, ejercicio, tipo) VALUES (@idcuenta, @ejercicio, 3)
END

SELECT @sql = ''

IF @ingresos != 0
BEGIN
	SELECT @sql = 'UPDATE ew_ban_saldos SET 
	' + @per + ' = ' +@per + '+(' + CONVERT(VARCHAR(15),@ingresos) + ') 
WHERE 
	idcuenta = ' + CONVERT(VARCHAR(4), @idcuenta) + ' 
	AND ejercicio = ' + CONVERT(VARCHAR(4), @ejercicio) + '
	AND tipo = 2 '
END

IF @egresos != 0
BEGIN
	SELECT @sql = @sql + 'UPDATE ew_ban_saldos SET 
	' + @per + ' = ' +@per + '+(' + CONVERT(VARCHAR(15),@egresos) + ') 
WHERE 
	idcuenta = '  + CONVERT(VARCHAR(4), @idcuenta) + ' 
	AND ejercicio = ' + CONVERT(VARCHAR(4), @ejercicio) + '
	AND tipo = 3'
END

EXEC(@sql)

IF @@error != 0
BEGIN
	SELECT @error = 'Error al afectar saldos de la cuenta de bancos con la sig. instruccion:
' + @sql
	
	RAISERROR(@error, 16, 1)
	RETURN
END

SELECT @sql2 = @listado

SELECT @sql = 'UPDATE ew_ban_saldos SET 
	' + @sql2 + '
WHERE 
	idcuenta = '  + CONVERT(VARCHAR(4), @idcuenta) + '
	AND ejercicio = ' + CONVERT(VARCHAR(4), @ejercicio) + ' 
	AND tipo = 1 '

EXEC (@sql)	

UPDATE ew_ban_cuentas SET
	saldo_actual = saldo_actual + @ingresos - @egresos
WHERE
	idcuenta = @idcuenta

IF @@error != 0
BEGIN
	SELECT @error = 'Error al afectar saldos de bancos con la sig. instruccion: 
 ' + @sql
	
	RAISERROR(@error, 16, 1)
	RETURN
END
GO
