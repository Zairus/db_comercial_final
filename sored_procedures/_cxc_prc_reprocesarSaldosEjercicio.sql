USE db_comercial_final
GO
IF OBJECT_ID('_cxc_prc_reprocesarSaldosEjercicio') IS NOT NULL
BEGIN
	DROP PROCEDURE _cxc_prc_reprocesarSaldosEjercicio
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200415
-- Description:	Reprocesar saldos de CXC por Ejercicio
-- =============================================
CREATE PROCEDURE [dbo].[_cxc_prc_reprocesarSaldosEjercicio]
	@ejercicio AS INT
	, @debug AS INT = 0
AS

SET NOCOUNT ON
SET DEADLOCK_PRIORITY 10

DECLARE
	@idcliente AS INT
	, @periodo AS INT
	, @idmoneda AS INT
	, @cargos AS DECIMAL(18, 6)
	, @abonos AS DECIMAL(18, 6)
	, @importe AS DECIMAL(18, 6)
	, @error_mensaje AS VARCHAR(200)

IF @debug = 1
BEGIN
	PRINT 'Eliminado saldos del ejercicio...'
END

UPDATE ew_cxc_saldos SET
	periodo1 = 0
	, periodo2 = 0
	, periodo3 = 0
	, periodo4 = 0
	, periodo5 = 0
	, periodo6 = 0
	, periodo7 = 0
	, periodo8 = 0
	, periodo9 = 0
	, periodo10 = 0
	, periodo11 = 0
	, periodo12 = 0
WHERE
	ejercicio = @ejercicio

IF @debug = 1
BEGIN
	PRINT 'Saldos en cero.'
END

DECLARE cur_acumulaCXC CURSOR FOR
	SELECT
		[idcliente] = ct.idcliente
		, [periodo] = MONTH(ct.fecha)
		, [idmoneda] = ct.idmoneda
		, [cargos] = SUM(CASE WHEN ct.tipo = 1 THEN ct.total ELSE 0 END)
		, [abonos] = SUM(CASE WHEN ct.tipo = 2 THEN ct.total ELSE 0 END)
		, [importe] = SUM(ct.total)
	FROM 
		ew_cxc_transacciones AS ct
	WHERE
		ct.cancelado = 0
		AND ct.aplicado = 1
		AND ct.tipo IN (1,2)
		AND ct.acumula = 1
		AND YEAR(ct.fecha) = @ejercicio
	GROUP BY
		ct.idcliente
		, MONTH(ct.fecha)
		, ct.idmoneda
		, ct.tipo
	ORDER BY
		ct.idcliente
		, MONTH(ct.fecha)
		, ct.tipo
		, ct.idmoneda

OPEN cur_acumulaCXC

FETCH NEXT FROM cur_acumulaCXC INTO
	@idcliente
	, @periodo
	, @idmoneda
	, @cargos
	, @abonos
	, @importe

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @error_mensaje = NULL

	EXEC [dbo].[_cxc_prc_acumularSaldos]
		@idcliente = @idcliente
		, @ejercicio = @ejercicio
		, @periodo = @periodo
		, @idmoneda = @idmoneda
		, @cargos = @cargos
		, @abonos = @abonos
		, @importe = @importe
		, @error_mensaje = @error_mensaje

	IF @debug = 1
	BEGIN
		PRINT 'Acumulado ejercicio: ' + LTRIM(RTRIM(STR(@ejercicio)))

		IF @error_mensaje IS NOT NULL
		BEGIN
			PRINT @error_mensaje
		END
	END

	FETCH NEXT FROM cur_acumulaCXC INTO
		@idcliente
		, @periodo
		, @idmoneda
		, @cargos
		, @abonos
		, @importe
END

CLOSE cur_acumulaCXC
DEALLOCATE cur_acumulaCXC

IF @debug = 1
BEGIN
	PRINT '[' + LTRIM(RTRIM(STR(@ejercicio))) + ']: Finalizado.'
END
GO
