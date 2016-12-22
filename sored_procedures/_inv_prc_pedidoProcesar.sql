USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110505
-- Description:	Procesar pedido de sucursal
-- =============================================
ALTER PROCEDURE [dbo].[_inv_prc_pedidoProcesar]
	@idtran AS INT
	,@idu AS INT
AS

SET NOCOUNT ON

DECLARE
	 @idestado AS INT
	,@cantidad_solicitada AS DECIMAL(18,6)
	,@cantidad_surtida AS DECIMAL(18,6)

SELECT
	@idestado = idestado
FROM
	ew_sys_transacciones AS st
WHERE
	st.idtran = @idtran

SELECT
	@cantidad_solicitada = SUM(solicitado)
FROM
	ew_inv_documentos_mov
WHERE
	idtran = @idtran

SELECT @cantidad_solicitada = ISNULL(@cantidad_solicitada, 0)

SELECT
	@cantidad_surtida = SUM(surtido)
FROM
	ew_inv_documentos_mov
WHERE
	idtran = @idtran

SELECT @cantidad_surtida = ISNULL(@cantidad_surtida, 0)

IF @cantidad_surtida > 0
BEGIN
	IF @cantidad_solicitada <> @cantidad_surtida
	BEGIN
		RAISERROR('Error: La cantidad surtida es diferente a la cantidad solicitada.', 16, 1)
		RETURN
	END
END

IF @idestado = 0
BEGIN
	IF @cantidad_surtida > 0
	BEGIN
		INSERT INTO ew_sys_transacciones2
			(idtran, idestado, idu)
		VALUES
			(@idtran, 44, @idu)
	END
END
GO
