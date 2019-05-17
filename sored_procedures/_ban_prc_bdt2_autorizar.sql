USE db_comercial_final
GO
IF OBJECT_ID('_ban_prc_bdt2_autorizar') IS NOT NULL
BEGIN
	DROP PROCEDURE _ban_prc_bdt2_autorizar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190430
-- Description:	Procesar integracion de deposito ventas
-- =============================================
CREATE PROCEDURE [dbo].[_ban_prc_bdt2_autorizar]
	@idtran AS INT
	, @idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@fecha AS DATETIME

SELECT
	@fecha = fecha
FROM
	ew_ban_documentos AS bd
WHERE
	bd.idtran = @idtran

EXEC [dbo].[_ban_prc_traspasoProcesar] @idtran, @fecha, @idu

EXEC [dbo].[_ban_prc_bdt2_contabilizar] @idtran
GO
