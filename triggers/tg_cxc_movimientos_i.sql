USE db_comercial_final
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 20100201
-- Description:	Trigger que se encarga de enviar a acumular los saldos
-- =============================================
ALTER TRIGGER [dbo].[tg_cxc_movimientos_i]
	ON [dbo].[ew_cxc_movimientos]
	FOR INSERT
AS 

SET NOCOUNT ON

DECLARE
 	@idtran AS INT
	, @idcliente AS SMALLINT
	, @idmoneda AS SMALLINT
	, @importe AS DECIMAL(15,2)
	, @ejercicio AS SMALLINT
	, @periodo AS SMALLINT
	, @cargos AS DECIMAL(15,2)
	, @abonos AS DECIMAL(15,2)
	, @error AS VARCHAR(250)
	, @error_mensaje AS VARCHAR(150)

SELECT @error_mensaje = ''

--------------------------------------------------------------------------------
-- Cursor agrupado por cliente/Moneda para mejorar rendimiento
--------------------------------------------------------------------------------
DECLARE cur_cxc_movimientos CURSOR FOR
	SELECT
		[idtran] = i.idtran
		, [idcliente] = i.idcliente
		, [idmoneda] = i.idmoneda
		, [ejercicio] = DATEPART(YEAR, i.fecha)
		, [periodo] = DATEPART(MONTH, i.fecha)
		, [cargos] = (CASE WHEN i.tipo = 1 THEN i.importe ELSE 0 END)
		, [abonos] = (CASE WHEN i.tipo = 2 THEN i.importe ELSE 0 END)
		, [importe] = (i.importe * ISNULL(NULLIF(CONVERT(INT, i.tipo), 2), -1))
	FROM 
		inserted AS i
		LEFT JOIN ew_cxc_transacciones AS ct
			ON ct.idtran = i.idtran
	WHERE
		i.tipo IN (1,2)
		AND ABS(i.importe) > 0
		AND ct.acumula = 1

OPEN cur_cxc_movimientos

FETCH NEXT FROM cur_cxc_movimientos INTO 
	@idtran
	, @idcliente
	, @idmoneda
	, @ejercicio
	, @periodo
	, @cargos
	, @abonos
	, @importe

WHILE @@FETCH_STATUS = 0
BEGIN	
	SELECT @error = ''

	--------------------------------------------------------------------------------
	-- Acumulado por periodos en EW_cxc_SALDOS
	--------------------------------------------------------------------------------	
	EXEC [dbo].[_cxc_prc_acumularSaldos]
		@idcliente
		, @ejercicio
		, @periodo
		, @idmoneda
		, @cargos
		, @abonos
		, @importe
		, @error OUTPUT

	If @error != ''
	BEGIN
		SELECT @error_mensaje = 'Error. ' + @error
		BREAK
	END
	
	--------------------------------------------------------------------------------
	-- Acumulado Global en EW_cxc_SALDOS_ACTUAL
	--------------------------------------------------------------------------------	
	UPDATE ew_cxc_saldos_actual SET
		saldo = saldo + @importe
	WHERE
		idcliente = @idcliente
		AND idmoneda = @idmoneda

	IF @@ROWCOUNT = 0
	BEGIN
		INSERT INTO ew_cxc_saldos_actual 
			(idcliente, idmoneda, saldo) 
		VALUES
			(@idcliente, @idmoneda, @importe)

		If @@error != 0
		BEGIN
			SELECT @error_mensaje = 'Error. Al acumular globales en EW_cxc_SALDOS_ACTUAL' 
			BREAK
		END
	END
	
	FETCH NEXT FROM cur_cxc_movimientos INTO 
		@idtran
		, @idcliente
		, @idmoneda
		, @ejercicio
		, @periodo
		, @cargos
		, @abonos
		, @importe
END

CLOSE cur_cxc_movimientos
DEALLOCATE cur_cxc_movimientos

--------------------------------------------------------------------------------
-- Regresando un error
--------------------------------------------------------------------------------	
If @error_mensaje != ''
BEGIN
	RAISERROR (@error_mensaje, 16, 1)
END
GO
