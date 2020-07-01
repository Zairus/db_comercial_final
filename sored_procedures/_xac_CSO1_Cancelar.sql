USE db_comercial_final
GO
IF OBJECT_ID('_xac_CSO1_Cancelar') IS NOT NULL
BEGIN
	DROP PROCEDURE _xac_CSO1_Cancelar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200414
-- Description:	Cancelar requisición de compras
-- =============================================
CREATE PROCEDURE [dbo].[_xac_CSO1_Cancelar]
	@idtran AS INT
	, @cancelado_fecha AS DATETIME
AS

SET NOCOUNT ON

UPDATE ew_com_documentos SET
	cancelado = 1
	, cancelado_fecha = @cancelado_fecha
WHERE 
	cancelado = 0
	AND idtran = @idtran
GO
