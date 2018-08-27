USE db_comercial_final
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 20170501
-- Description:	
-- Procedimiento para desplegar la transaccion EOR1 
-- y mejorar el rendimiento evitando los cargarDoc
-- =============================================
ALTER PROCEDURE [dbo].[_xac_EOR1_cargarDoc]
	@idtran AS INT
AS

SET NOCOUNT ON

----------------------------------------------------
-- 1)  ew_ven_ordenes
----------------------------------------------------
SELECT
	[referencia] = vo.transaccion
	,[transaccion] = vo.transaccion
	,[idsucursal] = vo.idsucursal
	,[suc_idimpuesto] = s.idimpuesto
	,[suc_impuesto] = imps.valor
	,[idalmacen] = vo.idalmacen
	,[fecha] = vo.fecha
	,[folio] = vo.folio
	,[idconcepto] = vo.idconcepto
	,[codcliente] = c.codigo
	,[idcliente] = vo.idcliente
	,[idu] = vo.idu
	,[idr] = vo.idr
	,[idtran] = vo.idtran
	,[remisionar] = vo.remisionar
	,[cancelado] = vo.cancelado
	,[cancelado_fecha] = vo.cancelado_fecha
	,[subtotal] = vo.subtotal
	,[impuesto1] = vo.impuesto1
	,[impuesto2] = vo.impuesto2
	,[impuesto1_ret] = vo.impuesto1_ret
	,[total] = vo.total
	,[costo] = vo.costo
	,[gastos] = vo.gastos
	,[comentario] = vo.comentario
	,[idmoneda] = vo.idmoneda
	,[tipocambio] = vo.tipocambio
	,[idimpuesto1] = vo.idimpuesto1
	,[iva] = (imp.valor/.01)
	,[idlista] = vo.idlista
	,[idmedioventa] = vo.idmedioventa
	,[dias_entrega] = vo.dias_entrega
	,[dias_pp] = p.descuento_pp1
	,[t_credito] = ct.credito
	,[CREDITO] = (CASE WHEN vo.CREDITO = 0 THEN 0 ELSE 1 END)
	,[CREDITO_PLAZO] = vo.CREDITO_PLAZO
	,[CLIENTE_LIMITE] = CT.CREDITO_LIMITE
	,[CLIENTE_SALDO] = CSA.SALDO
	,[CLIENTE_CREDITO] = (CASE WHEN ( (ISNULL(CT.CREDITO_LIMITE, 0) - ISNULL(CSA.SALDO, 0))) < 0 THEN 0 ELSE (ISNULL(CT.CREDITO_LIMITE, 0) - ISNULL(CSA.SALDO, 0)) END)
	,[IDFACTURACION] = vo.IDFACTURACION
	,[IDUBICACION] = vo.IDUBICACION
	,[IDVENDEDOR] = vo.idvendedor
	,[VENDEDOR] = V.NOMBRE
	,[IDCONTACTO] = vo.IDCONTACTO
	,[objerrmsg] = (CASE WHEN ct.credito_suspendido = 1 THEN 'El cliente tiene CREDITO SUSPENDIDO !!!!' ELSE '' END)
	,[xcliente] = (
		RTRIM(c.nombre) + '
		Tel: ' + c.telefono1 + ' ' + c.telefono2  + ' 
		Fax: ' + c.fax
	)
	,[xcredito] = (
		ISNULL(p.nombre,'') + '
		' + CASE WHEN ct.credito=1 THEN 'CREDITO' + (CASE WHEN ct.credito_suspendido=1 THEN ' SUSPENDIDO' ELSE '' END) ELSE 'CONTADO'  END + '
		Saldo Actual: ' + CONVERT(VARCHAR(50),CSA.saldo) + '
		Límite: ' + CONVERT(VARCHAR(50),ct.credito_limite) + '
		Disponible: ' + CONVERT(VARCHAR(50),ct.credito_limite-CSA.saldo)
	)
	,[xcontacto] = (
		ISNULL(RTRIM(con.nombre),'') + ISNULL( ' ' + con.apellido,'') + ' 
		Horario: ' + ISNULL(cc.horario,'') + '
		Telefono:  ' + ISNULL(tel.dato1,'')  + ' 
		Email: ' + ISNULL(eml.dato1,'')
	)
	,[xfacturacion] = (
		ISNULL(RTRIM(f.razon_social),'') + '
		RFC: ' + ISNULL(f.rfc,'') + '
		' + ISNULL(f.calle,'') + ' ' + ISNULL(f.noExterior,'')  + ' 
		' + ISNULL(f.colonia,'') + ' ' + ISNULL(f.codpostal,'') + '
		' + dbo.fn_sys_localidad(f.idciudad)
	)
	,[idimpuesto1] = (CASE WHEN i1.idimpuesto NOT IN (1,2) THEN  i1.idimpuesto ELSE (CASE WHEN 0.16>i1.valor THEN 1 ELSE f.idimpuesto1 END) END)
	,[iva] = ROUND((CASE WHEN i1.idimpuesto NOT IN (1,2) THEN  i1.valor ELSE (CASE WHEN 0.16>i1.valor THEN 0.16 ELSE i1.valor END) END)/.01,2)
	,[xubicacion] = (
		ISNULL(RTRIM(u.nombre),'') + '
		' + ISNULL(u.direccion1,'') + ' ' + ISNULL(u.direccion2,'')  + ' 
		' + ISNULL(u.colonia,'') + '  ' + ISNULL(u.codpostal,'') + '
		' + dbo.fn_sys_localidad(u.idciudad)
	)
	,[idrelacion] = 4
	,[entidad_codigo] = c.codigo
	,[entidad_nombre] = c.nombre
	,[identidad] = c.idcliente
	,[politica] = ISNULL(p.nombre,'Sin Asignación')
	,[faut] = [dbo].[fn_sys_obtenerDato]('GLOBAL', 'VENTA_FACT_AUT')
	,[cliente_orden] = vo.cliente_orden
FROM 
	ew_ven_ordenes AS vo
	LEFT JOIN vew_clientes AS c 
		ON C.IDCLIENTE = vo.IDCLIENTE
	LEFT JOIN EW_CLIENTES_TERMINOS AS CT 
		ON CT.IDCLIENTE = vo.IDCLIENTE
	LEFT JOIN EW_SYS_SUCURSALES AS S 
		ON S.IDSUCURSAL = vo.IDSUCURSAL
	LEFT JOIN EW_CXC_SALDOS_ACTUAL AS CSA 
		ON CSA.IDCLIENTE = vo.IDCLIENTE AND CSA.IDMONEDA = vo.IDMONEDA
	LEFT JOIN EW_CAT_IMPUESTOS AS IMP 
		ON IMP.IDIMPUESTO = vo.IDIMPUESTO1
	LEFT JOIN EW_CAT_IMPUESTOS AS IMPS 
		ON IMPS.IDIMPUESTO = S.IDIMPUESTO
	LEFT JOIN EW_VEN_VENDEDORES AS V 
		ON V.IDVENDEDOR = vo.IDVENDEDOR
	LEFT JOIN ew_ven_politicas AS p 
		ON p.idpolitica=ct.idpolitica 
	LEFT JOIN ew_ban_monedas AS m 
		ON m.idmoneda=c.idmoneda	
	LEFT JOIN ew_clientes_contactos AS cc 
		ON cc.idcliente = vo.idcliente AND cc.idcontacto = vo.idcontacto
	LEFT JOIN ew_cat_contactos AS con 
		ON con.idcontacto = cc.idcontacto
	LEFT JOIN ew_cat_contactos_contacto AS tel 
		ON tel.idcontacto = con.idcontacto AND tel.tipo =1
	LEFT JOIN ew_cat_contactos_contacto AS eml 
		ON eml.idcontacto = con.idcontacto AND eml.tipo =4
	LEFT JOIN ew_clientes_facturacion AS f 
		ON f.idcliente = vo.idcliente AND f.idfacturacion = vo.idfacturacion
	LEFT JOIN ew_cat_impuestos AS i1 
		ON i1.idimpuesto = f.idimpuesto1
	LEFT JOIN ew_clientes_ubicaciones AS u 
		ON u.idcliente = vo.idcliente AND u.idubicacion = vo.idubicacion
WHERE  
	vo.idtran = @idtran 
 
----------------------------------------------------
-- 2)  ew_ven_ordenes_mov
----------------------------------------------------
SELECT
	[consecutivo] = ew_ven_ordenes_mov.consecutivo
	,[codarticulo] = a.codigo
	,[idarticulo] = ew_ven_ordenes_mov.idarticulo
	,[descripcion] = a.nombre
	,[idum] = ew_ven_ordenes_mov.idum
	,[existencia] = ew_ven_ordenes_mov.existencia
	,[cantidad_ordenada] = ew_ven_ordenes_mov.cantidad_ordenada
	,[cantidad_autorizada] = ew_ven_ordenes_mov.cantidad_autorizada
	,[cantidad_devuelta] = ew_ven_ordenes_mov.cantidad_devuelta
	,[cantidad_porFacturar] =  ew_ven_ordenes_mov.cantidad_porFacturar
	,[cantidad_porSurtir] = ew_ven_ordenes_mov.cantidad_porSurtir
	,[idmoneda_m] = ISNULL(vlm.idmoneda,0)
	,[tipocambio_m] = ISNULL(dbo.fn_ban_tipocambio(vlm.idmoneda,0),1)
	,[precio_congelado] = ISNULL(vlm.precio_congelado,0)
	,[precio_unitario_m] = ew_ven_ordenes_mov.precio_unitario
	,[precio_unitario_m2] = ew_ven_ordenes_mov.precio_unitario
	,[precio_unitario] = ew_ven_ordenes_mov.precio_unitario
	,[max_descuento1] = pv.descuento_limite
	,[max_descuento2] = pv.descuento_linea
	,[descuentos] = ew_ven_ordenes_mov.descuentos
	,[descuento1] = ew_ven_ordenes_mov.descuento1
	,[descuento2] = ew_ven_ordenes_mov.descuento2
	,[descuento3] = ew_ven_ordenes_mov.descuento3
	,[idimpuesto1] = ew_ven_ordenes_mov.idimpuesto1
	,[idimpuesto1_valor] = ew_ven_ordenes_mov.idimpuesto1_valor
	,[idimpuesto2] = ew_ven_ordenes_mov.idimpuesto2
	,[idimpuesto2_valor] = ew_ven_ordenes_mov.idimpuesto2_valor
	,[idimpuesto1_ret] = ew_ven_ordenes_mov.idimpuesto1_ret
	,[idimpuesto1_ret_valor] = ew_ven_ordenes_mov.idimpuesto1_ret_valor
	,[importe] = ew_ven_ordenes_mov.importe
	,[impuesto1] = ew_ven_ordenes_mov.impuesto1
	,[impuesto2] = ew_ven_ordenes_mov.impuesto2
	,[impuesto1_ret] = ew_ven_ordenes_mov.impuesto1_ret
	,[total] = ew_ven_ordenes_mov.total
	,[comentario] = ew_ven_ordenes_mov.comentario
	,[idr] = ew_ven_ordenes_mov.idr
	,[idtran] = ew_ven_ordenes_mov.idtran
	,[idmov] = ew_ven_ordenes_mov.idmov
	,[idmov2] = ew_ven_ordenes_mov.idmov2
	,[objidtran] = CONVERT (INT,idmov2)
	,[cantidad_mayoreo] = s.mayoreo
	,[descuento_pp1] = ew_ven_ordenes_mov.descuento_pp1
	,[descuento_pp2] = ew_ven_ordenes_mov.descuento_pp2
	,[descuento_pp3] = ew_ven_ordenes_mov.descuento_pp3

	,[cuenta_sublinea] = subl.contabilidad
	,[objlevel] = ew_ven_ordenes_mov.objlevel

	,[clasif_SAT] = (CASE WHEN a.idclasificacion_SAT=0 THEN '-Sin Clasif.-' ELSE ISNULL(csat.clave,'-Sin Clasif.-') END)
FROM 
	ew_ven_ordenes_mov
	LEFT JOIN ew_ven_ordenes AS vo 
		ON vo.idtran = ew_ven_ordenes_mov.idtran
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = ew_ven_ordenes_mov.idarticulo
	LEFT JOIN ew_articulos_sucursales AS s 
		ON s.idarticulo = ew_ven_ordenes_mov.idarticulo 
		AND s.idsucursal = vo.idsucursal
	LEFT JOIN ew_ven_ordenes AS doc 
		ON doc.idtran = ew_ven_ordenes_mov.idtran
	LEFT JOIN ew_ven_listaprecios_mov AS vlm 
		ON vlm.idarticulo = a.idarticulo 
		AND vlm.idlista = doc.idlista
	LEFT JOIN ew_clientes_terminos AS ct 
		ON ct.idcliente = doc.idcliente 
	LEFT JOIN ew_ven_politicas AS pv 
		ON pv.idpolitica = ct.idpolitica	
	LEFT JOIN ew_articulos_niveles AS subl 
		ON subl.codigo = a.nivel3
	LEFT JOIN ew_cfd_sat_clasificaciones AS csat
		ON csat.idclasificacion = a.idclasificacion_sat
WHERE
	ew_ven_ordenes_mov.idtran = @idtran 
 
----------------------------------------------------
-- Impuestos
----------------------------------------------------
SELECT
	[codigo] = a.codigo
	,[nombre] = a.nombre
	,[idtasa] = citr.idtasa
	,[tasa] = cit.tasa
	,[base_proporcion] = cit.base_proporcion
	,[base] = citr.base
	,[importe] = citr.importe
	,[idr] = citr.idr
	,[idtran] = citr.idtran
	,[idmov] = citr.idmov
FROM 
	ew_ct_impuestos_transacciones AS citr
	LEFT JOIN ew_ven_ordenes_mov AS vom
		ON vom.idmov = citr.idmov
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vom.idarticulo
	LEFT JOIN ew_cat_impuestos_tasas AS cit
		ON cit.idtasa = citr.idtasa
WHERE 
	citr.idtran = @idtran

----------------------------------------------------
-- Tracking
----------------------------------------------------
SELECT
	*
FROM
	tracking 
WHERE  
	tracking.idtran = @idtran 
 
----------------------------------------------------
-- 4)  bitacora
----------------------------------------------------
SELECT
	fechahora, codigo, nombre, usuario_nombre, host, comentario
FROM 
	bitacora
 
WHERE  
	bitacora.idtran = @idtran 
ORDER BY 
	fechahora
GO

