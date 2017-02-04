USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170131
-- Description:	Reporte para conteo de toma de inventario
-- =============================================
ALTER PROCEDURE [dbo].[_inv_rpt_inventarioTomaConteo]
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	[folio] = id.folio
	,[fecha] = id.fecha
	,[movimiento] = o.nombre
	,[almacen] = alm.nombre
	,[sucursal] = s.nombre
	,a.codigo
	,[nombre] = LEFT(a.nombre, 80)
	,[nombre_corto] = LEFT(a.nombre_corto, 20)
	,[existencia] = ISNULL(aa.existencia, 0)
	,[conteo] = ''
	,[diferencia] = ''
FROM
	ew_inv_documentos_mov AS idm
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = idm.idarticulo
	LEFT JOIN ew_inv_documentos AS id
		ON id.idtran = idm.idtran
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idarticulo = idm.idarticulo
		AND aa.idalmacen = id.idalmacen
	LEFT JOIN objetos AS o
		ON o.codigo = id.transaccion
	LEFT JOIN ew_inv_almacenes AS alm
		ON alm.idalmacen = id.idalmacen
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = alm.idsucursal
WHERE
	idm.idtran = @idtran
GO