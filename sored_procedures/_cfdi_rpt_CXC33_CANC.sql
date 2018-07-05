USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180704
-- Description:	Formato de impresion acuse de cancelacion CXC
-- =============================================
ALTER PROCEDURE _cfdi_rpt_CXC33_CANC
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@acuse_xml AS XML

SELECT
	@acuse_xml = ccc.acuse
FROM
	ew_cfd_comprobantes_cancelados AS ccc
WHERE
	ccc.idtran = @idtran

;WITH XMLNAMESPACES ( 
	'http://www.w3.org/2000/09/xmldsig#' AS ns2
	,'http://cancelacfd.sat.gob.mx' AS ns3
)
SELECT 
	cc.idtran

	,[fecha] = @acuse_xml.value('(/Acuse/@Fecha)[1]', 'DATETIME')
	,[uuid] = @acuse_xml.value('(/Acuse/ns3:Folios/ns3:UUID)[1]', 'VARCHAR(100)')
	,[digest] = @acuse_xml.value('(/Acuse/ns2:Signature/ns2:SignedInfo/ns2:Reference/ns2:DigestValue)[1]', 'VARCHAR(MAX)')
	,[signature] = @acuse_xml.value('(/Acuse/ns2:Signature/ns2:KeyInfo/ns2:KeyValue/ns2:RSAKeyValue/ns2:Modulus)[1]', 'VARCHAR(MAX)')
	,[exponent] = @acuse_xml.value('(/Acuse/ns2:Signature/ns2:KeyInfo/ns2:KeyValue/ns2:RSAKeyValue/ns2:Exponent)[1]', 'VARCHAR(50)')

	,[emisor_rfc] = @acuse_xml.value('(/Acuse/@RfcEmisor)[1]', 'VARCHAR(20)')
	,[emisor_direccion] = (
		ISNULL(e.calle, '')
		+ ' ' + ISNULL(e.noExterior, '')
		+ ' ' + ISNULL(e.colonia, '')
		+ ' ' + ISNULL(e.codpostal, '')
		+ ' ' + ISNULL(ecd.ciudad + ', ' + ecd.estado, '')
	)
	
	,[documento_folio] = cc.cfd_serie + LTRIM(RTRIM(STR(cc.cfd_folio)))
	,[documento_fecha] = ct.fecha
	,[documento_fecha_timbrado] = cct.cfdi_FechaTimbrado
	,[cliente] = ISNULL(c.razon_social, ISNULL(c.nombre, '-Sin Nombre-'))
	,[cliente_codigo] = c.codigo
	,[cliente_rfc] = c.rfc
	,[cliente_direccion] = (
		ISNULL(c.calle, '')
		+ ' ' + ISNULL(c.noExterior, '')
		+ ' ' + ISNULL(c.colonia, '')
		+ ' ' + ISNULL(c.codpostal, '')
		+ ' ' + ISNULL(ccd.ciudad + ', ' + ccd.estado, '')
	)
	,[movimiento_cancelado] = (
		CASE 
			WHEN o.codigo LIKE 'EFA%' THEN 'Factura de Venta' 
			ELSE o.nombre 
		END
	)
FROM
	ew_cfd_comprobantes AS cc
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = cc.idtran
	LEFT JOIN vew_clientes AS e
		ON e.idcliente = 0
	LEFT JOIN ew_sys_ciudades AS ecd
		ON ecd.idciudad = e.idciudad
	LEFT JOIN vew_clientes AS c
		ON c.idcliente = ct.idcliente
	LEFT JOIN ew_sys_ciudades AS ccd
		ON ccd.idciudad = c.idciudad
	LEFT JOIN ew_cfd_comprobantes_timbre As cct
		ON cct.idtran = cc.idtran
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
WHERE
	cc.idtran = @idtran
GO
