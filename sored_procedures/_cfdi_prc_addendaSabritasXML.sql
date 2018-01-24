USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170622
-- Description:	Addenda sabritas
-- =============================================
ALTER PROCEDURE [dbo].[_cfdi_prc_addendaSabritasXML]
	@idtran AS INT
	,@addenda AS VARCHAR(MAX) OUTPUT
AS

SET NOCOUNT ON

SELECT
	@addenda = (
		''
		+ '<cfdi:Addenda>'
		+ '<RequestCFD version="2.0" idPedido="'
		+ vt.no_orden
		+ '" tipo="AddendaPCO">'
		+ '<Documento tipoDoc="1" folioUUID="' + ISNULL(cct.cfdi_UUID, '') + '"/>'
		+ '<Proveedor idProveedor="1000084761"/>'
		+ '<Recepciones>'
		+ '<Recepcion idRecepcion="' + vt.no_recepcion + '">'
		
	)
FROM
	ew_ven_transacciones AS vt
	LEFT JOIN ew_cfd_comprobantes_timbre AS cct
		ON cct.idtran = vt.idtran
WHERE
	vt.idtran = @idtran
	
SELECT
	@addenda = (
		@addenda 
		+ '<Concepto '
		+'unidad="' + ccm.cfd_unidad + '" '
		+'descripcion="' + REPLACE(ccm.cfd_descripcion, '"', '&quot;') + '" '
		+'cantidad="' + CONVERT(VARCHAR(20), ccm.cfd_cantidad) + '" '
		+'valorUnitario="' + CONVERT(VARCHAR(20), ccm.cfd_valorUnitario) + '" '
		+'importe="' + CONVERT(VARCHAR(20), ccm.cfd_importe) + '" '
		+'/>'
	)
FROM
	ew_cfd_comprobantes_mov AS ccm
WHERE
	ccm.idtran = @idtran
	
SELECT
	@addenda = (
		@addenda
		+ '</Recepcion>'
		+ '</Recepciones>'
		+ '</RequestCFD>'
		+ '</cfdi:Addenda>'
	)
GO
