USE db_comercial_final
GO
-- ==========================================================================================
-- Autor:		Laurence Saavedra
-- Fecha:		2010-02
-- Descripcion: Trigger que se encarga de cerrar automaticamente la transaccion en cartera
-- ==========================================================================================
ALTER TRIGGER [dbo].[tg_cxp_transacciones_u]
	ON [dbo].[ew_cxp_transacciones]
	AFTER UPDATE
AS 

SET NOCOUNT ON

DECLARE
	@idtran AS BIGINT
	,@idu AS INT

IF UPDATE(saldo)
BEGIN
	--------------------------------------------------------------------------------
	-- Cerrando automaticamente las transacciones que lo indican
	--------------------------------------------------------------------------------
	DECLARE cur_tg_cxp_transacciones_u CURSOR FOR
		SELECT
			i.idtran
		FROM 
			inserted i
			LEFT JOIN deleted d ON d.idr=i.idr
			LEFT JOIN ew_sys_transacciones t ON t.idtran=i.idtran
		WHERE
			i.tipo IN (1,2)
			AND i.cancelado = 0
			AND i.aplicado = 1
			AND (
				i.saldo = 0 
				AND d.saldo > 0
			)
			AND i.cierre_automatico = 1
			AND t.idestado < 251

	OPEN cur_tg_cxp_transacciones_u

	FETCH NEXT FROM cur_tg_cxp_transacciones_u INTO
		@idtran

	WHILE @@FETCH_STATUS=0
	BEGIN
		SELECT TOP 1
			@idu = idu
		FROM
			ew_cxp_transacciones_mov AS ctm
		WHERE
			ctm.idtran2 = @idtran
		ORDER BY
			ctm.fechahora DESC

		SELECT @idu = ISNULL(@idu, dbo._sys_fnc_usuario())

		-- Cerrando la transaccion
		INSERT INTO ew_sys_transacciones2	
			(idtran, idestado, idu)
		VALUES
			(@idtran, dbo.fn_sys_estadoID('CERR'), @idu)
		
		FETCH NEXT FROM cur_tg_cxp_transacciones_u INTO
			@idtran
	END

	CLOSE cur_tg_cxp_transacciones_u
	DEALLOCATE cur_tg_cxp_transacciones_u
	
	--------------------------------------------------------------------------------
	-- Abriendo automaticamente las transacciones cerradas
	--------------------------------------------------------------------------------
	DECLARE cur_tg_cxp_transacciones_u CURSOR FOR
		SELECT
			i.idtran
		FROM 
			inserted i
			LEFT JOIN deleted AS d 
				ON d.idr = i.idr
			LEFT JOIN ew_sys_transacciones AS t 
				ON t.idtran = i.idtran
		WHERE
			i.tipo IN (1,2)
			AND i.cancelado = 0
			AND i.aplicado = 1
			AND (
				i.saldo > 0 
				AND d.saldo = 0
			)
			AND t.idestado = 251

	OPEN cur_tg_cxp_transacciones_u

	FETCH NEXT FROM cur_tg_cxp_transacciones_u INTO
		@idtran

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT TOP 1
			@idu = idu
		FROM
			ew_cxp_transacciones_mov AS ctm
		WHERE
			ctm.idtran2 = @idtran
		ORDER BY
			ctm.fechahora DESC

		SELECT @idu = ISNULL(@idu, dbo._sys_fnc_usuario())

		-- Abriendo la transaccion
		INSERT INTO ew_sys_transacciones2	
			(idtran, idestado, idu)
		VALUES
			(@idtran, dbo.fn_sys_estadoID('CER~'), @idu)
		
		FETCH NEXT FROM cur_tg_cxp_transacciones_u INTO
			@idtran
	END

	CLOSE cur_tg_cxp_transacciones_u
	DEALLOCATE cur_tg_cxp_transacciones_u	
END
GO