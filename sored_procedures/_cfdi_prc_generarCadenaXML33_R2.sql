USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170903
-- Description:	Generar Cadena XML CFDi 3.3
-- =============================================
ALTER PROCEDURE [dbo].[_cfdi_prc_generarCadenaXML33_R2]
	@idtran AS INT
	, @comprobante AS VARCHAR(MAX) OUTPUT
AS

SET NOCOUNT ON

DECLARE
	@xml AS XML

DECLARE
	@cfd_fecha AS DATETIME = GETDATE()
	, @namespace_text AS VARCHAR(MAX) = ''
	, @schema_location AS VARCHAR(MAX) = ''

CREATE TABLE #_tmp_ns (
	codigo VARCHAR(50)
)

INSERT INTO #_tmp_ns (codigo) VALUES ('xsi'), ('cfdi')

INSERT INTO #_tmp_ns (codigo) 
SELECT
	[codigo] = 'pago10'
FROM
	ew_cfd_comprobantes AS ccp
WHERE
	ccp.cfd_tipoDeComprobante = 'P'
	AND ccp.idtran = @idtran

SELECT
	@cfd_fecha = cc.cfd_fecha
FROM
	ew_cfd_comprobantes AS cc
WHERE
	cc.idtran = @idtran

SELECT
	@schema_location = @schema_location + xmlns.uri + ' ' + xmlns.xsd + ' '
FROM
	db_comercial.dbo.evoluware_cfd_sat_xmlnamespace AS xmlns
WHERE
	(LEN(xmlns.uri) > 0 AND LEN(xmlns.xsd) > 0)
	AND xmlns.codigo IN (SELECT tns.codigo FROM #_tmp_ns AS tns)

SELECT @schema_location = REPLACE(@schema_location, '  ', ' ')
SELECT @schema_location = LTRIM(RTRIM(@schema_location))

;WITH XMLNAMESPACES ( 
	'http://www.sat.gob.mx/cfd/3' AS cfdi
	, 'http://www.sat.gob.mx/Pagos' AS pago10
	, 'http://www.w3.org/2001/XMLSchema-instance' AS xsi 
)
SELECT
	@xml = g.XML
FROM (
	SELECT
		@schema_location AS '@xsi:schemaLocation'
		, '3.3' AS '@Version'
		, cc.cfd_serie AS '@Serie'
		, CONVERT(VARCHAR(15), cc.cfd_folio) AS '@Folio'
		, CONVERT(VARCHAR(19), @cfd_fecha, 126) AS '@Fecha'
		, cer.noCertificado AS '@NoCertificado'
		, REPLACE(REPLACE(cc.cfd_tipoDeComprobante, 'ingreso', 'I'), 'egreso', 'E') AS '@TipoDeComprobante'
		, NULL AS '@CondicionesDePago' --(CASE WHEN cc.cdf_condicionesDePago = '' THEN NULL ELSE cc.cdf_condicionesDePago END)
		, ISNULL(s.codpostal, '83000') AS '@LugarExpedicion'
		, (CASE WHEN cc.cfd_tipoDeComprobante = 'P' THEN 'XXX' ELSE cc.cfd_Moneda END) AS '@Moneda'
		, (CASE WHEN cc.cfd_tipoDeComprobante = 'P' THEN NULL ELSE dbo._sys_fnc_decimales(cc.cfd_TipoCambio, (CASE WHEN cc.cfd_Moneda = 'MXN' THEN 0 ELSE 6 END)) END) AS '@TipoCambio'
		, (CASE WHEN cc.cfd_tipoDeComprobante = 'P' THEN '0' ELSE dbo._sys_fnc_decimales(cc.cfd_subtotal, csm.decimales) END) AS '@SubTotal'
		
		, (
			CASE 
				WHEN cc.cfd_tipoDeComprobante = 'P' THEN '0' 
				ELSE dbo._sys_fnc_decimales(
					(
						ROUND(cc.cfd_subtotal, 2)
						+ ROUND(ISNULL((
							SELECT 
								SUM(cci.cfd_importe) 
							FROM 
								ew_cfd_comprobantes_impuesto AS cci
							WHERE 
								cci.cfd_ambito = 0
								AND cci.idtipo = 1
								AND cci.idtran = cc.idtran
						), 0), 2)
						- ROUND(ISNULL((
							SELECT 
								SUM(cci.cfd_importe) 
							FROM 
								ew_cfd_comprobantes_impuesto AS cci
							WHERE 
								cci.cfd_ambito = 0
								AND cci.idtipo = 2
								AND cci.idtran = cc.idtran
						), 0), 2)
					)
					, csm.decimales
				) 
			END
		) AS '@Total'

		, (CASE WHEN cc.cfd_tipoDeComprobante NOT IN ('P') THEN cc.cfd_metodoDePago ELSE NULL END) AS '@FormaPago'
		, (CASE WHEN cc.cfd_tipoDeComprobante NOT IN ('P') THEN cc.cfd_formaDePago ELSE NULL END) AS '@MetodoPago'
		, dbEVOLUWARE.dbo.base64_read(cer.certificado) AS '@Certificado'
		
		--CfdiRelacionados
		, (
			SELECT
				ccdr1.tiporelacion AS '@TipoRelacion'
				, (
					SELECT
						ccdr2.cfdi_UUID AS '@UUID'
					FROM
						ew_cfd_comprobantes_documentos_relacionados AS ccdr2
					WHERE
						ccdr2.idtran = cc.idtran
						AND ccdr2.tiporelacion = ccdr1.tiporelacion
					FOR XML PATH('cfdi:CfdiRelacionado'), TYPE
				)
			FROM
				(
					SELECT DISTINCT
						ccdr.tiporelacion
					FROM
						ew_cfd_comprobantes_documentos_relacionados AS ccdr
					WHERE
						ccdr.idtran = cc.idtran
				) AS ccdr1
			FOR XML PATH('cfdi:CfdiRelacionados'), TYPE
		) AS '*'

		--Emisor
		, (
			SELECT
				cc.rfc_emisor AS '@Rfc'
				,emisor_rfc.cfd_nombre AS '@Nombre'
				,[dbo].[_sys_fnc_parametroTexto]('CFDI_REGIMEN') AS '@RegimenFiscal'
			FOR XML PATH('cfdi:Emisor'), TYPE
		) AS '*'

		--Receptor
		, (
			SELECT
				cc.rfc_receptor AS '@Rfc'
				,(
					CASE 
						WHEN LEN(receptor_rfc.cfd_nombre) = 0 THEN NULL 
						ELSE receptor_rfc.cfd_nombre 
					END
				) AS '@Nombre'
				,NULL AS '@ResidenciaFiscal' --ISNULL(csat_p.c_pais, 'MEX')
				,cc.cfd_uso AS '@UsoCFDI'
			FOR XML PATH('cfdi:Receptor'), TYPE
		) AS '*'
		
		--Conceptos
		, (
			SELECT
				csc.clave AS '@ClaveProdServ'
				, (
					CASE
						WHEN cc.cfd_tipoDeComprobante = 'P' THEN NULL
						ELSE (
							(
								CASE 
									WHEN ccm.cfd_noIdentificacion = '' THEN a.codigo 
									ELSE ccm.cfd_noIdentificacion 
								END
							)
						)
					END
				) AS '@NoIdentificacion'
				, (
					CASE
						WHEN cc.cfd_tipoDeComprobante = 'P' THEN '1'
						ELSE CONVERT(VARCHAR(20), ccm.cfd_cantidad)
					END
				) AS '@Cantidad'
				,ISNULL(um.sat_unidad_clave, 'EA') AS '@ClaveUnidad'
				, (
					CASE
						WHEN cc.cfd_tipoDeComprobante = 'P' THEN NULL
						ELSE ccm.cfd_unidad
					END
				) AS '@Unidad'
				,ccm.cfd_descripcion AS '@Descripcion'
				, (
					CASE
						WHEN cc.cfd_tipoDeComprobante = 'P' THEN '0'
						ELSE dbo._sys_fnc_decimales(ccm.cfd_valorUnitario, 2)
					END
				) AS '@ValorUnitario'
				, (
					CASE
						WHEN cc.cfd_tipoDeComprobante = 'P' THEN '0'
						ELSE dbo._sys_fnc_decimales(ccm.cfd_importe, csm.decimales)
					END
				) AS '@Importe'
				--,ccm.cfd_descuento AS '@Descuento'
				
				--Impuestos por conceptos
				, (
					SELECT
						(
							SELECT
								dbo._sys_fnc_decimales(
									(
										CASE
											WHEN cmi.importe = 0 THEN 
												cmi.base
											ELSE
												CONVERT(DECIMAL(15,2), 
													cmi.importe
													/ ISNULL(cit.tasa, ci.valor)
												)
										END
									)
									, csm.decimales
								) AS '@Base'
								,ISNULL(csi.c_impuesto, '002') AS '@Impuesto'
								,'Tasa' AS '@TipoFactor'
								,dbo._sys_fnc_decimales(
									ISNULL(cit.tasa, ci.valor)
									, 6
								) AS '@TasaOCuota'
								,dbo._sys_fnc_decimales(cmi.importe, csm.decimales) AS '@Importe'
							FROM
								ew_cfd_comprobantes_mov_impuesto AS cmi
								LEFT JOIN ew_ven_transacciones_mov AS vtm
									ON vtm.idmov = cmi.idmov2
								LEFT JOIN ew_cat_impuestos_tasas AS cit
									ON cit.idtasa = cmi.idtasa
								LEFT JOIN ew_cat_impuestos AS ci
									ON ci.idimpuesto = cmi.idimpuesto
								LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_impuesto AS csi
									ON csi.descripcion = ci.nombre
							WHERE
								ISNULL(cit.tipo, ci.tipo) = 1
								AND cmi.idtran = @idtran
								AND cmi.idmov2 = ccm.idmov2
							FOR XML PATH ('cfdi:Traslado'), TYPE
						) AS 'cfdi:Traslados'
						,(
							SELECT
								dbo._sys_fnc_decimales(cmi.base, csm.decimales) AS '@Base'
								,ISNULL(csi.c_impuesto, '002') AS '@Impuesto'
								,'Tasa' AS '@TipoFactor'
								,dbo._sys_fnc_decimales(ISNULL(cit.tasa, ci.valor), 6) AS '@TasaOCuota'
								,dbo._sys_fnc_decimales(cmi.importe, csm.decimales) AS '@Importe'
							FROM
								ew_cfd_comprobantes_mov_impuesto AS cmi
								LEFT JOIN ew_cat_impuestos_tasas AS cit
									ON cit.idtasa = cmi.idtasa
								LEFT JOIN ew_cat_impuestos AS ci
									ON ci.idimpuesto = cmi.idimpuesto
								LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_impuesto AS csi
									ON csi.descripcion = ci.nombre
							WHERE
								ISNULL(cit.tipo, ci.tipo) = 2
								AND cmi.idtran = @idtran
								AND cmi.idmov2 = ccm.idmov2
							FOR XML PATH ('cfdi:Retencion'), TYPE
						) AS 'cfdi:Retenciones'
					WHERE
						(
							SELECT COUNT(*) 
							FROM 
								ew_cfd_comprobantes_mov_impuesto AS ccmi 
							WHERE 
								ccmi.idtran = cc.idtran 
								AND ccmi.idmov2 = ccm.idmov2
								AND (
									ccmi.importe > 0
									OR ct.transaccion NOT IN ('FDA2')
								)
						) > 0
					FOR XML PATH ('cfdi:Impuestos'), TYPE
				) AS '*'

				--Partes
				, (
					SELECT
						csc.clave AS '@ClaveProdServ'
						,(CASE WHEN ccmp.cfd_noIdentificacion = '' THEN NULL ELSE ccmp.cfd_noIdentificacion END) AS '@NoIdentificacion'
						,ccmp.cfd_cantidad AS '@Cantidad'
						,NULL AS '@ClaveUnidad'
						,(
							CASE
								WHEN cc.cfd_tipoDeComprobante = 'P' THEN NULL
								ELSE ccm.cfd_unidad
							END
						) AS '@Unidad'
						,ccmp.cfd_descripcion AS '@Descripcion'
						,dbo._sys_fnc_decimales(ccmp.cfd_valorUnitario, csm.decimales) AS '@ValorUnitario'
						,dbo._sys_fnc_decimales(ccmp.cfd_importe, csm.decimales) AS '@Importe'
						,NULL AS '@Descuento'
					FROM
						ew_cfd_comprobantes_mov AS ccmp
					WHERE
						ccmp.consecutivo_padre = ccm.consecutivo
						AND ccmp.idtran = ccm.idtran
					FOR XML PATH ('cfdi:Parte'), TYPE
				) AS '*'
			FROM
				ew_cfd_comprobantes_mov AS ccm
				LEFT JOIN ew_ven_transacciones_mov AS vtm
					ON vtm.idmov = ccm.idmov2
				LEFT JOIN ew_articulos AS a0
					ON a0.idarticulo = ccm.idarticulo
				LEFT JOIN ew_articulos AS a
					ON a.idarticulo = ISNULL(a0.idarticulo, vtm.idarticulo)
				LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_clasificaciones AS csc
					ON csc.idclasificacion = a.idclasificacion_sat
				LEFT JOIN ew_cat_unidadesMedida AS um
					ON um.idum = a.idum_venta
			WHERE
				ccm.consecutivo_padre = 0
				AND ccm.idtran = cc.idtran
			FOR XML PATH('cfdi:Concepto'), TYPE
		) AS 'cfdi:Conceptos'
		
		--Impuestos
		, (
			SELECT
				(
					CASE
						WHEN cc.cfd_tipoDeComprobante = 'P' THEN
							'0'
						ELSE
							dbo._sys_fnc_decimales(
								(
									SELECT 
										SUM(cci.cfd_importe) 
									FROM 
										ew_cfd_comprobantes_impuesto AS cci
									WHERE 
										cci.cfd_ambito = 0
										AND cci.idtipo = 2
										AND cci.idtran = cc.idtran
								)
								,csm.decimales
							)
					END
				) AS '@TotalImpuestosRetenidos'
				, (
					CASE
						WHEN cc.cfd_tipoDeComprobante = 'P' THEN
							'0'
						ELSE
							dbo._sys_fnc_decimales(
								(
									SELECT 
										SUM(cci.cfd_importe) 
									FROM 
										ew_cfd_comprobantes_impuesto AS cci
									WHERE 
										cci.cfd_ambito = 0
										AND cci.idtipo = 1
										AND cci.idtran = cc.idtran
								)
								,csm.decimales
							)
					END
				) AS '@TotalImpuestosTrasladados'
				, (
					SELECT
						ISNULL(csi.c_impuesto, '002') AS '@Impuesto'
						,dbo._sys_fnc_decimales(SUM(cci.cfd_importe), csm.decimales) AS '@Importe'
					FROM
						ew_cfd_comprobantes_impuesto AS cci 
						LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_impuesto AS csi
							ON csi.descripcion = cci.cfd_impuesto
					WHERE
						cci.cfd_ambito = 0
						AND cci.idtipo = 2
						AND cci.idtran = cc.idtran
					GROUP BY
						ISNULL(csi.c_impuesto, '002')
					FOR XML PATH('cfdi:Retencion'), TYPE
				) AS 'cfdi:Retenciones'
				, (
					SELECT
						ISNULL(csi.c_impuesto, '002') AS '@Impuesto'
						,'Tasa' AS '@TipoFactor' --Tasa; Cuota; Exento
						,dbo._sys_fnc_decimales((cci.cfd_tasa / 100.00), 6) AS '@TasaOCuota'
						,dbo._sys_fnc_decimales(SUM(cci.cfd_importe), csm.decimales) AS '@Importe'
					FROM
						ew_cfd_comprobantes_impuesto AS cci 
						LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_impuesto AS csi
							ON csi.descripcion = cci.cfd_impuesto
					WHERE
						cci.cfd_ambito = 0
						AND cci.idtipo = 1
						AND cci.idtran = cc.idtran
					GROUP BY
						ISNULL(csi.c_impuesto, '002')
						,cci.cfd_tasa
					FOR XML PATH('cfdi:Traslado'), TYPE
				) AS 'cfdi:Traslados'
			WHERE 
				cc.cfd_tipoDeComprobante NOT IN ('P')
				AND (
					SELECT COUNT(*)
					FROM
						ew_cfd_comprobantes_impuesto AS cci 
							LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_impuesto AS csi
								ON csi.descripcion = cci.cfd_impuesto
						WHERE
							cci.cfd_ambito = 0
							AND cci.idtran = cc.idtran
				) > 0
			FOR XML PATH ('cfdi:Impuestos'), TYPE
		) AS '*'
		
		, (
			SELECT
				(
					SELECT
						'1.0' AS '@Version'
						,(
							SELECT
								CONVERT(VARCHAR(19), p.fecha, 126) AS '@FechaPago'
								, ccp.cfd_metodoDePago AS '@FormaDePagoP'
								, ccp.cfd_moneda AS '@MonedaP'
								, (CASE WHEN ccp.cfd_moneda = 'MXN' THEN NULL ELSE ccp.cfd_tipocambio END) AS '@TipoCambioP'
								, dbo._sys_fnc_decimales(ccp.cfd_total, csm.decimales) AS '@Monto'
								, (CASE WHEN p.referencia = '' THEN NULL ELSE p.referencia END) AS '@NumOperacion'
								, NULL AS '@RfcEmisorCtaOrd'
								, (CASE WHEN ccb.extranjero = 1 THEN cbb.nombre ELSE NULL END) AS '@NomBancoOrdExt'
								, (
									CASE 
										WHEN LEN(p.clabe_origen) = 0 THEN NULL 
										WHEN ISNULL(csfpp.bancarizado, 0) = 0 THEN NULL
										ELSE p.clabe_origen 
									END
								) AS '@CtaOrdenante'
								, (
									CASE
										WHEN ISNULL(csfpp.bancarizado, 0) = 0 THEN NULL
										ELSE cbb_e.rfc
									END
								) AS '@RfcEmisorCtaBen'
								, (	
									CASE
										WHEN ISNULL(csfpp.bancarizado, 0) = 0 THEN NULL
										ELSE bc.clabe
									END
								) AS '@CtaBeneficiario'
								, NULL AS '@TipoCadPago'
								, NULL AS '@CertPago'
								, NULL AS '@CadPago'
								, NULL AS '@SelloPago'
								, (
									SELECT
										ccft.cfdi_UUID AS '@IdDocumento'
										, ccf.cfd_serie AS '@Serie'
										, ccf.cfd_folio AS '@Folio'
										, ccf.cfd_moneda AS '@MonedaDR'
										, (CASE WHEN ccp.cfd_moneda = ccf.cfd_moneda THEN NULL ELSE ccf.cfd_tipoCambio END) AS '@TipoCambioDR'
										, ccf.cfd_formaDePago AS '@MetodoDePagoDR' --ccf.cfd_formaDePago
										, (SELECT COUNT(*) FROM ew_cxc_transacciones_mov AS np WHERE np.idtran2 = ctm.idtran2 AND np.idtran <= ctm.idtran) AS '@NumParcialidad'
										, (dbo._sys_fnc_decimales(f.saldo + ctm.importe2, csm.decimales)) AS '@ImpSaldoAnt'
										, dbo._sys_fnc_decimales(ctm.importe2, csm.decimales) AS '@ImpPagado'
										, (dbo._sys_fnc_decimales(f.saldo, csm.decimales)) AS '@ImpSaldoInsoluto'
									FROM
										ew_cxc_transacciones_mov AS ctm
										LEFT JOIN ew_cfd_comprobantes AS ccf
											ON ccf.idtran = ctm.idtran2
										LEFT JOIN ew_cfd_comprobantes_timbre AS ccft
											ON ccft.idtran = ccf.idtran
										LEFT JOIN ew_cxc_transacciones AS f
											ON f.idtran = ctm.idtran2
									WHERE
										ctm.idtran = cc.idtran
									FOR XML PATH('pago10:DoctoRelacionado'), TYPE
								) AS '*'
								, (
									SELECT
										ISNULL((
											SELECT 
												SUM(ccip.cfd_importe) 
											FROM 
												ew_cfd_comprobantes_impuesto AS ccip
											WHERE 
												ccip.cfd_ambito = 0
												AND ccip.idtipo = 2
												AND ccip.idtran = cc.idtran
										), 0) AS '@TotalImpuestosRetenidos'
										, ISNULL((
											SELECT 
												SUM(ccip.cfd_importe) 
											FROM 
												ew_cfd_comprobantes_impuesto AS ccip
											WHERE 
												ccip.cfd_ambito = 0
												AND ccip.idtipo = 1
												AND ccip.idtran = cc.idtran
										), 0) AS '@TotalImpuestosTrasladados'
										, (
											SELECT
												ISNULL(csi.c_impuesto, '002') AS '@Impuesto'
												,SUM(cci.cfd_importe) AS '@Importe'
											FROM
												ew_cfd_comprobantes_impuesto AS cci 
												LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_impuesto AS csi
													ON csi.descripcion = cci.cfd_impuesto
											WHERE
												cci.cfd_ambito = 0
												AND cci.idtipo = 2
												AND cci.idtran = cc.idtran
											GROUP BY
												ISNULL(csi.c_impuesto, '002')
											FOR XML PATH('pago10:Retencion'), TYPE
										) AS 'pago10:Retenciones'
										, (
											SELECT
												ISNULL(csi.c_impuesto, '002') AS '@Impuesto'
												,'Tasa' AS '@TipoFactor' --Tasa; Cuota; Exento
												,CONVERT(DECIMAL(18,6), (cci.cfd_tasa / 100.00)) AS '@TasaOCuota'
												,SUM(cci.cfd_importe) AS '@Importe'
											FROM
												ew_cfd_comprobantes_impuesto AS cci 
												LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_impuesto AS csi
													ON csi.descripcion = cci.cfd_impuesto
											WHERE
												cci.cfd_ambito = 0
												AND cci.idtipo = 1
												AND cci.idtran = cc.idtran
											GROUP BY
												ISNULL(csi.c_impuesto, '002')
												,cci.cfd_tasa
											FOR XML PATH('pago10:Traslado'), TYPE
										) AS 'pago10:Traslados'
									WHERE 3 = 4
									FOR XML PATH ('pago10:Impuestos'), TYPE
								) AS '*'
							FOR XML PATH('pago10:Pago'), TYPE
						) AS '*'
					FROM
						ew_cfd_comprobantes AS ccp
						LEFT JOIN ew_cxc_transacciones AS p
							ON p.idtran = ccp.idtran
						LEFT JOIN ew_ban_cuentas AS bc
							ON bc.idcuenta = p.idcuenta
						LEFT JOIN ew_ban_bancos AS cbb_e
							ON cbb_e.idbanco = bc.idbanco
						LEFT JOIN ew_clientes_cuentas_bancarias AS ccb
							ON ccb.idcliente = p.idcliente
							AND ccb.clabe = p.clabe_origen
						LEFT JOIN ew_ban_bancos AS cbb
							ON cbb.idbanco = ccb.idbanco
						LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_formapago AS csfpp
							ON csfpp.c_formapago = ccp.cfd_metodoDePago
					WHERE
						ccp.cfd_tipoDeComprobante IN ('P')
						AND ccp.idtran = cc.idtran
					FOR XML PATH('pago10:Pagos'), TYPE
				) AS '*'
			FOR XML PATH ('cfdi:Complemento'), TYPE
		) AS '*'
	FROM
		ew_cfd_comprobantes AS cc
		LEFT JOIN ew_sys_sucursales AS s
			ON s.idsucursal = cc.idsucursal
		LEFT JOIN ew_sys_ciudades AS cd
			ON cd.idciudad = s.idciudad

		LEFT JOIN ew_cfd_rfc AS emisor_rfc
			ON emisor_rfc.cfd_rfc = cc.rfc_emisor
		LEFT JOIN ew_cfd_rfc AS receptor_rfc
			ON receptor_rfc.cfd_rfc = cc.rfc_receptor
		LEFT JOIN ew_cxc_transacciones AS ct
			ON ct.idtran = cc.idtran
		LEFT JOIN objetos AS o
			ON o.codigo = ct.transaccion
		LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_tiporelacion AS cst
			ON cst.idr = ct.idrelacion
		LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_tiporelacion_objetos AS csto
			ON csto.objeto = o.objeto
		LEFT JOIN ew_clientes_facturacion AS cf
			ON cf.idfacturacion = 0
			AND cf.idcliente = ct.idcliente
		LEFT JOIN ew_sys_ciudades AS cte_cd
			ON cte_cd.idciudad = cf.idciudad
		LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_pais AS csat_p 
			ON csat_p.descripcion = cte_cd.pais
			
		LEFT JOIN ew_cfd_folios AS f
			ON f.idfolio = cc.idfolio
		LEFT JOIN ew_cfd_certificados AS cer
			ON cer.idcertificado = f.idcertificado
		LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_monedas AS csm
			ON csm.c_moneda = cc.cfd_Moneda
	WHERE
		cc.idtran = @idtran
	FOR XML PATH('cfdi:Comprobante'), TYPE
) AS g(XML)

SELECT @comprobante = '<?xml version="1.0" encoding="utf-8"?>' + CONVERT(VARCHAR(MAX), @xml)

SELECT
	@comprobante = REPLACE(@comprobante, ' xmlns:' + xmlns.codigo + '="' + xmlns.uri + '"', '')
	, @namespace_text = (
		@namespace_text 
		+ (
			CASE 
				WHEN xmlns.codigo IN (SELECT tns.codigo FROM #_tmp_ns AS tns) THEN 
					' xmlns:' + xmlns.codigo + '="' + xmlns.uri + '"' 
				ELSE 
					'' 
			END
		)
	)
FROM
	db_comercial.dbo.evoluware_cfd_sat_xmlnamespace AS xmlns

SELECT @namespace_text = '<cfdi:Comprobante' + @namespace_text

SELECT @comprobante = REPLACE(@comprobante, '<cfdi:Comprobante', @namespace_text)

DROP TABLE #_tmp_ns
GO
