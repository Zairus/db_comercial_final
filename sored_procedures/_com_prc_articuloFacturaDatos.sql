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
	,[idtipo] = a.idtipo
	,[costo_unitario] = aa.costo_ultimo
	,[costo_ultimo] = aa.costo_ultimo
	,[precio_lista] = ISNULL(((vlm.precio1 * bm.tipocambio) - ((vlm.precio1 * bm.tipocambio) * 0.10)), 0)
	,[clave_proveedor] = ''

	--########################################################
	,[idimpuesto1] = ISNULL((
		SELECT TOP 1
			cit.idimpuesto
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE 
			ci.grupo = 'IVA'
			AND cit.tipo = 1
			AND ait.idarticulo = a.idarticulo
	), suc.idimpuesto)
	,[idimpuesto1_valor] = ISNULL((
		SELECT TOP 1
			cit.tasa
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE 
			ci.grupo = 'IVA'
			AND cit.tipo = 1
			AND ait.idarticulo = a.idarticulo
	), ISNULL((SELECT ci1.valor FROM ew_cat_impuestos AS ci1 WHERE ci1.idimpuesto = suc.idimpuesto), 0))
	,[idimpuesto2] = ISNULL((
		SELECT TOP 1
			cit.idimpuesto
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE
			ci.grupo = 'IEPS'
			AND cit.tipo = 1
			AND ait.idarticulo = a.idarticulo
	), a.idimpuesto2)
	,[idimpuesto2_valor] = ISNULL((
		SELECT TOP 1
			cit.tasa
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE 
			ci.grupo = 'IEPS'
			AND cit.tipo = 1
			AND ait.idarticulo = a.idarticulo
	), ISNULL((SELECT ci1.valor FROM ew_cat_impuestos AS ci1 WHERE ci1.idimpuesto = a.idimpuesto2), 0))
	,[idimpuesto1_ret] = ISNULL((
		SELECT TOP 1
			cit.idimpuesto
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE 
			ci.grupo = 'IVA'
			AND cit.tipo = 2
			AND ait.idarticulo = a.idarticulo
	), a.idimpuesto1_ret)
	,[idimpuesto1_ret_valor] = ISNULL((
		SELECT TOP 1
			cit.tasa
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE 
			ci.grupo = 'IVA'
			AND cit.tipo = 2
			AND ait.idarticulo = a.idarticulo
	), ISNULL((SELECT ci1.valor FROM ew_cat_impuestos AS ci1 WHERE ci1.idimpuesto = a.idimpuesto1_ret), 0))
	,[idimpuesto2_ret] = ISNULL((
		SELECT TOP 1
			cit.idimpuesto
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE 
			ci.grupo = 'ISR'
			AND cit.tipo = 2
			AND ait.idarticulo = a.idarticulo
	), a.idimpuesto2_ret)
	,[idimpuesto2_ret_valor] = ISNULL((
		SELECT TOP 1
			cit.tasa
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE 
			ci.grupo = 'ISR'
			AND cit.tipo = 2
			AND ait.idarticulo = a.idarticulo
	), ISNULL((SELECT ci1.valor FROM ew_cat_impuestos AS ci1 WHERE ci1.idimpuesto = a.idimpuesto2_ret), 0))

	--########################################################
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
	LEFT JOIN ew_sys_sucursales AS suc
		ON suc.idsucursal = @idsucursal
WHERE
	a.codigo = @codigo
GO
