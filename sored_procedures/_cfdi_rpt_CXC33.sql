USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20171212
-- Description:	Formato de impreison CFDi 33 para CXC
-- =============================================
ALTER PROCEDURE [dbo].[_cfdi_rpt_CXC33]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE @concat_nom_corto_articulo VARCHAR(1) = ''

SELECT @concat_nom_corto_articulo = ISNULL(dbo.fn_sys_parametro('PDF_CONCAT_NOM_CORTO_ARTICULO'),'0')

SELECT
	[idsucursal] = cc.idsucursal
	,[sucursal] = s.nombre
	,[transaccion] = o.codigo
	,[documento] = (
		o.nombre
	)
	,[documento_tipo] = vt.tipo
	,[fecha] = cc.cfd_fecha
	,[folio] = cc.cfd_serie + dbo.fnRellenar(LTRIM(RTRIM(STR(cc.cfd_folio))),6,'0')

	,[emisor_nombre] = ''
	,[emisor_rfc] = cc.rfc_emisor
	,[emisor_domicilio] = (
		SELECT
			ecfa.razon_social
			+ ' - '
			+ ecfa.rfc
			+ CHAR(10)
			+ ccu.cfd_calle 
			+ ' '
			+ ccu.cfd_noExterior
			+ (
				CASE 
					WHEN LEN(ccu.cfd_noInterior) > 0 THEN ' ' + ccu.cfd_noInterior
					ELSE '' 
				END
			)
			+ ' COL. ' + ccu.cfd_colonia
			+ ' '
			+ (CASE WHEN ccu.cfd_municipio='' THEN ccu.cfd_localidad ELSE ccu.cfd_municipio END)
			+ ', '
			+ ccu.cfd_estado
			+ ', '
			+ ' C.P. '
			+ ccu.cfd_codigoPostal
			+ CASE WHEN DB_NAME() NOT IN ('db_rafagas_datos2') THEN ' TEL: ' --que excluya teléfono en RAFAGAS DEL PACIFICO
			+ s.telefono
			ELSE '' END
		FROM 
			ew_cfd_comprobantes_ubicacion AS ccu 
		WHERE
			ccu.idtipo = 1 
			AND ccu.idtran = cc.idtran
	)
	,[emisor_expedidoen] = (
		SELECT
			s.nombre
			+ CHAR(10)
			+ REPLACE(s.direccion, CHAR(13), '')
			+ ' COL. ' + s.colonia
			+ CHAR(10)
			+ REPLACE(scd.ciudad, CHAR(13), '')
			+ ', '
			+ scd.estado
			+ ' C.P. '
			+ s.codpostal
		FROM
			ew_sys_ciudades AS scd
		WHERE
			scd.idciudad = s.idciudad
	)
	
	,[emisor_codigopostal] = (
		SELECT
			s.codpostal
		FROM
			ew_sys_ciudades AS scd
		WHERE
			scd.idciudad = s.idciudad
	)
	,[receptor_no_orden] = ISNULL(vt2.no_orden,'') --ORDEN DE COMPRA DEL CLIENTE
	,[receptor_codigo] = c.codigo
	,[receptor_nombre] = cf.razon_social
	,[receptor_rfc] = cc.rfc_receptor
	,[receptor_domicilio] = (
		SELECT
			ccu.cfd_calle 
			+ ' '
			+ ccu.cfd_noExterior
			+ (
				CASE 
					WHEN LEN(ccu.cfd_noInterior) > 0 THEN ' ' + ccu.cfd_noInterior
					ELSE '' 
				END
			)
			+ ' COL. ' + ccu.cfd_colonia
			+ CHAR(10)
			+ (CASE WHEN ccu.cfd_municipio='' THEN ccu.cfd_localidad ELSE ccu.cfd_municipio END)
			+ ', '
			+ ccu.cfd_estado
			+ ' '
			+ ccu.cfd_codigoPostal
		FROM 
			ew_cfd_comprobantes_ubicacion AS ccu 
		WHERE
			ccu.idtipo = 2
			AND ccu.idtran = cc.idtran
	)
	,[receptor_telefono] = ISNULL((
		SELECT TOP 1
			cfat.telefono1
		FROM 
			ew_clientes_facturacion AS cfat 
		WHERE 
			cfat.idcliente = doc.idcliente
	), '')
	,[receptor_cuenta] = ISNULL((
		SELECT TOP 1
			bb.nombre + ' ' +doc.clabe_origen
		FROM
			ew_clientes_cuentas_bancarias AS ccb
			LEFT JOIN ew_ban_bancos AS bb
				ON bb.idbanco = ccb.idbanco
		WHERE
			ccb.idcliente = doc.idcliente
			AND  ccb.clabe = doc.clabe_origen
	), '')
	
	,[receptor_contacto] = (
		SELECT TOP 1 
			(cc.nombre + ' ' + cc.apellido)
		FROM
			ew_cat_contactos cc
		LEFT JOIN ew_clientes_contactos ccc 
			ON ccc.idcontacto = cc.idcontacto
		WHERE
			ccc.idcliente = c.idcliente AND LTRIM(RTRIM(cc.nombre)) <>''
	)
	,[condicionesDePago] = cc.cdf_condicionesDePago
	,[Moneda] = cc.cfd_Moneda
	,[TipoCambio] = CONVERT(VARCHAR(20),CONVERT(NUMERIC(18,2),cc.cfd_TipoCambio))
	,[formaDePago] = csfp.descripcion + ' [' + cc.cfd_metodoDePago + ']'
	,[metodoDePago] = csmp.descripcion + ' [' + cc.cfd_formaDePago + ']'

	,[subtotal] = cc.cfd_subTotal
	,[total] = cc.cfd_total

	,[cfd_version] = cc.cfd_version
	,[cfd_uso] = csu.descripcion + ' [' + cc.cfd_uso + ']'
	,[cfd_tiporelacion] = ISNULL(ISNULL('[' + cst.c_tiporelacion + '] ' + cst.descripcion, '[' + csto_cst.c_tiporelacion + '] ' + csto_cst.descripcion), '')
	,[cfd_noCertificado] = cc.cfd_noCertificado
	,[cfd_tipoDeComprobante] = cc.cfd_tipoDeComprobante
	,[cfd_cadenaOriginal] = ccs.cadenaOriginal
	,[cfd_certificado] = ccs.cfd_certificado
	,[cfd_sello] = ccs.cfd_sello
	,[cfd_pac] = ccc.pac
	,[cfd_acuse] = ccc.acuse

	,[cfd_FechaTimbrado] = cct.cfdi_FechaTimbrado
	,[cfd_versionTFD] = cct.cfdi_versionTFD
	,[cfd_UUID] = cct.cfdi_UUID
	,[cfd_noCertificadoSAT] = cct.cfdi_noCertificadoSAT
--	,[cfd_selloSAT] = cct.cfdi_selloDigital
	,[cfd_selloCFDI] = cct.cfdi_selloDigital
	,[cfd_selloSAT] = (
		SELECT
			cco.valor
		FROM
			dbo._sys_fnc_separarMultilinea(cct.cfdi_cadenaOriginal, '|') AS cco
		WHERE
			cco.idr = 7
	)
	,[cfd_cadenaOriginalSAT] = cct.cfdi_cadenaOriginal
	,[cfd_QRCode] = cct.QRCode
	,[cfd_fechaCancelacion] = cct.cfdi_fechaCancelacion
	,[cfd_respuesta_mensaje] = cct.cfdi_respuesta_mensaje

	,[concepto_consecutivo] = ccm.concepto_consecutivo
	,[concepto_idarticulo] = ccm.concepto_idarticulo
	,[concepto_codarticulo] = ccm.concepto_codarticulo
	,[concepto_claveSAT] = ccm.concepto_claveSAT
	,[concepto_cantidad] = ccm.concepto_cantidad
	,[concepto_unidad] = ccm.concepto_unidad
	,[concepto_descripcion] = REPLACE(ccm.concepto_descripcion, CHAR(13), '<br />')
	,[concepto_precio_unitario] = ccm.concepto_precio_unitario
	,[concepto_importe] = ccm.concepto_importe

	,[total_texto] = [db_comercial].[dbo].[_sys_fnc_monedaTexto](cc.cfd_total, csm.c_moneda)

	,[vendedor] = ISNULL(v.nombre,'')

	,[pagare] = (
		CASE WHEN DB_NAME()='db_conexionpc_datos' THEN
		(
			SELECT
				'Por éste pagaré me(nos) obligo(amos) a pagar incondicionalmente en la ciudad de '
				+ ccu.cfd_municipio
				+ ', '
				+ ccu.cfd_estado
				+ ' a la orden de '
				+ ecfa.razon_social
				+ ' la cantidad de: $'
				+ CONVERT(VARCHAR(20), CONVERT(NUMERIC(18,2),cc.cfd_total))
				+ ' (Son: '
				+ [db_comercial].[dbo].[_sys_fnc_monedaTexto](cc.cfd_total, csm.c_moneda)
				+ '.'
				+ CHAR(13) + CHAR(10)
				+ 'Con vencimiento el '
				+ CONVERT(VARCHAR(10), DATEADD(day,ct.credito_plazo,cc.cfd_fecha), 103)
				+ ' este pagaré causará intereses moratorios del 5% mensual a partir de su vencimiento. Cubriendo, además, costos y gastos originados.'
				+ CHAR(13) + CHAR(10)
				+ 'Se extiende en la ciudad de '
				+ ccu.cfd_municipio
				+ ', '
				+ ccu.cfd_estado
				+ ' el '
				+ CONVERT(VARCHAR(10), cc.cfd_fecha, 103)
				+ '.'
			FROM 
				ew_cfd_comprobantes_ubicacion AS ccu 
			WHERE
				ccu.idtipo = 1 
				AND ccu.idtran = cc.idtran
		)
		ELSE
		(
			SELECT
				'POR ESTE PAGARE PROMETO (EMOS) Y ME (NOS) OBLIGO (AMOS) A PAGAR INCONDICIONALMENTE A LA ORDEN DE '
				+ ecfa.razon_social
				+ ' EL DIA '
				+ CONVERT(VARCHAR(8), cc.cfd_fecha, 3)
				+ ' EN LA CIUDAD DE '
				+ ccu.cfd_municipio
				+ ', '
				+ ccu.cfd_estado
				+ ' LA CANTIDAD DE $'
				+ CONVERT(VARCHAR(20), cc.cfd_total)
				+ ' (Son: '
				+ [db_comercial].[dbo].[_sys_fnc_monedaTexto](cc.cfd_total, csm.c_moneda)
				+ ' VALOR RECIBIDO A MI (NUESTRA) ENTERA SATISFACCIÓN, ESTE PAGARÉ ES MERCANTIL Y ESTA REGIDO POR LA LEY GENERAL DE TITULOS Y OPERACIONES DE CREDITO, '
				+ 'EN SU ART. 173 PARTE FINAL POR NO SER DOMICILIADO Y ARTICULOS CORRELATIVOS QUEDA EXPRESAMENTE CONVENIDO QUE SI NO ES PAGADO ESTE DOCUMENTO A SU VENCIMIENTO '
				+ 'CAUSARA UN INTERESES MORATORIO DE '
				+ '6%'
				+ ' MENSUAL, SOMETIENDOME EN CASO DE COBRO JUDICIAL A LA JURISDICCION Y COMPETENCIA DE LOS JUECES Y TRIBUNALES DE ESTA CIUDAD DE '
				+ ccu.cfd_municipio
				+ ', '
				+ ccu.cfd_estado
				+ '.'
			FROM 
				ew_cfd_comprobantes_ubicacion AS ccu 
			WHERE
				ccu.idtipo = 1 
				AND ccu.idtran = cc.idtran
		)
		END
	)
	,[observaciones] = CASE WHEN doc.transaccion IN('EFA1','EFA6') THEN (CONVERT(VARCHAR(MAX),doc.comentario) + ISNULL(dbo.fn_sys_parametro('VEN_MENSAJE_COMENTARIO'),'')) ELSE doc.comentario END
	,[cancelado] = ISNULL(vt.cancelado,0)

	,[vendedor] = ISNULL(v.nombre,'')
FROM 
	ew_cfd_comprobantes AS cc
	LEFT JOIN ew_cfd_comprobantes_cancelados AS ccc
		ON ccc.idtran = cc.idtran
	LEFT JOIN ew_cfd_comprobantes_sello AS ccs
		ON ccs.idtran = cc.idtran
	LEFT JOIN ew_cfd_comprobantes_timbre AS cct
		ON cct.idtran = cc.idtran
	LEFT JOIN ew_clientes_facturacion AS ecfa
		ON ecfa.idcliente = 0 AND ecfa.idfacturacion = 0
---------------------------------------------------------------------------
-- Se agregaron estos LEFT JOIN para que se haga el amarre por medio de idcliente
-- y no por RFC para evitar que ponga otro nombre en la factura cuando se repite el RFC
-- en ew_clientes_facturacion
	LEFT JOIN ew_cxc_transacciones AS vt
		ON cc.idtran = vt.idtran
	LEFT JOIN ew_clientes_facturacion cf
		ON cf.idcliente = vt.idcliente AND cf.idfacturacion=vt.idfacturacion
	LEFT JOIN ew_clientes c
		ON c.idcliente = cf.idcliente

	LEFT JOIN ew_ven_transacciones AS vt2
		ON vt2.idtran = vt.idtran

	LEFT JOIN ew_ven_vendedores v
		ON v.idvendedor = vt2.idvendedor

	LEFT JOIN ew_clientes_terminos ct
		ON ct.idcliente = c.idcliente
---------------------------------------------------------------------------
	LEFT JOIN (
		SELECT
			[idtran] = ccm1.idtran
			,[concepto_consecutivo] = ccm1.consecutivo
			,[concepto_ordenamiento] = ccm1.consecutivo
			,[concepto_idarticulo] = ccm1.idarticulo
			,[concepto_codarticulo] = a.codigo
			,[concepto_claveSAT] = csc.clave
			,[concepto_cantidad] = ccm1.cfd_cantidad
			,[concepto_unidad] = ISNULL(cum1.sat_unidad_clave, 'EA') + '-' + ccm1.cfd_unidad
			,[concepto_descripcion] = (
				CASE 
					WHEN @concat_nom_corto_articulo = 1 THEN 
						a.nombre_corto + ' - ' + ccm1.cfd_descripcion 
					ELSE ccm1.cfd_descripcion 
				END
			) 
			+ (
				CASE 
					WHEN LEN(vtm.series) > 0 THEN 
						CHAR(13) + CHAR(10)
						+ ' SERIES: ' + REPLACE(vtm.series, CHAR(9), ',')
					ELSE '' 
				END
			)
			+ (
				CASE
					WHEN a.lotes > 0 THEN
						ISNULL(SUBSTRING(CHAR(13) + CHAR(10) + (
							SELECT
								(
									CONVERT(VARCHAR(20), vtml.cantidad)
									+ ', Lote: ' + vtml.lote
									+ ', Cad.: '
									+ ISNULL(CONVERT(VARCHAR(8), (
										SELECT
											MAX(ic.fecha_caducidad)
										FROM
											ew_inv_capas AS ic
										WHERE
											ic.fecha_caducidad IS NOT NULL
											AND ic.lote = vtml.lote
									), 3), '')
									+ '; '
								) AS [text()]
							FROM
								ew_ven_transacciones_mov_lotes AS vtml
							WHERE
								vtml.cantidad > 0
								AND vtml.idtran = ccm1.idtran
								AND vtml.idarticulo = ccm1.idarticulo
							FOR XML PATH('')
						), 2, 1000), '')
					ELSE ''
				END
			)
			,[concepto_precio_unitario] = ccm1.cfd_valorUnitario
			,[concepto_importe] = ccm1.cfd_importe
		FROM
			ew_cfd_comprobantes_mov AS ccm1
			LEFT JOIN ew_articulos AS a
				ON a.idarticulo = ccm1.idarticulo
			LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_clasificaciones AS csc
				ON csc.idclasificacion = a.idclasificacion_sat
			LEFT JOIN ew_ven_transacciones_mov AS vtm
				ON vtm.idmov = ccm1.idmov2
			LEFT JOIN ew_cat_unidadesMedida AS cum1
				ON cum1.idum = a.idum_venta
		WHERE
			ccm1.cfd_unidad <> 'ACT'
			AND ccm1.consecutivo_padre = 0

		UNION ALL

		SELECT
			[idtran] = ctm1.idtran
			,[concepto_consecutivo] = ccm1.consecutivo
			,[concepto_ordenamiento] = ccm1.consecutivo
			,[concepto_idarticulo] = ccm1.idarticulo
			,[concepto_codarticulo] = a.codigo
			,[concepto_claveSAT] = csc.clave
			,[concepto_cantidad] = 1
			,[concepto_unidad] = ccm1.cfd_unidad
			,[concepto_descripcion] = (
				'Aplicación a '
				+ o1.nombre
				+ ': '
				+ ccf.cfd_serie
				+ LTRIM(RTRIM(STR(ccf.cfd_folio)))
			)
			,[concepto_precio_unitario] = ct1.subtotal
			,[concepto_importe] = ctm1.importe
		FROM
			ew_cfd_comprobantes_mov AS ccm1
			LEFT JOIN ew_cxc_transacciones_mov AS ctm1
				ON ctm1.idtran = ccm1.idtran
			LEFT JOIN ew_cxc_transacciones AS ctd1
				ON ctd1.idtran = ccm1.idtran
			LEFT JOIN ew_articulos AS a
				ON a.idarticulo = ccm1.idarticulo
			LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_clasificaciones AS csc
				ON csc.idclasificacion = a.idclasificacion_sat
			LEFT JOIN ew_cfd_comprobantes AS ccf
				ON ccf.idtran = ctm1.idtran2
			LEFT JOIN ew_cxc_transacciones AS ct1
				ON ct1.idtran = ctm1.idtran2
			LEFT JOIN objetos AS o1
				ON o1.codigo = ct1.transaccion
			WHERE 
				ccm1.idr IS NOT NULL
				AND ccm1.consecutivo_padre = 0
				AND ctd1.transaccion NOT IN ('EDE1')

		UNION ALL
		
		SELECT
			[idtran] = ccm1.idtran

			,[concepto_consecutivo] = ccm1.consecutivo
			,[concepto_ordenamiento] = ccm1.consecutivo
			,[concepto_idarticulo] = ccm1.idarticulo
			,[concepto_codarticulo] = ccm1.cfd_noIdentificacion
			,[concepto_claveSAT] = csc.clave
			,[concepto_cantidad] = ccm1.cfd_cantidad
			,[concepto_unidad] = ccm1.cfd_unidad
			,[concepto_descripcion] = ccm1.cfd_descripcion
			,[concepto_precio_unitario] = ccm1.cfd_valorUnitario
			,[concepto_importe] = ccm1.cfd_importe
		FROM
			ew_cfd_comprobantes_mov AS ccm1
			LEFT JOIN ew_cxc_transacciones AS ct
				ON ct.idtran = ccm1.idtran
			LEFT JOIN ew_articulos AS a
				ON a.idarticulo = ccm1.idarticulo
			LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_clasificaciones AS csc
				ON csc.idclasificacion = a.idclasificacion_sat
		WHERE
			ct.transaccion IN ('EFA4')

		UNION ALL

		SELECT
			[idtran] = vtms.idtran
			,[concepto_consecutivo] = ISNULL(ccm1.consecutivo, 0) + 10
			,[concepto_ordenamiento] = ISNULL(ccm1.consecutivo, 0)
			,[concepto_idarticulo] = ISNULL(ccm1.idarticulo, 0)
			,[concepto_codarticulo] = ''
			,[concepto_claveSAT] = ''
			,[concepto_cantidad] = NULL
			,[concepto_unidad] = ''
			,[concepto_descripcion] = 
				'Tipo Plan: ' + spt.nombre + CHAR(13) + CHAR(10)
				+ (
					'Periodo: ' 
					+ LTRIM(RTRIM(STR(vtms.ejercicio))) + '-' 
					+ (
						SELECT spd.descripcion 
						FROM ew_sys_periodos_datos AS spd 
						WHERE 
							spd.grupo = 'meses' 
							AND spd.id = vtms.periodo
					)
				) + CHAR(13) + CHAR(10)
				+ (
					REPLACE((
						SELECT
							(
								(
									CASE
										WHEN ROW_NUMBER() OVER (PARTITION BY cu.idubicacion ORDER BY cu.nombre) = 1 THEN 
											'Ubic.: ' + ISNULL(cu.nombre, 'GENERAL') + '{13}'
											+ 'Equipo(s): {13}'
										ELSE ''
									END
								)
								+ CHAR(9) + '*'
								+ se.serie
								+ ': '
								+ ae.nombre
								+ ', '
								+ '{13}'
							) AS [text()]
						FROM
							ew_clientes_servicio_equipos AS cse
							LEFT JOIN ew_clientes_ubicaciones AS cu
								ON cu.idcliente = cse.idcliente
								AND cu.idubicacion = cse.idubicacion
							LEFT JOIN ew_ser_equipos AS se
								ON se.idequipo = cse.idequipo
							LEFT JOIN ew_articulos AS ae
								ON ae.idarticulo = se.idarticulo
						WHERE
							cse.idcliente = vt.idcliente
							AND cse.plan_codigo = csp.plan_codigo
						ORDER BY
							cu.nombre
						FOR XML PATH ('')
					), '{13}', CHAR(13) + CHAR(10))
				)
			,[concepto_precio_unitario] = NULL
			,[concepto_importe] = NULL
		FROM
			ew_ven_transacciones_mov_servicio AS vtms
			LEFT JOIN ew_cfd_comprobantes_mov AS ccm1
				ON ccm1.idmov2 = vtms.idmov
			LEFT JOIN ew_articulos AS a
				ON a.idarticulo = ccm1.idarticulo
			LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_clasificaciones AS csc
				ON csc.idclasificacion = a.idclasificacion_sat
			LEFT JOIN ew_ven_transacciones AS vt
				ON vt.idtran = vtms.idtran
			LEFT JOIN ew_clientes_servicio_planes AS csp
				ON csp.idcliente = vt.idcliente
				AND csp.plan_codigo = vtms.plan_codigo
			LEFT JOIN ew_ser_planes_tipos AS spt
				ON spt.idtipoplan = csp.tipo
	) AS ccm
		ON ccm.idtran = cc.idtran

	LEFT JOIN ew_cxc_transacciones AS doc
		ON doc.idtran = cc.idtran
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = cc.idsucursal
	LEFT JOIN objetos AS o
		ON o.codigo = doc.transaccion
	LEFT JOIN ew_ban_monedas AS bm
		ON bm.idmoneda = doc.idmoneda

	LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_uso AS csu
		ON csu.c_usocfdi = cc.cfd_uso
	LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_formapago AS csfp
		ON csfp.c_formapago = cc.cfd_metodoDePago
	LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_metodopago AS csmp
		ON csmp.c_metodopago = cc.cfd_formaDePago
	LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_monedas AS csm
		ON csm.c_moneda = bm.codigo
		
	LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_tiporelacion AS cst
		ON cst.idr = doc.cfd_idrelacion
	LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_tiporelacion_objetos AS csto
		ON csto.objeto = o.objeto
	LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_tiporelacion AS csto_cst
		ON csto_cst.c_tiporelacion = csto.c_tiporelacion
WHERE
	cc.idtran = @idtran
ORDER BY
	ccm.concepto_ordenamiento
GO
