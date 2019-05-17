USE db_comercial_final
GO
-- =============================================
-- Autor:			Laurence Saavedra
-- Creado el:		Septiembre 2011
-- Modificado en:	
-- Description:		Procedimiento para desplegar la transaccion EFA1 
--					y mejorar el rendimiento evitando los cargarDoc
-- Ejemplo :		EXEC _xac_EFA1_cargarDoc @idtran 
-- =============================================
ALTER PROCEDURE [dbo].[_xac_EFA1_cargarDoc]
	@idtran AS INT
AS

SET NOCOUNT ON

EXEC [dbEVOLUWARE].[dbo].[_sys_prc_procesarErrores]
 
----------------------------------------------------
-- 1) ew_ven_transacciones
----------------------------------------------------
SELECT
	[transaccion] = ew_ven_transacciones.transaccion
	, [referencia] = ISNULL(vd.folio, ISNULL(vref.folio, ''))
	, [idtran2] = ew_ven_transacciones.idtran2
	, [idsucursal] = ew_ven_transacciones.idsucursal
	, [idalmacen] = ew_ven_transacciones.idalmacen
	, [codcliente] = c.codigo
	, ew_ven_transacciones.idconcepto
	, ew_ven_transacciones.idcliente
	, ew_ven_transacciones.fecha
	, ew_ven_transacciones.folio
	, ew_ven_transacciones.idu
	, ew_ven_transacciones.idr
	, ew_ven_transacciones.idtran
	, ew_ven_transacciones.cancelado
	, ew_ven_transacciones.cancelado_fecha
	, [cliente] = c.nombre
	, [idfacturacion] = ew_ven_transacciones.idfacturacion
	, [facturara]= cf.razon_social
	, [rfc]=cf.rfc
	, [direccion] = cf.calle + ISNULL(' '+cf.noExterior,'') + ISNULL(' '+cf.noInterior,'') 
	, [colonia] = ISNULL(u.cfd_colonia,cf.colonia)
	, [ciudad] = ISNULL(u.cfd_localidad,fac.ciudad)
	, [municipio] = ISNULL(u.cfd_municipio,fac.municipio)
	, [estado] = ISNULL(u.cfd_estado,fac.estado)
	, [pais] = ISNULL(u.cfd_pais, fac.pais)
	, [codigopostal] = ISNULL(u.cfd_codigoPostal,cf.codpostal)
	, cf.email
	, [contacto] = cc.nombre
	, [horario] = ecc.horario
	, [t_credito] = ct.credito
	, [credito] = ew_ven_transacciones.credito
	, [credito_plazo] = ew_ven_transacciones.credito_plazo
	, cliente_limite = ISNULL(ct.credito_limite, 0)
	, ew_ven_transacciones.dias_pp1
	, ew_ven_transacciones.dias_pp2
	, ew_ven_transacciones.dias_pp3
	, ew_ven_transacciones.descuento_pp1
	, ew_ven_transacciones.descuento_pp2
	, ew_ven_transacciones.descuento_pp3
	, ew_ven_transacciones.idmoneda
	, ew_ven_transacciones.tipocambio
	, ew_ven_transacciones.subtotal
	, ew_ven_transacciones.impuesto1
	, ew_ven_transacciones.impuesto2
	, ew_ven_transacciones.total
	, ew_ven_transacciones.comentario
	, entidad_codigo = c.codigo
	, entidad_nombre = c.nombre
	, identidad = c.idcliente
	, cf.contabilidad
	, [metodoDePago]=RTRIM(c.cfd_metodoDePago) + ' ' + RTRIM(c.cfd_NumCtaPago)
	, ew_ven_transacciones.guia_folio
	, ew_ven_transacciones.guia_importe
	, ew_ven_transacciones.idproveedor
	, p.nombre AS acreedor
	, [UUID] = ISNULL(timbres.cfdi_UUID,'')

	, ew_ven_transacciones.idvendedor
	, ew_ven_transacciones.no_orden
	, ew_ven_transacciones.no_recepcion
	, [sys_cuenta] = dbo.fn_sys_obtenerDato('GLOBAL', 'EVOLUWARE_CUENTA')
	, [cliente_notif] = dbo._sys_fnc_parametroActivo('CFDI_NOTIFICAR_AUTOMATICO')
FROM 
	ew_ven_transacciones
	LEFT JOIN ew_ven_ordenes AS vd 
		ON vd.idtran = ew_ven_transacciones.idtran2
	LEFT JOIN ew_ven_transacciones AS vref
		ON vref.idtran = ew_ven_transacciones.idtran2
	LEFT JOIN ew_clientes AS c 
		ON c.idcliente = ew_ven_transacciones.idcliente
	LEFT JOIN ew_clientes_contactos AS ecc 
		ON ecc.idcliente = c.idcliente
	LEFT JOIN ew_cat_contactos AS cc 
		ON cc.idcontacto = ecc.idcontacto
	LEFT JOIN ew_clientes_facturacion AS cf 
		ON cf.idcliente = ew_ven_transacciones.idcliente 
		AND cf.idfacturacion = ew_ven_transacciones.idfacturacion
	LEFT JOIN ew_clientes_terminos AS ct 
		ON ct.idcliente = c.idcliente
	LEFT JOIN ew_sys_ciudades AS fac 
		ON fac.idciudad = cf.idciudad 
	LEFT JOIN dbo.ew_proveedores AS p 
		ON p.idproveedor = ew_ven_transacciones.idproveedor
	LEFT JOIN ew_cfd_comprobantes_timbre AS timbres 
		ON timbres.idtran = ew_ven_transacciones.idtran
	LEFT JOIN ew_cfd_comprobantes_ubicacion AS u 
		ON u.idtran = ew_ven_transacciones.idtran 
		AND u.idtipo = 2
WHERE  
	ew_ven_transacciones.idtran = @idtran 

----------------------------------------------------
-- 2) ew_cxc_transacciones
----------------------------------------------------
SELECT
	ew_cxc_transacciones.transaccion
	, ew_cxc_transacciones.idcliente
	, ew_cxc_transacciones.fecha
	, ew_cxc_transacciones.folio
	, ew_cxc_transacciones.idu
	, ew_cxc_transacciones.idr
	, ew_cxc_transacciones.idtran
	, ew_cxc_transacciones.cancelado
	, ew_cxc_transacciones.cancelado_fecha
	, ew_cxc_transacciones.idfacturacion
	, [cliente_saldo] = ISNULL(csa.saldo, 0)
	, ew_cxc_transacciones.idimpuesto1
	, ew_cxc_transacciones.idimpuesto1_valor
	, ew_cxc_transacciones.subtotal
	, ew_cxc_transacciones.impuesto1	
	, ew_cxc_transacciones.impuesto2
	, ew_cxc_transacciones.saldo
	, ew_cxc_transacciones.comentario
	, [concepto_cuenta] = c.contabilidad
	, ew_cxc_transacciones.vencimiento
	, [tipocambio_dof] = dbo.fn_ban_obtenerTC(ew_cxc_transacciones.idmoneda, ew_cxc_transacciones.fecha)
	, ew_cxc_transacciones.idforma
	, ew_cxc_transacciones.idmetodo
	, ew_cxc_transacciones.cfd_iduso
	, ew_cxc_transacciones.idrelacion
FROM 
	ew_cxc_transacciones
	LEFT JOIN ew_cxc_saldos_actual csa 
		ON csa.idcliente = ew_cxc_transacciones.idcliente 
		AND csa.idmoneda = ew_cxc_transacciones.idmoneda
	LEFT JOIN conceptos AS c 
		ON c.idconcepto = ew_cxc_transacciones.idconcepto
WHERE  
	ew_cxc_transacciones.idtran = @idtran 

----------------------------------------------------
-- 3) ew_cxc_transacciones_rel
----------------------------------------------------

SELECT
	[Folio_dr] = dr.folio
	, [Fecha_dr] = dr.fecha
	, [Estado_dr] = [dbo].[fn_sys_estadoActualNombre](dr.idtran)
	, [Documento_dr] = [dbo].[_sys_fnc_objetoGrupoNombre](dr.idtran)
	, [uuid_dr] = cct.cfdi_UUID
	, [idtran2] = ctr.idtran2
	, [idrelacion] = ISNULL(NULLIF(ctr.idrelacion, 0), d.idrelacion)
	, [idr] = ctr.idr
	, [idtran] = ctr.idtran
	, [idmov] = ctr.idmov
FROM
	ew_cxc_transacciones_rel AS ctr
	LEFT JOIN ew_cxc_transacciones AS d
		ON d.idtran = ctr.idtran
	LEFT JOIN ew_cxc_transacciones AS dr
		ON dr.idtran = ctr.idtran2
	LEFT JOIN ew_cfd_comprobantes_timbre AS cct
		ON cct.idtran = dr.idtran
WHERE
	ctr.idtran = @idtran

----------------------------------------------------
-- 10) ew_ven_transacciones_mov
----------------------------------------------------
SELECT
	ew_ven_transacciones_mov.idtran
	, ew_ven_transacciones_mov.idr
	, ew_ven_transacciones_mov.consecutivo
	, ew_ven_transacciones_mov.idarticulo
	, ew_ven_transacciones_mov.idalmacen
	, [marca] = m.nombre
	, ew_ven_transacciones_mov.idum
	, [maneja_lote] = a.lotes
	, [mostrar_lote] = ISNULL(SUBSTRING((
		SELECT
			', ' + vtml.lote AS [text()]
		FROM
			ew_ven_transacciones_mov_lotes AS vtml
		WHERE
			vtml.idtran = ew_ven_transacciones_mov.idtran
			AND vtml.idarticulo = ew_ven_transacciones_mov.idarticulo
		FOR XML PATH('')
	), 2, 1000), '')
	, ic.lote
	, ic.fecha_caducidad
	, ew_ven_transacciones_mov.idcapa
	, ew_ven_transacciones_mov.cantidad_autorizada
	, ew_ven_transacciones_mov.cantidad_facturada
	, ew_ven_transacciones_mov.cantidad_surtida
	, ew_ven_transacciones_mov.cantidad_devuelta
	, ew_ven_transacciones_mov.precio_unitario
	, ew_ven_transacciones_mov.descuento1
	, ew_ven_transacciones_mov.descuento2
	, ew_ven_transacciones_mov.descuento3
	, ew_ven_transacciones_mov.importe
	, ew_ven_transacciones_mov.total
	, ew_ven_transacciones_mov.comentario
	, ew_ven_transacciones_mov.idmov
	, ew_ven_transacciones_mov.idmov2
	, ew_ven_transacciones_mov.idtran2
	, [SERIES] = CASE WHEN (dbo.fn_sys_parametro('VEN_SURFAC') <> 0) 
			THEN ew_ven_transacciones_mov.SERIES 
			ELSE 
				dbo.fn_ven_articuloseries(ew_ven_transacciones_mov.idmov) 
			END
	, [OBJIDTRAN] = ew_ven_transacciones_mov.IDTRAN2
	, [CODARTICULO] = A.CODIGO
	, [DESCRIPCION] = A.NOMBRE
	, [referencia] = ord.folio
	, a.nombre_corto

	, ew_ven_transacciones_mov.impuesto1
	, ew_ven_transacciones_mov.impuesto2
	, ew_ven_transacciones_mov.impuesto1_ret
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

	, ew_ven_transacciones_mov.agrupar
	, ew_ven_transacciones_mov.objlevel

	, [clasif_SAT] = CASE WHEN a.idclasificacion_SAT=0 THEN '-Sin Clasif.-' ELSE ISNULL(csat.clave,'-Sin Clasif.-') END
FROM 
	ew_ven_transacciones_mov
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = ew_ven_transacciones_mov.idarticulo
	LEFT JOIN ew_ven_ordenes AS ord 
		ON ord.idtran = ew_ven_transacciones_mov.idtran2 
	LEFT JOIN ew_inv_capas AS ic 
		ON ew_ven_transacciones_mov.idcapa = ic.idcapa 
		AND ew_ven_transacciones_mov.idarticulo = ic.idarticulo
	LEFT JOIN ew_cat_marcas AS m 
		ON a.idmarca=m.idmarca

	LEFT JOIN ew_ven_transacciones AS vt
		ON vt.idtran = ew_ven_transacciones_mov.idtran
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = vt.idsucursal
	LEFT JOIN ew_cat_impuestos AS ci
		ON ci.idimpuesto = (CASE WHEN a.idimpuesto1 = 0 THEN s.idimpuesto ELSE a.idimpuesto1 END)

	LEFT JOIN ew_cfd_sat_clasificaciones csat
		ON csat.idclasificacion = a.idclasificacion_sat
WHERE  
	ew_ven_transacciones_mov.idtran = @idtran 

----------------------------------------------------
-- 20) ew_ven_transacciones_pagos
----------------------------------------------------
SELECT
	[consecutivo] = vtp.consecutivo
	, vtp.idtran
	, vtp.idtran2
	, vtp.idmov
	, vtp.idmov2
	, vtp.idforma
	, [forma_fecha] = ct.fecha
	, [forma_referencia] = ct.folio
	, [clabe_origen] = vtp.clabe_origen
	, [ref_moneda] = (SELECT nombre FROM ew_ban_monedas WHERE idmoneda = ct.idmoneda)
	, [saldo_ref]=ct.saldo
	, vtp.forma_moneda
	, forma_tipocambio
	, vtp.subtotal
	, vtp.impuesto1
	, vtp.total
	, vtp.comentario
	------ por Vladimir (Feb. 07, 2018) --------------
	, [objidtran] = (
		CASE 
			WHEN vtp.idtran2 = 0 THEN pago_b.idtran 
			ELSE vtp.idtran2 
		END
	)
	, [folio_pago] = ISNULL(pago.folio,'')
FROM 
	ew_ven_Transacciones_pagos AS vtp
	LEFT JOIN ew_cxc_transacciones AS ct ON ct.idtran = vtp.idtran
	LEFT JOIN ew_cxc_transacciones_mov AS ctm ON ctm.idtran2 = ct.idtran AND ctm.importe2 = vtp.total
	LEFT JOIN ew_cxc_transacciones AS pago ON pago.idtran = ctm.idtran
	LEFT JOIN ew_ban_transacciones AS pago_b ON pago_b.idtran = pago.idtran
WHERE
	pago.cancelado = 0
	AND vtp.idtran = @idtran

----------------------------------------------------
-- 40) ew_ct_impuestos_transacciones
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

----------------------------------------------------
-- 89) contabilidad
----------------------------------------------------
SELECT 
	*
FROM
	contabilidad 
WHERE  
	contabilidad.idtran2=@idtran 

----------------------------------------------------
-- 90) bitacora
----------------------------------------------------
SELECT
	fechahora
	, codigo
	, nombre
	, usuario_nombre
	, host
	, comentario
FROM 
	bitacora
 
WHERE  
	bitacora.idtran = @idtran 
ORDER BY 
	fechahora 

----------------------------------------------------
-- 101) tracking
----------------------------------------------------
SELECT
	*
FROM
	fn_sys_tracking(@idtran)

----------------------------------------------------
-- 102) ew_ven_transacciones_mov_lotes
----------------------------------------------------
SELECT
	vtml.consecutivo
	,vtml.lote
	,[codarticulo] = a.codigo
	,[nombre] = a.nombre
	,vtml.idarticulo
	,vtml.cantidad
	,vtml.comentario
FROM 
	ew_ven_transacciones_mov_lotes AS vtml
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vtml.idarticulo
WHERE
	vtml.idtran = @idtran

----------------------------------------------------
-- 110) ew_cfd_comprobantes_cancelados
----------------------------------------------------
SELECT
	idtran
	, [acuse] = ISNULL(acuse, '')
FROM
	ew_cfd_comprobantes_cancelados
WHERE
	idtran = @idtran
GO
