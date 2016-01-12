USE [db_comercial_final]
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
 
----------------------------------------------------
-- 1)  ew_ven_transacciones
----------------------------------------------------
SELECT
	ew_ven_transacciones.transaccion
	,[referencia] = ISNULL(vd.folio, '')
	,[idtran2] =ew_ven_transacciones.idtran2
	,ew_ven_transacciones.idsucursal
	,ew_ven_transacciones.idalmacen
	,[codcliente] = c.codigo
	,ew_ven_transacciones.idconcepto
	,ew_ven_transacciones.idcliente
	,ew_ven_transacciones.fecha
	,ew_ven_transacciones.folio
	,ew_ven_transacciones.idu
	,ew_ven_transacciones.idr
	,ew_ven_transacciones.idtran
	,ew_ven_transacciones.cancelado
	,ew_ven_transacciones.cancelado_fecha
	,[cliente] = c.nombre
	,[idfacturacion] = ew_ven_transacciones.idfacturacion
	,[facturara]= cf.razon_social
	,[rfc]=cf.rfc
	,[direccion] = cf.calle + ISNULL(' '+cf.noExterior,'') + ISNULL(' '+cf.noInterior,'') 
	,[colonia] = cf.colonia
	,[ciudad] = fac.ciudad
	,[estado] = fac.estado
	,[codigopostal] = cf.codpostal
	,cf.email
	,[contacto] = cc.nombre
	,[horario] = ecc.horario
	,[t_credito] = ct.credito
	,[credito] = ew_ven_transacciones.credito
	,[credito_plazo] = ew_ven_transacciones.credito_plazo
	,cliente_limite = ISNULL(ct.credito_limite, 0)
	,ew_ven_transacciones.dias_pp1
	,ew_ven_transacciones.dias_pp2
	,ew_ven_transacciones.dias_pp3
	,ew_ven_transacciones.descuento_pp1
	,ew_ven_transacciones.descuento_pp2
	,ew_ven_transacciones.descuento_pp3
	,ew_ven_transacciones.idmoneda
	,ew_ven_transacciones.tipocambio
	,ew_ven_transacciones.subtotal
	,ew_ven_transacciones.impuesto1
	,ew_ven_transacciones.impuesto2
	,ew_ven_transacciones.total
	,ew_ven_transacciones.comentario
	,idrelacion = 4
	,entidad_codigo = c.codigo
	,entidad_nombre = c.nombre
	,identidad = c.idcliente
	,cf.contabilidad
	,[metodoDePago]=RTRIM(c.cfd_metodoDePago) + ' ' + RTRIM(c.cfd_NumCtaPago)
	,ew_ven_transacciones.guia_folio
	,ew_ven_transacciones.guia_importe
	,ew_ven_transacciones.idproveedor
	,p.nombre AS acreedor
	,UUID=ISNULL(timbres.cfdi_UUID,'')

	,ew_ven_transacciones.idvendedor
FROM 
	ew_ven_transacciones
	LEFT JOIN ew_ven_ordenes AS vd ON vd.idtran = ew_ven_transacciones.idtran2
	LEFT JOIN ew_clientes AS c ON c.idcliente = ew_ven_transacciones.idcliente
	LEFT JOIN ew_clientes_contactos AS ecc ON ecc.idcliente = c.idcliente
	LEFT JOIN ew_cat_contactos AS cc ON cc.idcontacto = ecc.idcontacto
	LEFT JOIN ew_clientes_facturacion AS cf ON cf.idcliente=ew_ven_transacciones.idcliente AND cf.idfacturacion = ew_ven_transacciones.idfacturacion
	LEFT JOIN ew_clientes_terminos AS ct ON ct.idcliente = c.idcliente
	LEFT JOIN ew_sys_ciudades fac ON fac.idciudad = cf.idciudad 
	LEFT JOIN dbo.ew_proveedores AS p ON p.idproveedor=ew_ven_transacciones.idproveedor
	LEFT JOIN ew_cfd_comprobantes_timbre timbres ON timbres.idtran = ew_ven_transacciones.idtran
WHERE  
	ew_ven_transacciones.idtran=@idtran 
 
----------------------------------------------------
-- 2)  ew_cxc_transacciones
----------------------------------------------------
SELECT
	ew_cxc_transacciones.transaccion
	,ew_cxc_transacciones.idcliente
	,ew_cxc_transacciones.fecha
	,ew_cxc_transacciones.folio
	,ew_cxc_transacciones.idu
	,ew_cxc_transacciones.idr
	,ew_cxc_transacciones.idtran
	,ew_cxc_transacciones.cancelado
	,ew_cxc_transacciones.cancelado_fecha
	,ew_cxc_transacciones.idfacturacion
	,cliente_saldo = ISNULL(csa.saldo, 0)
	,ew_cxc_transacciones.idimpuesto1
	,ew_cxc_transacciones.idimpuesto1_valor
	,ew_cxc_transacciones.subtotal
	,ew_cxc_transacciones.impuesto1	
	,ew_cxc_transacciones.impuesto2
	,ew_cxc_transacciones.saldo
	,ew_cxc_transacciones.comentario
	,[concepto_cuenta]=c.contabilidad
	,ew_cxc_transacciones.vencimiento
	,[tipocambio_dof] = dbo.fn_ban_obtenerTC(ew_cxc_transacciones.idmoneda, ew_cxc_transacciones.fecha)
FROM ew_cxc_transacciones
LEFT JOIN ew_cxc_saldos_actual csa ON csa.idcliente = ew_cxc_transacciones.idcliente AND csa.idmoneda = ew_cxc_transacciones.idmoneda
LEFT JOIN conceptos c ON c.idconcepto=ew_cxc_transacciones.idconcepto
	

 
WHERE  
	ew_cxc_transacciones.idtran=@idtran 
 
----------------------------------------------------
-- 3)  ew_ven_transacciones_mov
----------------------------------------------------
SELECT
	ew_ven_transacciones_mov.idtran
	,ew_ven_transacciones_mov.idr
	,ew_ven_transacciones_mov.consecutivo
	,ew_ven_transacciones_mov.idarticulo
	,ew_ven_transacciones_mov.idalmacen
	,[marca] = m.nombre
	,ew_ven_transacciones_mov.idum
	,[maneja_lote] = a.lotes
	,ic.lote
	,ic.fecha_caducidad
	,ew_ven_transacciones_mov.idcapa
	,ew_ven_transacciones_mov.cantidad_autorizada
	,ew_ven_transacciones_mov.cantidad_facturada
	,ew_ven_transacciones_mov.cantidad_surtida
	,ew_ven_transacciones_mov.cantidad_devuelta
	,ew_ven_transacciones_mov.precio_unitario
	,ew_ven_transacciones_mov.descuento1
	,ew_ven_transacciones_mov.descuento2
	,ew_ven_transacciones_mov.descuento3
	,ew_ven_transacciones_mov.importe
	,ew_ven_transacciones_mov.idimpuesto1
	,ew_ven_transacciones_mov.idimpuesto1_valor
	,ew_ven_transacciones_mov.idimpuesto2
	,ew_ven_transacciones_mov.idimpuesto2_valor
	,ew_ven_transacciones_mov.idimpuesto1_ret
	,ew_ven_transacciones_mov.idimpuesto1_ret_valor
	,ew_ven_transacciones_mov.impuesto1
	,ew_ven_transacciones_mov.impuesto2
	,ew_ven_transacciones_mov.impuesto1_ret
	,ew_ven_transacciones_mov.total
	,ew_ven_transacciones_mov.comentario
	,ew_ven_transacciones_mov.idmov
	,ew_ven_transacciones_mov.idmov2
	,ew_ven_transacciones_mov.idtran2
	,[SERIES] = CASE WHEN (dbo.fn_sys_parametro('VEN_SURFAC') <> 0) 
			THEN ew_ven_transacciones_mov.SERIES 
			ELSE 
				dbo.fn_ven_articuloseries(ew_ven_transacciones_mov.idmov) 
			END
	,[OBJIDTRAN] = ew_ven_transacciones_mov.IDTRAN2
	,[CODARTICULO] = A.CODIGO
	,[DESCRIPCION] = A.NOMBRE
	,[referencia] = ord.folio
	,a.nombre_corto
FROM 
	ew_ven_transacciones_mov
	LEFT JOIN ew_articulos a ON a.idarticulo = ew_ven_transacciones_mov.idarticulo
	LEFT JOIN ew_ven_ordenes ord ON ord.idtran = ew_ven_transacciones_mov.idtran2 
	LEFT JOIN ew_inv_capas ic ON ew_ven_transacciones_mov.idcapa = ic.idcapa AND ew_ven_transacciones_mov.idarticulo = ic.idarticulo
	LEFT JOIN ew_cat_marcas m ON a.idmarca=m.idmarca
WHERE  
	ew_ven_transacciones_mov.idtran=@idtran 
 
----------------------------------------------------
-- 4)  ew_ven_transacciones_pagos
----------------------------------------------------
SELECT
	[consecutivo] = ew_ven_transacciones_pagos.consecutivo
	,ew_ven_transacciones_pagos.idtran
	,ew_ven_transacciones_pagos.idtran2
	,ew_ven_transacciones_pagos.idmov
	,ew_ven_transacciones_pagos.idmov2
	,ew_ven_transacciones_pagos.idforma
	,[forma_fecha] = ct.fecha
	,[forma_referencia] = ct.folio
	,[ref_moneda]=(SELECT nombre FROM ew_ban_monedas WHERE idmoneda=ct.idmoneda)
	,[saldo_ref]=ct.saldo
	,forma_moneda
	,forma_tipocambio
	,ew_ven_transacciones_pagos.subtotal
	,ew_ven_transacciones_pagos.impuesto1
	,ew_ven_transacciones_pagos.total
	,ew_ven_transacciones_pagos.comentario
FROM 
	ew_ven_transacciones_pagos
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = ew_ven_transacciones_pagos.idtran
WHERE
	ew_ven_transacciones_pagos.cancelado = 0 
 AND  
	ew_ven_transacciones_pagos.idtran=@idtran 
 
----------------------------------------------------
-- 5)  contabilidad
----------------------------------------------------
SELECT 
	*
FROM
	contabilidad 
WHERE  
	contabilidad.idtran2=@idtran 
 
----------------------------------------------------
-- 6)  bitacora
----------------------------------------------------
SELECT
	fechahora, codigo, nombre, usuario_nombre, host, comentario
FROM 
	bitacora
 
WHERE  
	bitacora.idtran=@idtran 
ORDER BY 
	fechahora 
----------------------------------------------------
-- 7)  tracking
----------------------------------------------------
SELECT
		*
	FROM
		tracking 
WHERE  
	tracking.idtran=@idtran 
GO
