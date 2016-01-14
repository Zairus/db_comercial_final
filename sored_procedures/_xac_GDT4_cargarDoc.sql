USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20121228
-- Description:	Cargar re empaque de producto
-- =============================================
ALTER PROCEDURE [dbo].[_xac_GDT4_cargarDoc]
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	[transaccion] = id.transaccion
	,[idsucursal] = id.idsucursal
	,[idalmacen] = id.idalmacen
	,[fecha] = id.fecha
	,[folio] = id.folio
	,[referencia] = id.referencia
	,[concepto] = c.nombre
	,[idconcepto] = id.idconcepto
	,[cancelado] = id.cancelado
	,[cancelado_fecha] = id.cancelado_fecha
	,[idu] = id.idu
	,[idr] = id.idr
	,[idtran] = id.idtran
	,[idmov] = id.idmov
	,[saldo] = 0
	,[comentario] = id.comentario
FROM 
	ew_inv_documentos AS id
	LEFT JOIN conceptos AS c
		ON c.idconcepto = id.idconcepto
WHERE
	id.idtran = @idtran

SELECT
	[codarticulo] = a.codigo
	,[nombre] = a.nombre
	,[idarticulo] = idm.idarticulo
	,[idum] = idm.idum
	,[existencia] = aa.existencia
	,[cantidad] = idm.cantidad
	,[costo_unitario] = idm.costo / idm.cantidad
	,[costo] = idm.costo
	,[idalmacen] = idm.idalmacen
	,[idr] = idm.idr
	,[idtran] = idm.idtran
	,[idmov] = idm.idmov
	,[spa] = ''
FROM 
	ew_inv_documentos_mov AS idm 
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = idm.idarticulo
	LEFT JOIN ew_inv_documentos AS id
		ON id.idtran = idm.idtran
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idalmacen = id.idalmacen
		AND aa.idarticulo = idm.idarticulo
WHERE 
	idm.consecutivo = 0
	AND idm.idtran = @idtran

SELECT
	[consecutivo] = idm.consecutivo
	,[codarticulo] = a.codigo
	,[nombre] = a.nombre
	,[idarticulo] = idm.idarticulo
	,[idum] = idm.idum
	,[existencia] = aa.existencia
	,[cantidad] = idm.cantidad
	,[factor] = idm.factor
	,[cantidad_eq] = (idm.cantidad * idm.factor)
	,[costo_unitario] = idm.costo / idm.cantidad
	,[costo] = idm.costo
	,[idalmacen] = idm.idalmacen
	,[comentario] = idm.comentario
	,[idr] = idm.idr
	,[idtran] = idm.idtran
	,[idmov] = idm.idmov
FROM 
	ew_inv_documentos_mov AS idm
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = idm.idarticulo
	LEFT JOIN ew_inv_documentos AS id
		ON id.idtran = idm.idtran
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idalmacen = id.idalmacen
		AND aa.idarticulo = idm.idarticulo
WHERE
	idm.consecutivo > 0
	AND idm.idtran = @idtran
GO
