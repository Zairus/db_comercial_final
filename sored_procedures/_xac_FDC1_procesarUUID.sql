USE db_comercial_final
GO
IF OBJECT_ID('_xac_FDC1_procesarUUID') IS NOT NULL
BEGIN
	DROP PROCEDURE _xac_FDC1_procesarUUID
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200213
-- Description:	Crear estructura en ew_cfd_comprobantes a partir de UUID capturado
-- =============================================
CREATE PROCEDURE [dbo].[_xac_FDC1_procesarUUID]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@uuid AS UNIQUEIDENTIFIER

SELECT
	@uuid = uuid
FROM
	ew_cxc_transacciones AS ct
WHERE
	ct.idtran = @idtran
	AND LEN(ct.uuid) > 0

IF @uuid IS NULL
BEGIN
	RETURN
END

INSERT INTO ew_cfd_comprobantes (
	idtran
	, idsucursal
	, idestado
	, idfolio
	, cfd_version
	, cfd_fecha
	, cfd_folio
	, cfd_serie
	, cfd_noCertificado
	, cfd_formaDePago
	, cdf_condicionesDePago
	, cfd_subTotal
	, cfd_total
	, cfd_metodoDePago
	, cfd_tipoDeComprobante
	, rfc_emisor
	, rfc_receptor
	, receptor_nombre
	, xcfd_noAprobacion
	, xcfd_anoAprobacion
	, cfd_Moneda
	, cfd_TipoCambio
	, comentario
	, idtran2
	, cfd_NumCtaPago
	, cfd_uso
)
SELECT
	[idtran] = ct.idtran
	, [idsucursal] = ct.idsucursal
	, [idestado] = 0
	, [idfolio] = 0
	, [cfd_version] = '3.2'
	, [cfd_fecha] = ct.fecha
	, [cfd_folio] = 0
	, [cfd_serie] = ''
	, [cfd_noCertificado] = ''
	, [cfd_formaDePago] = 'PUE'
	, [cdf_condicionesDePago] = 'CONTADO'
	, [cfd_subTotal] = ct.subtotal
	, [cfd_total] = ct.total
	, [cfd_metodoDePago] = '01'
	, [cfd_tipoDeComprobante] = 'I'
	, [rfc_emisor] = e_cfa.rfc
	, [rfc_receptor] = c.rfc
	, [receptor_nombre] = c.razon_social
	, [xcfd_noAprobacion] = 0
	, [xcfd_anoAprobacion] = 0
	, [cfd_Moneda] = 'MXP'
	, [cfd_TipoCambio] = 1
	, [comentario] = ''
	, [idtran2] = 0
	, [cfd_NumCtaPago] = ''
	, [cfd_uso] = '03'
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_clientes_facturacion AS e_cfa
		ON e_cfa.idcliente = 0
		AND e_cfa.idfacturacion = 0
	LEFT JOIN vew_clientes AS c
		ON c.idcliente = ct.idcliente
WHERE
	ct.idtran = @idtran

INSERT INTO ew_cfd_comprobantes_timbre (
	idtran
	, cfdi_FechaTimbrado
	, cfdi_versionTFD
	, cfdi_UUID
	, cfdi_noCertificadoSAT
	, cfdi_selloDigital
	, cfdi_cadenaOriginal
	, QRCode
	, cfdi_fechaCancelacion
	, cfdi_respuesta_codigo
	, cfdi_respuesta_mensaje
	, cfdi_prueba
)
SELECT
	[idtran] = ct.idtran
	, [cfdi_FechaTimbrado] = ct.fecha
	, [cfdi_versionTFD] = '1.1'
	, [cfdi_UUID] = ct.uuid
	, [cfdi_noCertificadoSAT] = ''
	, [cfdi_selloDigital] = ''
	, [cfdi_cadenaOriginal] = ''
	, [QRCode] = ''
	, [cfdi_fechaCancelacion] = ''
	, [cfdi_respuesta_codigo] = ''
	, [cfdi_respuesta_mensaje] = ''
	, [cfdi_prueba] = ''
FROM
	ew_cxc_transacciones AS ct
WHERE
	ct.idtran = @idtran
GO
