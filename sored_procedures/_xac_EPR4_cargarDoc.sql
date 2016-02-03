USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160127
-- Description:	Carga datos para actualizar preciod
-- =============================================
ALTER PROCEDURE [dbo].[_xac_EPR4_cargarDoc]
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	[transaccion] = ct.transaccion
	,[idsucursal] = ct.idsucursal
	,[idalmacen] = ct.idalmacen
	,[fecha] = ct.fecha
	,[folio] = ct.folio
	,[idu] = ct.idu
	,[idr] = ct.idr
	,[idtran] = ct.idtran
	,[comentario] = ct.comentario
	,[spa] = ''
FROM
	ew_com_transacciones AS ct
WHERE
	ct.idtran = @idtran

SELECT
	[consecutivo] = ctm.consecutivo
	,[proveedor] = p.nombre
	,[codarticulo] = a.codigo
	,[descripcion] = a.nombre
	,[idarticulo] = ctm.idarticulo
	,[idum] = a.idum_compra
	,[cantidad_ordenada] = ctm.cantidad_ordenada
	,[cantidad_recibida] = ctm.cantidad_recibida
	,[idmoneda] = ctm.idmoneda
	,[tipocambio] = ctm.tipocambio
	,[tipocambio_dof] = dbo.fn_ban_obtenerTC(ct.idmoneda, ct.fecha)
	,[costo_unitario] = ctm.costo_unitario
	,[costo_unitario2] = ctm.costo_unitario
	,[precio_neto] = ctm.precio_neto
	,[margen] = dbo.fn_sys_calcularMargen(ctm.precio_neto / dbo.fn_ct_articuloCargaFactor(ctm.idarticulo, ct.idsucursal), ctm.costo_unitario)
	,[precio_neto2] = ctm.precio_neto2
	,[margen2] = dbo.fn_sys_calcularMargen(ctm.precio_neto2 / dbo.fn_ct_articuloCargaFactor(ctm.idarticulo, ct.idsucursal), ctm.costo_unitario)
	,[precio_neto3] = ctm.precio_neto3
	,[margen3] = dbo.fn_sys_calcularMargen(ctm.precio_neto3 / dbo.fn_ct_articuloCargaFactor(ctm.idarticulo, ct.idsucursal), ctm.costo_unitario)
	,[precio_neto4] = ctm.precio_neto4
	,[margen4] = dbo.fn_sys_calcularMargen(ctm.precio_neto4 / dbo.fn_ct_articuloCargaFactor(ctm.idarticulo, ct.idsucursal), ctm.costo_unitario)
	,[precio_neto5] = ctm.precio_neto5
	,[margen5] = dbo.fn_sys_calcularMargen(ctm.precio_neto5 / dbo.fn_ct_articuloCargaFactor(ctm.idarticulo, ct.idsucursal), ctm.costo_unitario)
	,[comentario] = ctm.comentario
	,[idr] = ctm.idr
	,[idtran] = ctm.idtran
	,[idmov] = ctm.idmov
	,[objidtran] = ctm.idtran
FROM
	ew_com_transacciones_mov AS ctm
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = ctm.idarticulo
	LEFT JOIN ew_com_ordenes AS ct
		ON ct.idtran = ctm.idtran2
	LEFT JOIN ew_proveedores AS p
		ON p.idproveedor = ct.idproveedor
WHERE
	ctm.idtran = @idtran

/*
SELECT
	[cmd] = ',[' + oc.codigo + '] = '''''
FROM 
	objetos AS o
	LEFT JOIN objetos_grids AS og
		ON og.objeto = o.objeto
	LEFT JOIN objetos_columnas AS oc
		ON oc.objeto = o.objeto
		AND oc.grid = og.codigo
WHERE 
	o.objeto = 1399
	AND og.[tables] LIKE '%ew_com_transacciones_mov%'
ORDER BY
	og.orden
	,oc.orden
*/
GO
