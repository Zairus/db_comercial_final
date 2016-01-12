USE [db_comercial_final]
GO
-- =============================================
-- Autor:			Laurence Saavedra
-- Creado el:		Septiembre 2011
-- Modificado en:	
-- Description:		Procedimiento para desplegar la transaccion ECO1 
--					y mejorar el rendimiento evitando los cargarDoc
-- Ejemplo :		EXEC _xac_ECO1_cargarDoc @idtran 
-- =============================================
ALTER PROCEDURE [dbo].[_xac_ECO1_cargarDoc]
	@idtran AS INT
AS

SET NOCOUNT ON
 
----------------------------------------------------
-- 1)  ew_ven_documentos
----------------------------------------------------
SELECT
	
	[transaccion] = ew_ven_documentos.transaccion
	,[idsucursal] = ew_ven_documentos.idsucursal
	,[idalmacen] = ew_ven_documentos.idalmacen
	,[fecha] = ew_ven_documentos.fecha
	,[folio] = ew_ven_documentos.folio
	,ew_ven_documentos.idconcepto
	,[codcliente] = c.codigo
	,[idcliente] = ew_ven_documentos.idcliente
	,[idu] = ew_ven_documentos.idu
	,[idr] = ew_ven_documentos.idr
	,[idtran] = ew_ven_documentos.idtran
	,[cancelado] = ew_ven_documentos.cancelado
	,[cancelado_fecha] = ew_ven_documentos.cancelado_fecha
	,[subtotal] = ew_ven_documentos.subtotal
	,[impuesto1] = ew_ven_documentos.impuesto1
	,[impuesto2] = ew_ven_documentos.impuesto2
	,[total] = ew_ven_documentos.total
	,[costo] = ew_ven_documentos.costo
	,[gastos] = ew_ven_documentos.gastos
	,[comentario] = ew_ven_documentos.comentario
	,[idmoneda] = ew_ven_documentos.idmoneda
	,[tipocambio] = ew_ven_documentos.tipocambio
	,[idimpuesto1] = ew_ven_documentos.idimpuesto1
	,[IVA] = (imp.valor/.01)
	,[idlista] = ew_ven_documentos.idlista
	,[idmedioventa] = ew_ven_documentos.idmedioventa
	,[dias_entrega] = ew_ven_documentos.dias_entrega
	,[t_credito] = ct.credito
	,[credito] = CASE WHEN ew_ven_documentos.credito=0 THEN 0 ELSE 1 END
	,[credito_plazo] = ew_ven_documentos.credito_plazo
	,[cliente_limite] = ct.credito_limite
	,[cliente_saldo] = csa.saldo
	,[cliente_credito] = (CASE WHEN ( (ISNULL(ct.credito_limite, 0) - ISNULL(csa.saldo, 0))) < 0 THEN 0 ELSE (ISNULL(ct.credito_limite, 0) - ISNULL(csa.saldo, 0)) END)
	,[idfacturacion] = ew_ven_documentos.idfacturacion
	,[idubicacion] = ew_ven_documentos.idubicacion
	,[vendedor]=v.nombre
	,[idcontacto] = ew_ven_documentos.idcontacto
	,idrelacion =4
	,entidad_codigo = c.codigo
	,entidad_nombre = c.nombre
	,identidad = c.idcliente
FROM 
	ew_ven_documentos
	LEFT JOIN ew_clientes AS c ON c.idcliente = ew_ven_documentos.idcliente
	LEFT JOIN ew_clientes_terminos AS ct ON ct.idcliente = ew_ven_documentos.idcliente
	LEFT JOIN ew_sys_sucursales AS s ON s.idsucursal = ew_ven_documentos.idsucursal
	LEFT JOIN ew_cxc_saldos_actual AS csa ON csa.idcliente = ew_ven_documentos.idcliente AND csa.idmoneda = ew_ven_documentos.idmoneda
	LEFT JOIN ew_cat_impuestos imp ON imp.idimpuesto = ew_ven_documentos.idimpuesto1
	LEFT JOIN ew_ven_vendedores v ON v.idvendedor = ew_ven_documentos.idvendedor 
WHERE  
	ew_ven_documentos.idtran=@idtran 
 
----------------------------------------------------
-- 2)  ew_ven_documentos_mov
----------------------------------------------------
SELECT
	[consecutivo] = ew_ven_documentos_mov.consecutivo
	,[codarticulo] = a.codigo
	,[idarticulo] = ew_ven_documentos_mov.idarticulo
	,[descripcion] = a.nombre
	,[nombre_corto] = a.nombre_corto
	,[marca] = m.nombre
	,[idum] = ew_ven_documentos_mov.idum
	,[maneja_lote] = a.lotes
	,[existencia] = ew_ven_documentos_mov.existencia
	,[cantidad_solicitada] = ew_ven_documentos_mov.cantidad_solicitada
	,[idmoneda_m]=ISNULL(vlm.idmoneda,0)
	,[tipocambio_m]=ISNULL(dbo.fn_ban_tipocambio(vlm.idmoneda,0),1)
	,[precio_congelado]= ISNULL(vlm.precio_congelado,0)
	,[precio_unitario_m] = (ew_ven_documentos_mov.precio_unitario/ISNULL(dbo.fn_ban_tipocambio(vlm.idmoneda,0),1))/(1/(ISNULL(dbo.fn_ban_tipocambio(doc.idmoneda,0),1)))
	,[precio_unitario_m2] = (ew_ven_documentos_mov.precio_unitario/ISNULL(dbo.fn_ban_tipocambio(vlm.idmoneda,0),1))/(1/(ISNULL(dbo.fn_ban_tipocambio(doc.idmoneda,0),1)))
	,[precio_unitario] = ew_ven_documentos_mov.precio_unitario
	,[max_descuento1] = pv.descuento_limite
	,[max_descuento2] = pv.descuento_linea
	,[descuento1] = ew_ven_documentos_mov.descuento1
	,[descuento2] = ew_ven_documentos_mov.descuento2
	,[descuento3] = ew_ven_documentos_mov.descuento3
	,[idimpuesto1] = ew_ven_documentos_mov.idimpuesto1
	,[idimpuesto1_valor]= ew_ven_documentos_mov.idimpuesto1_valor
	,[idimpuesto2] = ew_ven_documentos_mov.idimpuesto2
	,[idimpuesto2_valor]= ew_ven_documentos_mov.idimpuesto2_valor
	,[importe] = ew_ven_documentos_mov.importe
	,[impuesto1] = ew_ven_documentos_mov.impuesto1
	,[impuesto2] = ew_ven_documentos_mov.impuesto2
	,[total] = ew_ven_documentos_mov.total
	,[comentario] = ew_ven_documentos_mov.comentario
	,[idr] = ew_ven_documentos_mov.idr
	,[idtran] = ew_ven_documentos_mov.idtran
	,[idmov] = ew_ven_documentos_mov.idmov
	,[idmov2] = ew_ven_documentos_mov.idmov2
	,[objidtran] = CONVERT (INT,idmov2)
	,[cantidad_mayoreo] = s.mayoreo
FROM 
	ew_ven_documentos_mov
	LEFT JOIN ew_ven_documentos doc ON doc.idtran =  ew_ven_documentos_mov.idtran
	LEFT JOIN ew_articulos AS a ON a.idarticulo = ew_ven_documentos_mov.idarticulo
	LEFT JOIN ew_articulos_sucursales AS s ON s.idarticulo = ew_ven_documentos_mov.idarticulo AND s.idsucursal = doc.idsucursal
	LEFT JOIN ew_ven_listaprecios_mov AS vlm ON vlm.idarticulo = a.idarticulo AND vlm.idlista = doc.idlista
	LEFT JOIN ew_clientes_terminos ct ON ct.idcliente = doc.idcliente 
	LEFT JOIN ew_ven_politicas pv ON pv.idpolitica = ct.idpolitica	
	LEFT JOIN ew_cat_marcas m ON a.idmarca=m.idmarca

 
WHERE  
	ew_ven_documentos_mov.idtran=@idtran 
 
----------------------------------------------------
-- 3)  bitacora
----------------------------------------------------
SELECT
	fechahora, codigo, nombre, usuario_nombre, host, comentario
FROM 
	bitacora
WHERE  
	bitacora.idtran=@idtran 
ORDER BY 
	fechahora
GO
