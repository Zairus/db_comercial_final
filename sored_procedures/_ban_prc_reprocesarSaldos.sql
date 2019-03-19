USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190301
-- Description:	Reprocesar saldos bancos
-- =============================================
ALTER PROCEDURE [dbo].[_ban_prc_reprocesarSaldos]
AS

SET NOCOUNT ON

DECLARE
	@error AS VARCHAR(100)
	, @ejercicio_anterior AS INT
	, @idcuenta AS INT
	, @ejercicio AS INT
	, @periodo AS INT
	, @tipo AS SMALLINT
	, @cargos AS DECIMAL(18,6)
	, @abonos AS DECIMAL(18,6)
	, @importe AS DECIMAL(18,6)

TRUNCATE TABLE ew_ban_saldos

SELECT @ejercicio_anterior = 0

DECLARE cur_banReprocesaSaldos CURSOR FOR
	SELECT
		bt.idcuenta
		, [ejercicio] = YEAR(bt.fecha)
		, [periodo] = MONTH(bt.fecha)
		, [tipo] = 0
		, [cargos] = SUM(CASE WHEN bt.tipo = 1 THEN bt.importe ELSE 0 END)
		, [abonos] = SUM(CASE WHEN bt.tipo = 2 THEN bt.importe ELSE 0 END)
		, [importe] = 0
	FROM
		ew_ban_transacciones AS bt
	WHERE
		bt.cancelado = 0
		AND bt.tipo IN (1,2)
	GROUP BY
		bt.idcuenta
		, YEAR(bt.fecha)
		, MONTH(bt.fecha)
	ORDER BY
		bt.idcuenta
		, YEAR(bt.fecha)
		, MONTH(bt.fecha)

OPEN cur_banReprocesaSaldos

FETCH NEXT FROM cur_banReprocesaSaldos INTO
	@idcuenta
	, @ejercicio
	, @periodo
	, @tipo
	, @cargos
	, @abonos
	, @importe

WHILE @@FETCH_STATUS = 0
BEGIN
	IF @ejercicio <> @ejercicio_anterior
	BEGIN
		EXEC _ban_prc_ejercicioInicializar @ejercicio
		SELECT @ejercicio_anterior = @ejercicio
	END

	EXEC _ban_prc_acumularSaldos @idcuenta, @ejercicio, @periodo, @tipo, @cargos, @abonos, @importe, @error OUTPUT

	IF LEN(@error) > 0
	BEGIN
		PRINT '[WARNING]: ' + @error
	END

	FETCH NEXT FROM cur_banReprocesaSaldos INTO
		@idcuenta
		, @ejercicio
		, @periodo
		, @tipo
		, @cargos
		, @abonos
		, @importe
END

CLOSE cur_banReprocesaSaldos
DEALLOCATE cur_banReprocesaSaldos
GO
