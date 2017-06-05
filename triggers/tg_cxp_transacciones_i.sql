USE db_comercial_final
GO
-- ==========================================================================================
-- Autor:		Laurence Saavedra
-- Fecha:		2010-02
-- Descripcion: Trigger que se encarga de aplicar la transaccion en cartera
-- ==========================================================================================
ALTER TRIGGER [dbo].[tg_cxp_transacciones_i]
	ON [dbo].[ew_cxp_transacciones]
	FOR INSERT
AS 

SET NOCOUNT ON

DECLARE
	@idtran AS BIGINT
	,@fecha AS SMALLDATETIME
	,@idu AS SMALLINT
	,@total AS DECIMAL(15,2)

IF EXISTS (
	SELECT *
	FROM
		inserted AS i
		LEFT JOIN evoluware_usuarios AS u
			ON u.idu = i.idu
	WHERE
		i.caja_chica = 1
		AND u.idcuenta = 0
)
BEGIN
	RAISERROR('Error: Se ha indicado que el movimiento es de caja chica pero el usuario no tiene caja asignada.', 16, 1)
	RETURN
END
	
--------------------------------------------------------------------------------
-- Aplicando automaticamente aquellas transacciones que no han sido programadas
--------------------------------------------------------------------------------
DECLARE cur_tg_cxp_transacciones_i CURSOR FOR
	SELECT
		i.idtran
		, i.fecha
		, i.idu
		, i.total
	FROM 
		inserted AS i
	WHERE
		i.tipo IN (1,2)
		AND i.programado = 0

OPEN cur_tg_cxp_transacciones_i

FETCH NEXT FROM cur_tg_cxp_transacciones_i INTO
	@idtran
	, @fecha
	, @idu
	, @total

WHILE @@FETCH_STATUS = 0
BEGIN
	UPDATE ew_cxp_Transacciones SET
		saldo = total
	WHERE
		idtran = @idtran

	-- aplicando la transaccion en cartera
	EXEC _cxp_prc_aplicarTransaccion @idtran, @fecha, @idu
	
	FETCH NEXT FROM cur_tg_cxp_transacciones_i INTO
		@idtran
		, @fecha
		, @idu
		, @total
END

CLOSE cur_tg_cxp_transacciones_i
DEALLOCATE cur_tg_cxp_transacciones_i
GO
