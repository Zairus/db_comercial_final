USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20171212
-- Description:	Formato de impreison CFDi 33 para CXC
-- =============================================
ALTER PROCEDURE _cfdi_rpt_CXC33
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	[idsucursal] = cc.idsucursal
	,[sucursal] = s.nombre
	,[documento] = (
		CASE
			WHEN o.codigo LIKE 'EFA%' THEN 'Factura de Venta'
			ELSE o.nombre
		END
	)
	,[fecha] = cc.cfd_fecha
	,[folio] = cc.cfd_serie + LTRIM(RTRIM(STR(cc.cfd_folio)))

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
			+ CHAR(10)
			+ ccu.cfd_municipio
			+ ', '
			+ ccu.cfd_estado
			+ ', '
			+ ccu.cfd_pais
			+ ' '
			+ ccu.cfd_codigoPostal
			+ CHAR(10)
			+ 'Tel: '
			+ s.telefono
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
			+ s.direccion
			+ CHAR(10)
			+ scd.ciudad
			+ ', '
			+ scd.estado
			+ ', '
			+ scd.pais
			+ ' '
			+ s.codpostal
			+ CHAR(10)
		FROM
			ew_sys_ciudades AS scd
		WHERE
			scd.idciudad = s.idciudad
	)
	
	,[receptor_nombre] = (
		SELECT
			ccrfc.cfd_nombre
		FROM
			ew_cfd_rfc AS ccrfc
		WHERE
			ccrfc.cfd_rfc = cc.rfc_receptor
	)
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
			+ CHAR(10)
			+ ccu.cfd_municipio
			+ ', '
			+ ccu.cfd_estado
			+ ', '
			+ ccu.cfd_pais
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
	
	,[condicionesDePago] = cc.cdf_condicionesDePago
	,[Moneda] = cc.cfd_Moneda
	,[TipoCambio] = cc.cfd_TipoCambio
	,[formaDePago] = csfp.descripcion + ' [' + cc.cfd_metodoDePago + ']'
	,[metodoDePago] = csmp.descripcion + ' [' + cc.cfd_formaDePago + ']'

	,[subtotal] = cc.cfd_subTotal
	,[total] = cc.cfd_total

	,[cfd_version] = cc.cfd_version
	,[cfd_uso] = csu.descripcion + ' [' + cc.cfd_uso + ']'
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
	,[cfd_selloSAT] = cct.cfdi_selloDigital
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
	,[concepto_descripcion] = ccm.concepto_descripcion
	,[concepto_precio_unitario] = ccm.concepto_precio_unitario
	,[concepto_importe] = ccm.concepto_importe

	,[total_texto] = [db_comercial].[dbo].[_sys_fnc_monedaTexto](cc.cfd_total, csm.c_moneda)
	,[pagare] = (
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
FROM 
	ew_cfd_comprobantes AS cc
	LEFT JOIN ew_cfd_comprobantes_cancelados AS ccc
		ON ccc.idtran = cc.idtran
	LEFT JOIN ew_cfd_comprobantes_sello AS ccs
		ON ccs.idtran = cc.idtran
	LEFT JOIN ew_cfd_comprobantes_timbre AS cct
		ON cct.idtran = cc.idtran
	LEFT JOIN ew_clientes_facturacion AS ecfa
		ON ecfa.idcliente = 0
		AND ecfa.idfacturacion = 0

	LEFT JOIN (
		SELECT
			[idtran] = ccm1.idtran
			,[concepto_consecutivo] = ccm1.consecutivo
			,[concepto_idarticulo] = ccm1.idarticulo
			,[concepto_codarticulo] = a.codigo
			,[concepto_claveSAT] = csc.clave
			,[concepto_cantidad] = ccm1.cfd_cantidad
			,[concepto_unidad] = ccm1.cfd_unidad
			,[concepto_descripcion] = ccm1.cfd_descripcion
			,[concepto_precio_unitario] = ccm1.cfd_valorUnitario
			,[concepto_importe] = ccm1.cfd_importe
		FROM
			ew_cfd_comprobantes_mov AS ccm1
			LEFT JOIN ew_articulos AS a
				ON a.idarticulo = ccm1.idarticulo
			LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_clasificaciones AS csc
				ON csc.idclasificacion = a.idclasificacion_sat
		WHERE
			ccm1.cfd_unidad <> 'ACT'

		UNION ALL

		SELECT
			[idtran] = ctm1.idtran
			,[concepto_consecutivo] = ccm1.consecutivo
			,[concepto_idarticulo] = ccm1.idarticulo
			,[concepto_codarticulo] = a.codigo
			,[concepto_claveSAT] = csc.clave
			,[concepto_cantidad] = 1
			,[concepto_unidad] = ccm1.cfd_unidad
			,[concepto_descripcion] = (
				'Pago '
				+ o1.nombre
				+ ': '
				+ ccf.cfd_serie
				+ LTRIM(RTRIM(STR(ccf.cfd_folio)))
			)
			,[concepto_precio_unitario] = ctm1.importe
			,[concepto_importe] = ctm1.importe
		FROM
			ew_cfd_comprobantes_mov AS ccm1
			LEFT JOIN ew_cxc_transacciones_mov AS ctm1
				ON ctm1.idtran = ccm1.idtran
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
	) AS ccm
		ON ccm.idtran = cc.idtran

	--LEFT JOIN ew_cfd_comprobantes_mov AS ccm
		--ON ccm.idtran = cc.idtran

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
WHERE
	cc.idtran = @idtran
GO
