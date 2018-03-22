USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 200912
-- Description:	Procesar orden de venta
-- Modificado Por: Tere Valdez 20091217 	
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_ordenProcesar]
	@idtran AS INT
	,@idu AS INT
AS

SET NOCOUNT ON

EXEC [dbo].[_ven_prc_existenciaComprometer]

EXEC [dbo].[_ven_prc_ordenValidar] @idtran, @idu

EXEC [dbo].[_sys_prc_genera_consecutivo] @idtran, ''

EXEC [dbo].[_ven_prc_ordenProcesarImpuestos] @idtran
GO
