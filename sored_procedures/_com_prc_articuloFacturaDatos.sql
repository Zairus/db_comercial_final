USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 201104029
-- Description:	Datos de articulo para compras
-- =============================================
ALTER PROCEDURE [dbo].[_com_prc_articuloFacturaDatos]
	 @codigo AS VARCHAR(30)
	,@idsucursal AS SMALLINT
	,@idalmacen AS SMALLINT
	,@codprovee AS VARCHAR(30)
	,@idmoneda AS SMALLINT = 0
	,@tipocambio AS DECIMAL(18,6) = 1
AS

SET NOCOUNT ON

SELECT
	 [codigo] = a.codigo
	,[nombre] = a.nombre
	,[idarticulo] = a.idarticulo
	,[costo_unitario] = aa.costo_ultimo
	,[costo_ultimo] = aa.costo_ultimo
	,[precio_lista] = ISNULL(((vlm.precio1 * bm.tipocambio2) - ((vlm.precio1 * bm.tipocambio2) * 0.10)), 0)
	,[clave_proveedor] = ''
FROM
	ew_articulos AS a
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idarticulo = a.idarticulo
		AND aa.idalmacen = @idalmacen
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = @idsucursal
	LEFT JOIN ew_ven_listaprecios_mov AS vlm
		ON vlm.idarticulo = a.idarticulo
		AND vlm.idlista = s.idlista
	LEFT JOIN ew_ban_monedas AS bm
		ON bm.idmoneda = vlm.idmoneda
WHERE
	a.codigo = @codigo
GO
