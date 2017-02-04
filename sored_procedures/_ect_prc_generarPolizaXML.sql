USE db_comercial_final
GO
ALTER PROCEDURE [dbo].[_ect_prc_generarPolizaXML]
	@datos AS VARCHAR(MAX) OUTPUT
	,@archivo_nombre AS VARCHAR(200) OUTPUT
	,@mes AS SMALLINT = NULL
	,@anio AS SMALLINT = NULL
AS

SET NOCOUNT ON

DECLARE
	@rfc AS VARCHAR(13)
	,@noCertificado AS VARCHAR(50)

SELECT @mes = ISNULL(@mes, MONTH(GETDATE()))
SELECT @anio = ISNULL(@anio, YEAR(GETDATE()))
SELECT @rfc = dbo.fn_sys_parametro('RFC')
SELECT TOP 1 @noCertificado = noCertificado FROM ew_cfd_certificados ORDER BY idr DESC

SELECT @datos = '<?xml version="1.0" encoding="utf-8"?>'

SELECT @datos = (
	@datos 
	+ '<PLZ:Polizas '
	+ 'Version="1.1" '
	+ 'RFC="' + @rfc + '" '
	+ 'Mes="' + dbo.fnRellenar(ISNULL(@mes, MONTH(GETDATE())), 2, '0') + '" '
	+ 'Anio="' + dbo.fnRellenar(ISNULL(@anio, YEAR(GETDATE())), 4, '0') + '" '
	+ 'TipoSolicitud="AF" ' --Atributo requerido para expresar el tipo de solicitud de la póliza ( AF - Acto de Fiscalización; FC - Fiscalización Compulsa; DE - Devolución; CO - Compensación )
	--+ 'NumOrden="CO" ' --Atributo opcional para expresar el número de orden asignado al acto de fiscalización al que hace referencia la solicitud de la póliza. Requerido para tipo de solicitud = AF y FC. Se convierte en requerido cuando se cuente con la información.
	--+ 'NumTramite="" ' --Atributo opcional para expresar el número de trámite asignado a la solicitud de devolución o compensación al que hace referencia la solicitud de la póliza. Requerido para tipo de solicitud = DE o CO. Se convierte en requerido cuando se cuente con la información.
	+ 'Sello="" '
	+ 'noCertificado="' + @noCertificado + '" '
	+ 'Certificado="" '
	+ 'xmlns:xs="http://www.w3.org/2001/XMLSchema" '
	+ 'xmlns:PLZ="www.sat.gob.mx/esquemas/ContabilidadE/1_1/PolizasPeriodo" '
	+ 'targetNamespace="www.sat.gob.mx/esquemas/ContabilidadE/1_1/PolizasPeriodo" '
	+ 'schemaLocation="http://www.sat.gob.mx/esquemas/ContabilidadE/1_1/PolizasPeriodo/PolizasPeriodo_1_1.xsd" '
	+ '>'
)

SELECT 
	@datos = (
		@datos 
		+ '<PLZ:Poliza '
		+ 'NumUnIdenPol="' + pol.folio + '" '
		+ 'Fecha="' 
		+ dbo.fnRellenar(YEAR(pol.fecha), 4, '0') 
		+ '-'
		+ dbo.fnRellenar(MONTH(pol.fecha), 2, '0') 
		+ '-'
		+ dbo.fnRellenar(DAY(pol.fecha), 2, '0') 
		+ 'T00:00:00'
		+ '" '
		+ 'Concepto="' + (CASE WHEN LEN(REPLACE(pol.concepto, ' ', '')) > 0 THEN pol.concepto ELSE 'Poliza ' + pol.folio END) + '" '
		+ '>'
		+ (
			SELECT
				'<PLZ:Transaccion '
				+ 'numCta="' + pm.cuenta + '" '
				+ 'DescCta="' + cc.nombre + '" '
				+ 'Concepto="' + pm.concepto + '" '
				+ 'Debe="' + CONVERT(VARCHAR(20), pm.cargos) + '" '
				+ 'Haber="' + CONVERT(VARCHAR(20), pm.abonos) + '" '
				
				+ (
					CASE
						WHEN pm.idtran2 NOT IN (SELECT st.idtran FROM ew_sys_transacciones AS st WHERE st.transaccion IN ('CFA1','AFA1','AFA3','BDA1','BDA2','DDA3')) AND pm.idtran2 > 0
							THEN '/>'
						ELSE
							'>'
							+ (
								SELECT
									'<PLZ:CompNal '
									+ 'UUID_CFDI="' + ISNULL(ccr.Timbre_UUID, '') + '" '
									+ 'RFC="' + p.rfc + '" '
									+ 'MontoTotal="' + CONVERT(VARCHAR(20), ct.total) + '" '
									+ 'Moneda="' + bm.nombre_corto + '" '
									+ 'TipCamb="' + CONVERT(VARCHAR(20), ct.tipocambio) + '" '
									+ '/>'
								FROM
									ew_cxp_transacciones AS ct
									LEFT JOIN ew_ban_monedas AS bm
										ON bm.idmoneda = ct.idmoneda
									LEFT JOIN ew_proveedores AS p
										ON p.idproveedor = ct.idproveedor
									LEFT JOIN ew_cfd_comprobantes_recepcion AS ccr
										ON ccr.idcomprobante = ct.idcomprobante
								WHERE
									ct.transaccion IN ('CFA1','AFA1','AFA3')
									AND ct.idtran = pm.idtran2
								FOR XML PATH('')
								--[Factura de compra]
								--CompNal
								--CompNalOtr
								--CompExt

								--[Pago a prov]
								--Cheque
								--Transferencia
								--OtrMetodoPago
							)
							+ '</PLZ:Transaccion>'
					END
				)
			FROM
				ew_ct_poliza_mov AS pm
				LEFT JOIN ew_ct_cuentas AS cc
					ON cc.cuenta = pm.cuenta
			WHERE
				pm.idtran = pol.idtran
			FOR XML PATH('')
		)
		+ '</PLZ:Poliza>'
	)
FROM
	ew_ct_poliza AS pol
WHERE
	pol.ejercicio = @anio
	AND pol.periodo = @mes

SELECT @datos = @datos + ''

SELECT @datos = @datos + '</PLZ:Polizas>'
SELECT @datos = @datos + ''

SELECT @datos = REPLACE(@datos, '&lt;', '<')
SELECT @datos = REPLACE(@datos, '&gt;', '>')

SELECT @datos = REPLACE(@datos, '&amp;lt;', '<')
SELECT @datos = REPLACE(@datos, '&amp;gt;', '>')

SELECT @archivo_nombre = ISNULL(@rfc, '') + dbo.fnRellenar(@anio, 4, '0') + dbo.fnRellenar(@mes, 2, '0') + 'PL.xml'
GO
