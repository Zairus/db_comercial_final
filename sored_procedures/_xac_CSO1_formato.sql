USE db_comercial_final
GO
IF OBJECT_ID('_xac_CSO1_formato') IS NOT NULL
BEGIN
	DROP PROCEDURE _xac_CSO1_formato
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200414
-- Description:	Formato de impresión de requisición de compra
-- =============================================
CREATE PROCEDURE [dbo].[_xac_CSO1_formato]
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	[almacen] = alm.nombre
	, [sucursal] = s.nombre
	, [fecha] = cd.fecha
	, [folio] = cd.folio
	, [estado] = [dbo].[fn_sys_estadoActualNombre](cd.idtran)
	, [transaccion] = cd.transaccion
	, [fecha_esperada] = cd.fecha_esperada
	, [fecha_recepcion] = cd.fecha_recepcion
	, [usuario] = u.nombre
	, [consecutivo] = cdm.consecutivo
	, [codarticulo] = a.codigo
	, [descripcion] = a.nombre
	, [unidad] = um.codigo
	, [existencia] = ISNULL(aa.existencia, 0)
	, [cantidad_solicitada] = cdm.cantidad_solicitada
	, [cantidad_autorizada] = cdm.cantidad_autorizada
	, [cantidad_ordenada] = cdm.cantidad_ordenada
	, [cantidad_recibida] = cdm.cantidad_recibida
	, [costo_unitario] = cdm.costo_unitario
	, [importe_mov] = cdm.importe
	, [d_comentario] = cdm.comentario
	, [comentario] = cd.comentario
	, [idtran] = cd.idtran
	, [empresa_rpt] = dbo.fn_sys_empresa()
FROM
	ew_com_documentos AS cd
	LEFT JOIN ew_com_documentos_mov AS cdm
		ON cdm.idtran = cd.idtran
	LEFT JOIN ew_sys_sucursales AS s 
		ON s.idsucursal = cd.idsucursal
	LEFT JOIN ew_inv_almacenes AS alm 
		ON alm.idalmacen = cd.idalmacen
	LEFT JOIN evoluware_usuarios AS u
		ON u.idu = cd.idu
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = cdm.idarticulo
	LEFT JOIN ew_cat_unidadesMedida AS um 
		ON um.idum = cdm.idum
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idarticulo = cdm.idarticulo
		AND aa.idalmacen = cd.idalmacen
WHERE
	cd.idtran = @idtran
GO
