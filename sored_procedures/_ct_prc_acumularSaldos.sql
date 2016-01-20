USE db_comercial_final
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 2010-07
-- Description:	Acumular saldos contables
-- =============================================
ALTER PROCEDURE [dbo].[_ct_prc_acumularSaldos]
	@cuenta AS VARCHAR(20)
	,@idsucursal AS SMALLINT
	,@ejercicio AS SMALLINT
	,@periodo AS SMALLINT
	,@cargos AS DECIMAL(12,2)
	,@abonos AS DECIMAL(12,2)
	,@importe AS DECIMAL(12,2)
	,@error_mensaje AS VARCHAR(800) OUTPUT
	,@contab AS TINYINT = 0
	,@forzar_afectar AS BIT = 0
AS

SET NOCOUNT ON

DECLARE
	@cuenta2 AS VARCHAR(20)
	,@periodo2 AS SMALLINT
	,@naturaleza AS TINYINT

DECLARE
	@sql AS VARCHAR(4000)
	,@sql2 AS VARCHAR(4000)

IF NOT EXISTS(SELECT cuenta FROM ew_ct_cuentas WHERE cuenta = @cuenta)
BEGIN
	SELECT @error_mensaje = 'La Cuenta ' + @cuenta + ' no existe...'

	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

IF NOT EXISTS(SELECT cuenta FROM ew_ct_cuentas WHERE afectable = 1 AND cuenta = @cuenta)
BEGIN
	IF @forzar_afectar = 0
	BEGIN
		SELECT @error_mensaje = 'La Cuenta ' + @cuenta + ' no es afectable...'

		RAISERROR(@error_mensaje, 16, 1)
		RETURN
	END
END

IF @contab > 0 
	SELECT @contab = 100

DECLARE cur_arbol CURSOR FOR
	SELECT
		cuenta
	FROM
		dbo._ct_fnc_arbol(@cuenta)

OPEN cur_arbol

FETCH NEXT FROM cur_arbol INTO
	@cuenta2

WHILE @@FETCH_STATUS = 0
BEGIN
	IF NOT EXISTS(
		SELECT TOP 1 cuenta 
		FROM 
			ew_ct_saldos 
		WHERE 
			idsucursal = 0
			AND cuenta = @cuenta2 
			AND ejercicio = @ejercicio 
			AND tipo = (1 + @contab)
	)
	BEGIN
		--print @cuenta2 + '.........'
		INSERT INTO ew_ct_saldos (cuenta, idsucursal, ejercicio, tipo) VALUES (@cuenta2, 0, @ejercicio, 1 + @contab)
		INSERT INTO ew_ct_saldos (cuenta, idsucursal, ejercicio, tipo) VALUES (@cuenta2, 0, @ejercicio, 2 + @contab)
		INSERT INTO ew_ct_saldos (cuenta, idsucursal, ejercicio, tipo) VALUES (@cuenta2, 0, @ejercicio, 3 + @contab)
	END

	IF NOT EXISTS(
		SELECT TOP 1 cuenta 
		FROM 
			ew_ct_saldos 
		WHERE 
			cuenta = @cuenta2
			AND idsucursal = @idsucursal 
			AND ejercicio = @ejercicio 
			AND (tipo = 1 + @contab)
	)
	BEGIN
		INSERT INTO ew_ct_saldos (cuenta, idsucursal, ejercicio, tipo) VALUES (@cuenta2, @idsucursal, @ejercicio, 1 + @contab)
		INSERT INTO ew_ct_saldos (cuenta, idsucursal, ejercicio, tipo) VALUES (@cuenta2, @idsucursal, @ejercicio, 2 + @contab)
		INSERT INTO ew_ct_saldos (cuenta, idsucursal, ejercicio, tipo) VALUES (@cuenta2, @idsucursal, @ejercicio, 3 + @contab)
	END
	
	SELECT @periodo2 = @periodo
	
	SELECT
		@naturaleza = naturaleza
	FROM ew_ct_cuentas
	WHERE
		cuenta = @cuenta2
	
	IF @cargos <> 0
	BEGIN
		SELECT @sql = '
UPDATE ew_ct_saldos SET
	periodo' + CONVERT(VARCHAR(20), @periodo2) + ' = periodo' + CONVERT(VARCHAR(20), @periodo2) + ' + ' + CONVERT(VARCHAR(20), @cargos) + '
WHERE 
	tipo = 2+' + CONVERT(VARCHAR(3),@contab) + '
	AND idsucursal IN (0, ' + CONVERT(VARCHAR(20), @idsucursal) + ')
	AND cuenta = ''' + @cuenta2 + '''
	AND ejercicio = ' + CONVERT(VARCHAR(20), @ejercicio)
		
		EXEC(@sql)
		
		IF @@error <> 0
		BEGIN
			SELECT @error_mensaje = 'ERROR: Ocurrió un error al acumular el saldo de la cuenta [' + @cuenta2 + '], en el ejercicio [' + CONVERT(VARCHAR(20), @ejercicio) + '], en el periodo [' + CONVERT(VARCHAR(20), @periodo2) + ']'
		END
	END
	
	IF @abonos <> 0
	BEGIN
		SELECT @sql = '
UPDATE ew_ct_saldos SET
	periodo' + CONVERT(VARCHAR(20), @periodo2) + ' = periodo' + CONVERT(VARCHAR(20), @periodo2) + ' + ' + CONVERT(VARCHAR(20), @abonos) + '
WHERE 
	tipo = 3+' + CONVERT(VARCHAR(3),@contab) + '
	AND idsucursal IN (0, ' + CONVERT(VARCHAR(20), @idsucursal) + ')
	AND cuenta = ''' + @cuenta2 + '''
	AND ejercicio = ' + CONVERT(VARCHAR(20), @ejercicio)
		
		EXEC(@sql)
		
		IF @@error <> 0
		BEGIN
			SELECT @error_mensaje = 'ERROR: Ocurrió un error al acumular el saldo de la cuenta [' + @cuenta2 + '], en el ejercicio [' + CONVERT(VARCHAR(20), @ejercicio) + '], en el periodo [' + CONVERT(VARCHAR(20), @periodo2) + ']'
		END
	END
	
	WHILE @periodo2 <= 13
	BEGIN
		IF @naturaleza = 0
		BEGIN
			SELECT @sql2 = '((' + CONVERT(VARCHAR(20), @cargos) + ') - (' + CONVERT(VARCHAR(20), @abonos) + '))'
		END
			ELSE
		BEGIN
			SELECT @sql2 = '((' + CONVERT(VARCHAR(20), @abonos) + ') - (' + CONVERT(VARCHAR(20), @cargos) + '))'
		END
		SELECT @sql = '
UPDATE ew_ct_saldos SET
periodo' + CONVERT(VARCHAR(20), @periodo2) + ' = periodo' + CONVERT(VARCHAR(20), (@periodo2)) + ' + ' + @sql2 + '
WHERE
tipo = (1+' + CONVERT(VARCHAR(3),@contab) + ')
AND idsucursal IN (0, ' + CONVERT(VARCHAR(20), @idsucursal) + ')
AND cuenta = ''' + @cuenta2 + '''
AND ejercicio = ' + CONVERT(VARCHAR(20), @ejercicio)
		
		EXEC(@sql)
		
		IF @@error <> 0
		BEGIN
			SELECT @error_mensaje = 'ERROR: Ocurrió un error al acumular el saldo de la cuenta [' + @cuenta2 + '], en el ejercicio [' + CONVERT(VARCHAR(20), @ejercicio) + '], en el periodo [' + CONVERT(VARCHAR(20), @periodo2) + ']'
		END
		
		SELECT @periodo2 = @periodo2 + 1
	END
	
	FETCH NEXT FROM cur_arbol INTO
		@cuenta2
END

CLOSE cur_arbol
DEALLOCATE cur_arbol
GO
