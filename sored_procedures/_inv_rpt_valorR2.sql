USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20161119
-- Description:	Valor del inventario por capa por almacen
-- =============================================
ALTER PROCEDURE _inv_rpt_valorR2
	@idsucursal AS INT = 0
	,@idalmacen AS INT = 0
	,@codarticulo AS VARCHAR(30) = ''
	,@codproveedor AS VARCHAR(30) = ''
	,@idmarca AS INT = 0
AS

SET NOCOUNT ON

SELECT
	[sucursal] = s.nombre
	,[almacen] = alm.nombre

	,[proveedor_codio] = ISNULL(p1.codigo, ISNULL(p2.codigo, 'NA'))
	,[proveedor] = ISNULL(p1.nombre, ISNULL(p2.nombre, '-No especificado-'))
	,[marca] = ISNULL(m.nombre, '-No especificado-')
	,[serie] = ic.serie

	,[codarticulo] = a.codigo
	,[articulo] = a.nombre

	,ice.existencia
	,[unidad] = ISNULL(um.codigo, 'NA')
	,[costo_unitario] = (ic.costo / ic.cantidad)
	,[valor] = ice.costo
	
	,ice.idcapa
	,ic.idtran
FROM
	ew_inv_capas_existencia AS ice
	LEFT JOIN ew_inv_capas AS ic
		ON ic.idcapa = ice.idcapa
	LEFT JOIN ew_inv_almacenes AS alm
		ON alm.idalmacen = ice.idalmacen
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = alm.idsucursal
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = ic.idarticulo
	LEFT JOIN ew_cat_marcas AS m
		ON m.idmarca = a.idmarca
	LEFT JOIN ew_cat_unidadesMedida AS um 
		ON um.idum = a.idum_almacen
	LEFT JOIN ew_inv_movimientos AS im
		ON im.tipo = 1
		AND im.idcapa = ice.idcapa
		AND im.idtran = ic.idtran
	LEFT JOIN ew_inv_transacciones_mov AS itm
		ON itm.idmov = im.idmov2
	LEFT JOIN ew_com_transacciones_mov AS ctm
		ON ctm.idmov = itm.idmov2
	LEFT JOIN ew_com_ordenes_mov AS com
		ON com.idmov = ctm.idmov2
	LEFT JOIN ew_com_ordenes AS co
		ON co.idtran = com.idtran
	LEFT JOIN ew_proveedores AS p1
		ON p1.idproveedor = co.idproveedor
	LEFT JOIN ew_articulos_sucursales AS [as]
		ON [as].idarticulo = ic.idarticulo
		AND [as].idsucursal = alm.idsucursal
	LEFT JOIN ew_proveedores AS p2
		ON p2.idproveedor = [as].idproveedor
WHERE
	ice.existencia > 0
	AND alm.idsucursal = (CASE WHEN @idsucursal = 0 THEN alm.idsucursal ELSE @idsucursal END)
	AND ice.idalmacen = (CASE WHEN @idalmacen = 0 THEN ice.idalmacen ELSE @idalmacen END)
	AND a.codigo = (CASE WHEN @codarticulo = '' THEN a.codigo ELSE @codarticulo END)
	AND ISNULL(p1.codigo, ISNULL(p2.codigo, 'NA')) = (CASE WHEN @codproveedor = '' THEN ISNULL(p1.codigo, ISNULL(p2.codigo, 'NA')) ELSE @codproveedor END)
	AND a.idmarca = (CASE WHEN @idmarca = 0 THEN a.idmarca ELSE @idmarca END)
ORDER BY
	alm.idsucursal
	,ice.idalmacen
	,a.codigo
GO
