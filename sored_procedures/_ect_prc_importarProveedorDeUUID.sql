USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160606
-- Description:	Vincular proveedor usando UUID de comprobante
-- =============================================
ALTER PROCEDURE [dbo].[_ect_prc_importarProveedorDeUUID]
	@uuid AS VARCHAR(50)
AS

SET NOCOUNT ON

DECLARE
	@idcomprobante AS INT

SELECT
	@idcomprobante = ccr.idcomprobante
FROM
	ew_cfd_comprobantes_recepcion AS ccr
WHERE
	ccr.Timbre_UUID = @uuid

EXEC [dbo].[_ect_prc_importarProveedor] @idcomprobante
GO
