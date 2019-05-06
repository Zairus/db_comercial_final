USE db_comercial_final
GO
IF OBJECT_ID('_ban_prc_bdt2_cancelar') IS NOT NULL
BEGIN
	DROP PROCEDURE _ban_prc_bdt2_cancelar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190430
-- Description:	Procesar integracion de deposito ventas
-- =============================================
CREATE PROCEDURE [dbo].[_ban_prc_bdt2_cancelar]
	@idtran AS INT
	, @idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@pass VARCHAR(100)
	, @cargo_idtran AS INT
	, @abono_idtran AS INT
	, @cancelado_fecha AS DATETIME

SELECT 
	@cancelado_fecha = fecha 
FROM 
	ew_ban_documentos 
WHERE 
	idtran = @idtran

SELECT
	@cargo_idtran = idtran
FROM
	ew_ban_transacciones
WHERE
	tipo = 1
	AND idtran2 = @idtran

SELECT
	@abono_idtran = idtran
FROM
	ew_ban_transacciones
WHERE
	tipo = 2
	AND idtran2 = @idtran

UPDATE ew_ban_documentos SET
	cancelado = 1
	, cancelado_fecha = fecha
WHERE
	idtran = @idtran

IF @cargo_idtran IS NOT NULL
BEGIN
	EXEC _ban_prc_cancelarTransaccion @cargo_idtran, @cancelado_fecha, @idu, 1, 1
END

IF @abono_idtran IS NOT NULL
BEGIN
	EXEC _ban_prc_cancelarTransaccion @abono_idtran, @cancelado_fecha, @idu, 1, 1
END

EXEC _ct_prc_transaccionCancelarContabilidad
	@idtran
	, 1
	, @cancelado_fecha
	, @idu
GO
