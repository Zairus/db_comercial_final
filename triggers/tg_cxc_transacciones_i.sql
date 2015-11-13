USE db_comercial_final
GO
-- ==========================================================================================
-- Autor:		Laurence Saavedra
-- Fecha:		2010-02
-- Descripcion: Trigger que se encarga de aplicar la transaccion en cartera
-- ==========================================================================================
ALTER TRIGGER [dbo].[tg_cxc_transacciones_i]
	ON [dbo].[ew_cxc_transacciones]
	FOR INSERT
AS 

SET NOCOUNT ON

DECLARE
	@idtran AS BIGINT
	,@fecha AS SMALLDATETIME
	,@idcliente AS SMALLINT
	,@idu AS SMALLINT
	,@tipo AS SMALLINT
	,@total AS DECIMAL(15,2)
	,@programado AS BIT
	,@idtran2 AS INT

--------------------------------------------------------------------------------
-- Aplicando automaticamente aquellas transacciones que no han sido programadas
--------------------------------------------------------------------------------
DECLARE cur_tg_cxc_transacciones_i CURSOR FOR
	SELECT
		idtran
		, fecha
		, idcliente
		, idu
		, tipo
		, total
		, programado
		, idtran2
	FROM 
		inserted 
	WHERE
		tipo IN (1,2)
		AND programado=0

OPEN cur_tg_cxc_transacciones_i

FETCH NEXT FROM cur_tg_cxc_transacciones_i INTO
	@idtran
	, @fecha
	, @idcliente
	, @idu
	, @tipo
	, @total
	, @programado
	, @idtran2

WHILE @@FETCH_STATUS=0
BEGIN
	
	-- aplicando la transaccion en cartera
	IF @programado = 0
	BEGIN
		--SELECT saldo, total FROM ew_cxc_transacciones WHERE idtran = @idtran
		UPDATE ew_cxc_transacciones SET
			saldo = total
		WHERE
			idtran = @idtran
			
		EXEC _cxc_prc_aplicarTransaccion @idtran, @fecha, @idu
	END

	IF @tipo = 1
	BEGIN
		EXEC _cxc_prc_clienteValidar @idcliente, @idtran
	END

	FETCH NEXT FROM cur_tg_cxc_transacciones_i INTO
		@idtran
		, @fecha
		, @idcliente
		, @idu
		, @tipo
		, @total
		, @programado
		, @idtran2
END

CLOSE cur_tg_cxc_transacciones_i
DEALLOCATE cur_tg_cxc_transacciones_i
GO
