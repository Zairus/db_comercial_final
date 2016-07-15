USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160616
-- Description:	Impuestos de comprobante XML
-- =============================================
ALTER PROCEDURE _ect_rpt_comprobanteRecepcion_impuestos
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

SELECT
	ccri.idcomprobante
	,[tipo] = (CASE WHEN ccri.tipo = 0 THEN 'Traslado' ELSE 'Retencion' END)
	,ccri.impuesto
	,ccri.tasa
	,ccri.importe
FROM 
	ew_cfd_comprobantes_recepcion_impuestos AS ccri
WHERE 
	ccri.idcomprobante = @idcomprobante
GO
