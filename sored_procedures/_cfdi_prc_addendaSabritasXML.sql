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

DECLARE
	@addenda_xml AS XML

SELECT
	@addenda_xml = g.XML
FROM (
	SELECT
		'2.0' AS '@version'
		, vt.no_orden AS '@idPedido'
		, 'AddendaPCO' AS '@tipo'
		,(
			SELECT
				'1' AS '@tipoDoc'
				,ISNULL(cct.cfdi_UUID, '') AS '@folioUUID'
			FOR XML PATH('Documento'), TYPE
		) AS '*'
		,(
			SELECT
				'1000084761' AS '@idProveedor'
			FOR XML PATH('Proveedor'), TYPE
		) AS '*'
		,(
			SELECT
				(
					SELECT
						vt.no_recepcion AS '@idRecepcion'
					FOR XML PATH('Recepcion'), TYPE
				) AS '*'
				,(
					SELECT
						ccm.cfd_unidad AS '@unidad'
						, REPLACE(ccm.cfd_descripcion, '"', '&quot;') AS '@descripcion'
						, CONVERT(VARCHAR(20), ccm.cfd_cantidad) AS '@cantidad'
						, CONVERT(VARCHAR(20), ccm.cfd_valorUnitario) AS '@valorUnitario'
						, CONVERT(VARCHAR(20), ccm.cfd_importe) AS '@importe'
					FROM
						ew_cfd_comprobantes_mov AS ccm
					WHERE
						ccm.idtran = vt.idtran
					FOR XML PATH('Concepto'), TYPE
				) AS '*'
			FOR XML PATH('Recepciones'), TYPE
		) AS '*'
	FROM
		ew_ven_transacciones AS vt
		LEFT JOIN ew_cfd_comprobantes_timbre AS cct
			ON cct.idtran = vt.idtran
	WHERE
		vt.idtran = @idtran
	FOR XML PATH('RequestCFD'), TYPE
) AS g(XML)

SELECT @addenda = '<cfdi:Addenda>' + CONVERT(VARCHAR(MAX), @addenda_xml) + '</cfdi:Addenda>'
GO
