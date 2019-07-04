USE db_comercial_final
GO
IF OBJECT_ID('_cxc_prc_fdc1_cancelar') IS NOT NULL
BEGIN
	DROP PROCEDURE _cxc_prc_fdc1_cancelar
END
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Cancelar cargo a cliente
-- =============================================
CREATE PROCEDURE [dbo].[_cxc_prc_fdc1_cancelar]
	@idtran AS INT
	, @idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@bancos_idtran AS INT
	, @cancelado_fecha AS DATETIME
	, @desaplicar_referencias AS BIT = 0
	, @forzar AS BIT = 0

SELECT
	@cancelado_fecha = ct.fecha
	, @idu = ct.idu
FROM
	ew_cxc_transacciones AS ct
WHERE
	ct.idtran = @idtran

SELECT
	@bancos_idtran
FROM
	ew_ban_transacciones AS bt
WHERE
	bt.idtran2 = @idtran

EXEC _cxc_prc_cancelarTransaccion
	@idtran
	, @cancelado_fecha
	, @idu

IF @bancos_idtran IS NOT NULL
BEGIN
	EXEC _ban_prc_cancelarTransaccion
		@idtran
		, @cancelado_fecha
		, @idu
		, @desaplicar_referencias
		, @forzar
END
GO
