USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160119
-- Description:	Formato conversion
-- =============================================
ALTER PROCEDURE _inv_rpt_GDT4
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	id.idtran

	,id.fecha
	,id.folio
	,[almacen] = alm.nombre
	,[sucursal] = s.nombre

	,[origen_idarticulo] = idm1.idarticulo
	,[origen_codigo] = a1.codigo
	,[origen_nombre] = a1.nombre
	,[origen_unidad] = cum1.nombre
	,[origen_cantidad] = idm1.cantidad
	,[origen_costo_unitario] = itm1.costo / idm1.cantidad
	,[origen_costo] = itm1.costo

	,[destino_idarticulo] = idm2.idarticulo
	,[destino_codigo] = a2.codigo
	,[destino_nombre] = a2.nombre
	,[destino_unidad] = cum2.nombre
	,[destino_cantidad] = idm2.cantidad
	,[destino_costo_unitario] = itm2.costo / idm2.cantidad
	,[destino_costo] = itm2.costo
	
	,[usuario] = u.nombre
	,id.comentario
	,[id] = ROW_NUMBER()  OVER (ORDER BY idm2.consecutivo)
FROM 
	ew_inv_documentos AS id
	LEFT JOIN ew_inv_almacenes AS alm
		ON alm.idalmacen = id.idalmacen
	LEFT JOIN ew_sys_sucursales As s
		ON s.idsucursal = alm.idsucursal
	LEFT JOIN ew_inv_documentos_mov AS idm1
		ON idm1.consecutivo = 0 
		AND idm1.idtran = id.idtran
	LEFT JOIN eW_inv_documentos_mov AS idm2
		ON idm2.consecutivo > 0
		AND idm2.idtran = id.idtran
	LEFT JOIN evoluware_usuarios AS u
		ON u.idu = id.idu
	LEFT JOIN ew_articulos AS a1
		ON a1.idarticulo = idm1.idarticulo
	LEFT JOIN ew_cat_unidadesMedida AS cum1
		ON cum1.idum = a1.idum_almacen
	LEFT JOIN ew_inv_transacciones_mov AS itm1
		ON itm1.tipo = 2
		AND itm1.idmov2 = idm1.idmov
	LEFT JOIN ew_articulos AS a2
		ON a2.idarticulo = idm2.idarticulo
	LEFT JOIN ew_cat_unidadesMedida AS cum2
		ON cum2.idum = a2.idum_almacen
	LEFT JOIN ew_inv_transacciones_mov AS itm2
		ON itm2.tipo = 1
		AND itm2.idmov2 = idm2.idmov
WHERE 
	id.idtran = @idtran
GO
