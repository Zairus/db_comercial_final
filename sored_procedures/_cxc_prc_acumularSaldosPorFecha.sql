USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150311
-- Description:	Bitacora de saldos por fecha CXC
-- =============================================
CREATE PROCEDURE [dbo].[_cxc_prc_acumularSaldosPorFecha]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@saldo AS DECIMAL(18,6)
	,@fecha1 AS SMALLDATETIME
	,@fecha AS SMALLDATETIME
	,@idmov2 AS MONEY
	,@importe AS DECIMAL(18,6)
	,@tipo1 AS SMALLINT
	,@tipo2 AS SMALLINT
	,@transaccion AS VARCHAR(5)

DELETE FROM ew_cxc_transacciones_saldos WHERE idtran = @idtran

SELECT
	@idmov2 = idmov
	,@fecha1 = fecha
	,@fecha = fecha
	,@saldo = total
	,@tipo1 = tipo
	,@transaccion = transaccion
FROM
	ew_cxc_transacciones
WHERE
	idtran = @idtran

INSERT INTO ew_cxc_transacciones_saldos (
	idtran
	,fecha
	,saldo
	,idmov2
	,transaccion
)
VALUES (
	@idtran
	,@fecha
	,@saldo
	,@idmov2
	,@transaccion
)

DECLARE cur_afectaciones CURSOR FOR
	SELECT
		ct.fecha
		,ctm.importe2
		,ctm.idmov
		,ct.tipo
		,ct.transaccion
	FROM
		ew_cxc_transacciones_mov AS ctm
		LEFT JOIN ew_cxc_transacciones AS ct
			ON ct.idtran = ctm.idtran
	WHERE
		ct.cancelado = 0
		AND ctm.idtran2 = @idtran
	ORDER BY
		ct.fecha
		,ct.idtran

OPEN cur_afectaciones

FETCH NEXT FROM cur_afectaciones INTO
	@fecha
	,@importe
	,@idmov2
	,@tipo2
	,@transaccion

WHILE @@FETCH_STATUS = 0
BEGIN
	IF @tipo1 = @tipo2
	BEGIN
		SELECT @saldo = @saldo + @importe
	END
		ELSE
	BEGIN
		SELECT @saldo = @saldo - @importe
	END

	UPDATE ew_cxc_transacciones_saldos SET
		saldo = @saldo
	WHERE
		idtran = @idtran
		AND fecha = (CASE WHEN @fecha < @fecha1 THEN @fecha1 ELSE @fecha END)

	IF @@ROWCOUNT = 0
	BEGIN
		INSERT INTO ew_cxc_transacciones_saldos (
			idtran
			,fecha
			,saldo
			,idmov2
			,transaccion
		)
		SELECT
			[idtran] = @idtran
			,[fecha] = (CASE WHEN @fecha < @fecha1 THEN @fecha1 ELSE @fecha END)
			,[saldo] = @saldo
			,[idmov2] = @idmov2
			,[transaccion] = @transaccion
		
	END

	FETCH NEXT FROM cur_afectaciones INTO
		@fecha
		,@importe
		,@idmov2
		,@tipo2
		,@transaccion
END

CLOSE cur_afectaciones
DEALLOCATE cur_afectaciones

DECLARE cur_aplicaciones2 CURSOR FOR
	SELECT
		f.fecha
		,ctm.importe
		,f.idmov
		,f.tipo
		,f.transaccion
	FROM
		ew_cxc_transacciones_mov AS ctm
		LEFT JOIN ew_cxc_transacciones As f
			ON f.idtran = ctm.idtran2
	WHERE
		ctm.idtran = @idtran
	ORDER BY
		f.fecha
		,f.idtran

OPEN cur_aplicaciones2

FETCH NEXT FROM cur_aplicaciones2 INTO
	@fecha
	,@importe
	,@idmov2
	,@tipo2
	,@transaccion

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @saldo = @saldo - @importe

	UPDATE ew_cxc_transacciones_saldos SET
		saldo = @saldo
	WHERE
		idtran = @idtran
		AND fecha = (CASE WHEN @fecha < @fecha1 THEN @fecha1 ELSE @fecha END)

	IF @@ROWCOUNT = 0
	BEGIN
		INSERT INTO ew_cxc_transacciones_saldos (
			idtran
			,fecha
			,saldo
			,idmov2
			,transaccion
		)
		SELECT
			[idtran] = @idtran
			,[fecha] = (CASE WHEN @fecha < @fecha1 THEN @fecha1 ELSE @fecha END)
			,[saldo] = @saldo
			,[idmov2] = @idmov2
			,[transaccion] = @transaccion
		
	END

	FETCH NEXT FROM cur_aplicaciones2 INTO
		@fecha
		,@importe
		,@idmov2
		,@tipo2
		,@transaccion
END

CLOSE cur_aplicaciones2
DEALLOCATE cur_aplicaciones2
GO
