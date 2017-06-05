USE db_comercial_final
GO
-- =============================================
-- Author:		Fernanda Corona
-- Create date: ENERO 2010
-- Description:	Reporte Transaccion EOR1 Ventas
-- Orden de Venta EOR1
-- Ejemplo : EXEC _ven_rpt_EOR1 2050
-- =============================================
ALTER PROCEDURE [dbo].[_ven_rpt_EOR1] 
	@idtran INT
AS

SET NOCOUNT ON

SELECT
	[sucursal]=s.nombre
	,[fecha] = d.fecha
	,[folio] = d.folio
	,razon_social=ISNULL(cf.razon_social,'')
	,[cliente] = c.codigo +' - '+ c.nombre
	,[f_direccion] = ISNULL(cf.calle,'')+ ' No. '+ cf.noExterior
	,[f_colonia] = ISNULL(cf.colonia,'')
	,[f_codigopostal] = ISNULL(cf.codpostal,'')
	,[telefono1] = ISNULL(cf.telefono1,'')
	,[telefono2] = ISNULL(cf.telefono2,'')
	,[contacto]=ISNULL(ccc.nombre,'') + ' ' + ISNULL(ccc.apellido,'')
	,[horario] = ISNULL(cc.horario,'')
	,[ciudad]=ISNULL(cd.ciudad+ ', '+cd.estado,'')
	,[vendedor]=ISNULL(v.nombre,'')	
	,[dir_entrega]=ISNULL(u.direccion1+ ' ' + u.direccion2,'')
	,[col_entrega]=ISNULL(u.colonia + ' ' + u.codpostal,'')
	,[cd_entrega]=ISNULL(cde.ciudad+ ', '+cde.estado,'')
	,d.credito
	,d.credito_plazo
	,d.idmoneda
	,[importe] = d.subtotal
	,[impuesto1] = d.impuesto1
	,[total] = d.total
	,[codarticulo] = a.codigo
	,[nombre_corto] = a.nombre_corto
	,[descripcion] = a.nombre
	,[cantidad_ordenada] = dm.cantidad_ordenada
	,dm.cantidad_autorizada
	,[importe_u] = dm.importe
	,[precio_unitario] = dm.precio_unitario
	,[precio_unitario_t] = (CASE WHEN dm.cantidad_autorizada > 0 THEN dm.importe / dm.cantidad_autorizada ELSE dm.importe END)
	,[descuento1] = dm.descuento1
	,[importeM] = dm.importe
	,[impuesto1M] = dm.impuesto1
	,[totalM] = dm.total
	,[comentarioM] = dm.comentario
	,d.comentario
	,[idtran] = dm.idtran
	,cantidad_letra = dbo.fnNum2Letra(d.total,d.idmoneda)

	,[unidad] = um.nombre
FROM 
	ew_ven_ordenes_mov AS dm
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = dm.idarticulo
	LEFT JOIN ew_ven_ordenes AS d 
		ON d.idtran=dm.idtran
	LEFT JOIN ew_clientes AS c 
		ON c.idcliente = d.idcliente
	LEFT JOIN ew_clientes_terminos AS ct 
		ON ct.idcliente = d.idcliente
	LEFT JOIN ew_clientes_contactos AS cc 
		ON cc.idcliente = d.idcliente 
		AND cc.idcontacto = d.idcontacto
	LEFT JOIN ew_clientes_facturacion AS cf 
		ON cf.idcliente = d.idcliente 
		AND cf.idfacturacion = d.idfacturacion
	LEFT JOIN ew_cat_contactos AS ccc 
		ON ccc.idcontacto = cc.idcontacto
	LEFT JOIN ew_clientes_ubicaciones AS u 
		ON u.idubicacion = d.idubicacion 
		AND u.idcliente=d.idcliente
	LEFT JOIN ew_ven_vendedores AS v 
		ON v.idvendedor = d.idvendedor	
	LEFT JOIN ew_sys_sucursales AS s 
		ON s.idsucursal = d.idsucursal
	LEFT JOIN almacen AS alm 
		ON alm.codalm = d.idalmacen
	LEFT JOIN ew_sys_ciudades AS cd
		ON cd.idciudad = cf.idciudad
	LEFT JOIN ew_sys_ciudades AS cde 
		ON cde.idciudad = u.idciudad
	LEFT JOIN ew_cat_unidadesMedida AS um 
		ON um.idum = a.idum_venta
WHERE
	dm.idtran = @idtran
GO
