USE db_comercial_final
GO
IF OBJECT_ID('_xac_EFA7_cargarDoc') IS NOT NULL
BEGIN
	DROP PROCEDURE _xac_EFA7_cargarDoc
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200428
-- Description:	Cargar sustitucion de CFDi
-- =============================================
CREATE PROCEDURE [dbo].[_xac_EFA7_cargarDoc]
	@idtran AS INT
AS

SET NOCOUNT ON

EXEC [dbEVOLUWARE].[dbo].[_sys_prc_procesarErrores]
 
----------------------------------------------------
-- 1) ew_ven_transacciones
----------------------------------------------------
SELECT
	[transaccion] = vt.transaccion
	, [referencia] = ISNULL(vd.folio, ISNULL(vref.folio, ''))
	, [idtran2] = vt.idtran2
	, [idsucursal] = vt.idsucursal
	, [idalmacen] = vt.idalmacen
	, [codcliente] = c.codigo
	, [idconcepto] = vt.idconcepto
	, [idcliente] = vt.idcliente
	, [fecha] = vt.fecha
	, [folio] = vt.folio
	, [idu] = vt.idu
	, [idr] = vt.idr
	, [idtran] = vt.idtran
	, [cancelado] = vt.cancelado
	, [cancelado_fecha] = vt.cancelado_fecha
	, [cliente] = c.nombre
	, [idfacturacion] = vt.idfacturacion
	, [facturara] = cf.razon_social
	, [rfc] = cf.rfc
	, [direccion] = cf.calle + ISNULL(' '+cf.noExterior,'') + ISNULL(' '+cf.noInterior,'') 
	, [colonia] = ISNULL(u.cfd_colonia,cf.colonia)
	, [ciudad] = ISNULL(u.cfd_localidad,fac.ciudad)
	, [municipio] = ISNULL(u.cfd_municipio,fac.municipio)
	, [estado] = ISNULL(u.cfd_estado,fac.estado)
	, [pais] = ISNULL(u.cfd_pais, fac.pais)
	, [codigopostal] = ISNULL(u.cfd_codigoPostal,cf.codpostal)
	, [email] = cf.email
	, [contacto] = cc.nombre
	, [horario] = ecc.horario
	, [t_credito] = ct.credito
	, [credito] = vt.credito
	, [credito_plazo] = vt.credito_plazo
	, [cliente_limite] = ISNULL(ct.credito_limite, 0)
	, [dias_pp1] = vt.dias_pp1
	, [dias_pp2] = vt.dias_pp2
	, [dias_pp3] = vt.dias_pp3
	, [descuento_pp1] = vt.descuento_pp1
	, [descuento_pp2] = vt.descuento_pp2
	, [descuento_pp3] = vt.descuento_pp3
	, [idmoneda] = vt.idmoneda
	, [tipocambio] = vt.tipocambio
	, [subtotal] = vt.subtotal
	, [impuesto1] = vt.impuesto1
	, [impuesto2] = vt.impuesto2
	, [total] = vt.total
	, [comentario] = vt.comentario
	, [entidad_codigo] = c.codigo
	, [entidad_nombre] = c.nombre
	, [identidad] = c.idcliente
	, [contabilidad] = cf.contabilidad
	, [metodoDePago] = RTRIM(c.cfd_metodoDePago) + ' ' + RTRIM(c.cfd_NumCtaPago)
	, [guia_folio] = vt.guia_folio
	, [guia_importe] = vt.guia_importe
	, [idproveedor] = vt.idproveedor
	, [acreedor] = p.nombre
	, [UUID] = ISNULL(timbres.cfdi_UUID,'')

	, [idvendedor] = vt.idvendedor
	, [no_orden] = vt.no_orden
	, [no_recepcion] = vt.no_recepcion
	, [sys_cuenta] = dbo.fn_sys_obtenerDato('GLOBAL', 'EVOLUWARE_CUENTA')
	, [cliente_notif] = dbo._sys_fnc_parametroActivo('CFDI_NOTIFICAR_AUTOMATICO')
FROM 
	ew_ven_transacciones AS vt
	LEFT JOIN ew_ven_ordenes AS vd 
		ON vd.idtran = vt.idtran2
	LEFT JOIN ew_ven_transacciones AS vref
		ON vref.idtran = vt.idtran2
	LEFT JOIN ew_clientes AS c 
		ON c.idcliente = vt.idcliente
	LEFT JOIN ew_clientes_contactos AS ecc 
		ON ecc.idcliente = c.idcliente
	LEFT JOIN ew_cat_contactos AS cc 
		ON cc.idcontacto = ecc.idcontacto
	LEFT JOIN ew_clientes_facturacion AS cf 
		ON cf.idcliente = vt.idcliente 
		AND cf.idfacturacion = vt.idfacturacion
	LEFT JOIN ew_clientes_terminos AS ct 
		ON ct.idcliente = c.idcliente
	LEFT JOIN ew_sys_ciudades AS fac 
		ON fac.idciudad = cf.idciudad 
	LEFT JOIN dbo.ew_proveedores AS p 
		ON p.idproveedor = vt.idproveedor
	LEFT JOIN ew_cfd_comprobantes_timbre AS timbres 
		ON timbres.idtran = vt.idtran
	LEFT JOIN ew_cfd_comprobantes_ubicacion AS u 
		ON u.idtran = vt.idtran 
		AND u.idtipo = 2
WHERE  
	vt.idtran = @idtran 

----------------------------------------------------
-- 2) ew_cxc_transacciones
----------------------------------------------------
SELECT
	[transaccion] = ct.transaccion
	, [idcliente] = ct.idcliente
	, [fecha] = ct.fecha
	, [folio] = ct.folio
	, [idu] = ct.idu
	, [idr] = ct.idr
	, [idtran] = ct.idtran
	, [cancelado] = ct.cancelado
	, [cancelado_fecha] = ct.cancelado_fecha
	, [idfacturacion] = ct.idfacturacion
	, [cliente_saldo] = ISNULL(csa.saldo, 0)
	, [idimpuesto1] = ct.idimpuesto1
	, [idimpuesto1_valor] = ct.idimpuesto1_valor
	, [subtotal] = ct.subtotal
	, [impuesto1] = ct.impuesto1
	, [impuesto2] = ct.impuesto2
	, [saldo] = ct.saldo
	, [comentario] = ct.comentario
	, [concepto_cuenta] = c.contabilidad
	, [vencimiento] = ct.vencimiento
	, [tipocambio_dof] = dbo.fn_ban_obtenerTC(ct.idmoneda, ct.fecha)
	, [idforma] = ct.idforma
	, [idmetodo] = ct.idmetodo
	, [cfd_iduso] = ct.cfd_iduso
	, [idrelacion] = ct.idrelacion
FROM 
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_cxc_saldos_actual AS csa 
		ON csa.idcliente = ct.idcliente 
		AND csa.idmoneda = ct.idmoneda
	LEFT JOIN conceptos AS c 
		ON c.idconcepto = ct.idconcepto
WHERE  
	ct.idtran = @idtran 

----------------------------------------------------
-- 10) ew_ven_transacciones_mov
----------------------------------------------------
SELECT
	[idtran] = vtm.idtran
	, [idr] = vtm.idr
	, [consecutivo] = vtm.consecutivo
	, [idarticulo] = vtm.idarticulo
	, [idalmacen] = vtm.idalmacen
	, [marca] = m.nombre
	, [idum] = vtm.idum
	, [maneja_lote] = a.lotes
	, [mostrar_lote] = ISNULL(SUBSTRING((
		SELECT
			', ' + vtml.lote AS [text()]
		FROM
			ew_ven_transacciones_mov_lotes AS vtml
		WHERE
			vtml.idtran = vtm.idtran
			AND vtml.idarticulo = vtm.idarticulo
		FOR XML PATH('')
	), 2, 1000), '')
	, [lote] = ic.lote
	, [fecha_caducidad] = ic.fecha_caducidad
	, [idcapa] = vtm.idcapa
	, [cantidad_autorizada] = vtm.cantidad_autorizada
	, [cantidad_facturada] = vtm.cantidad_facturada
	, [cantidad_surtida] = vtm.cantidad_surtida
	, [cantidad_devuelta] = vtm.cantidad_devuelta
	, [precio_unitario] = vtm.precio_unitario
	, [descuento1] = vtm.descuento1
	, [descuento2] = vtm.descuento2
	, [descuento3] = vtm.descuento3
	, [importe] = vtm.importe
	, [total] = vtm.total
	, [comentario] = vtm.comentario
	, [idmov] = vtm.idmov
	, [idmov2] = vtm.idmov2
	, [idtran2] = vtm.idtran2
	, [SERIES] = (
		CASE
			WHEN ([dbo].[fn_sys_parametro]('VEN_SURFAC') <> 0) THEN vtm.SERIES 
			ELSE [dbo].[fn_ven_articuloseries](vtm.idmov) 
		END
	)
	, [OBJIDTRAN] = vtm.IDTRAN2
	, [CODARTICULO] = A.CODIGO
	, [DESCRIPCION] = A.NOMBRE
	, [referencia] = ord.folio
	, [nombre_corto] = a.nombre_corto

	, [impuesto1] = vtm.impuesto1
	, [impuesto2] = vtm.impuesto2
	, [impuesto1_ret] = vtm.impuesto1_ret

	--####################################################
	, [idimpuesto1] = ISNULL((
		SELECT TOP 1
			cit.idimpuesto
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE 
			ci.grupo = 'IVA'
			AND cit.tipo = 1
			AND ait.idarticulo = a.idarticulo
	), ci.idimpuesto)
	, [idimpuesto1_valor] = ISNULL((
		SELECT TOP 1
			cit.tasa
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE 
			ci.grupo = 'IVA'
			AND cit.tipo = 1
			AND ait.idarticulo = a.idarticulo
	), ci.valor)
	, [idimpuesto1_cuenta] = ISNULL((
		SELECT TOP 1
			cit.contabilidad1
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE 
			ci.grupo = 'IVA'
			AND cit.tipo = 1
			AND ait.idarticulo = a.idarticulo
	), ci.contabilidad)

	, [idimpuesto2] = ISNULL((
		SELECT TOP 1
			cit.idimpuesto
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE 
			ci.grupo = 'IEPS'
			AND cit.tipo = 1
			AND ait.idarticulo = a.idarticulo
	), a.idimpuesto2)
	, [idimpuesto2_valor] = ISNULL((
		SELECT TOP 1
			cit.tasa
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE 
			ci.grupo = 'IEPS'
			AND cit.tipo = 1
			AND ait.idarticulo = a.idarticulo
	), ISNULL((SELECT ci1.valor FROM ew_cat_impuestos AS ci1 WHERE ci1.idimpuesto = a.idimpuesto2), 0))
	, [idimpuesto2_cuenta] = ISNULL((
		SELECT TOP 1
			cit.contabilidad1
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE 
			ci.grupo = 'IEPS'
			AND cit.tipo = 1
			AND ait.idarticulo = a.idarticulo
	), ISNULL((SELECT ci1.contabilidad FROM ew_cat_impuestos AS ci1 WHERE ci1.idimpuesto = a.idimpuesto2), 0))

	, [idimpuesto1_ret] = ISNULL((
		SELECT TOP 1
			cit.idimpuesto
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE 
			ci.grupo = 'IVA'
			AND cit.tipo = 2
			AND ait.idarticulo = a.idarticulo
	), a.idimpuesto1_ret)
	, [idimpuesto1_ret_valor] = ISNULL((
		SELECT TOP 1
			cit.tasa
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE 
			ci.grupo = 'IVA'
			AND cit.tipo = 2
			AND ait.idarticulo = a.idarticulo
	), ISNULL((SELECT ci1.valor FROM ew_cat_impuestos AS ci1 WHERE ci1.idimpuesto = a.idimpuesto1_ret), 0))
	, [idimpuesto1_ret_cuenta] = ISNULL((
		SELECT TOP 1
			cit.contabilidad1
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE 
			ci.grupo = 'IVA'
			AND cit.tipo = 2
			AND ait.idarticulo = a.idarticulo
	), ISNULL((SELECT ci1.contabilidad FROM ew_cat_impuestos AS ci1 WHERE ci1.idimpuesto = a.idimpuesto1_ret), 0))
	, [idimpuesto2_ret] = ISNULL((
		SELECT TOP 1
			cit.idimpuesto
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE 
			ci.grupo = 'ISR'
			AND cit.tipo = 2
			AND ait.idarticulo = a.idarticulo
	), a.idimpuesto2_ret)
	, [idimpuesto2_ret_valor] = ISNULL((
		SELECT TOP 1
			cit.tasa
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE 
			ci.grupo = 'ISR'
			AND cit.tipo = 2
			AND ait.idarticulo = a.idarticulo
	), ISNULL((SELECT ci1.valor FROM ew_cat_impuestos AS ci1 WHERE ci1.idimpuesto = a.idimpuesto2_ret), 0))
	, [idimpuesto2_ret_cuenta] = ISNULL((
		SELECT TOP 1
			cit.contabilidad1
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE 
			ci.grupo = 'ISR'
			AND cit.tipo = 2
			AND ait.idarticulo = a.idarticulo
	), ISNULL((SELECT ci1.contabilidad FROM ew_cat_impuestos AS ci1 WHERE ci1.idimpuesto = a.idimpuesto2_ret), 0))

	, [ingresos_cuenta] = ISNULL((
		SELECT TOP 1
			CASE
				WHEN cit.descripcion LIKE '%exen%' THEN '4100003000'
				ELSE
					CASE
						WHEN cit.tasa = 0 THEN '4100002000'
						ELSE '4100001000'
					END
			END
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE 
			ci.grupo = 'IVA'
			AND cit.tipo = 1
			AND ait.idarticulo = a.idarticulo
	), '4100001000')

	, vtm.agrupar
	, vtm.objlevel

	, [clasif_SAT] = CASE WHEN a.idclasificacion_SAT=0 THEN '-Sin Clasif.-' ELSE ISNULL(csat.clave,'-Sin Clasif.-') END
FROM 
	ew_ven_transacciones_mov AS vtm
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = vtm.idarticulo
	LEFT JOIN ew_ven_ordenes AS ord 
		ON ord.idtran = vtm.idtran2 
	LEFT JOIN ew_inv_capas AS ic 
		ON vtm.idcapa = ic.idcapa 
		AND vtm.idarticulo = ic.idarticulo
	LEFT JOIN ew_cat_marcas AS m 
		ON a.idmarca=m.idmarca

	LEFT JOIN ew_ven_transacciones AS vt
		ON vt.idtran = vtm.idtran
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = vt.idsucursal
	LEFT JOIN ew_cat_impuestos AS ci
		ON ci.idimpuesto = (CASE WHEN a.idimpuesto1 = 0 THEN s.idimpuesto ELSE a.idimpuesto1 END)

	LEFT JOIN ew_cfd_sat_clasificaciones csat
		ON csat.idclasificacion = a.idclasificacion_sat
WHERE  
	vtm.idtran = @idtran 

----------------------------------------------------
-- 20) ew_ct_impuestos_transacciones
----------------------------------------------------
SELECT
	[codigo] = a.codigo
	, [nombre] = a.nombre
	, [idtasa] = citr.idtasa
	, [tasa] = cit.tasa
	, [base_proporcion] = cit.base_proporcion
	, [base] = citr.base
	, [importe] = citr.importe
	, [idr] = citr.idr
	, [idtran] = citr.idtran
	, [idmov] = citr.idmov
	, [idmov2] = citr.idmov2
FROM 
	ew_ct_impuestos_transacciones AS citr
	LEFT JOIN ew_ven_transacciones_mov AS vom
		ON vom.idmov = citr.idmov
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vom.idarticulo
	LEFT JOIN ew_cat_impuestos_tasas AS cit
		ON cit.idtasa = citr.idtasa
WHERE 
	citr.idtran = @idtran
GO
