USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170221
-- Description:	Datos de articulo para compras
-- =============================================
ALTER PROCEDURE _com_prc_articuloDatosR2
	@codarticulo AS VARCHAR(MAX)
	,@idsucursal AS SMALLINT
	,@idalmacen AS SMALLINT
	,@idimpuesto AS TINYINT = 0
	,@idproveedor AS SMALLINT
	,@idmoneda AS SMALLINT = 0
AS

SET NOCOUNT ON

DECLARE
	@costo_unitario AS DECIMAL(18,6)

--Seleccionar sucursal, en caso de que no se le haya enviado
IF @idsucursal = 0
BEGIN
	SELECT TOP 1
		@idsucursal = idsucursal
	FROM
		ew_inv_almacenes
	WHERE 
		idalmacen = @idalmacen
END

SELECT
	[codarticulo] = a.codigo
	,[idarticulo] = a.idarticulo
	,[codigo_proveedor] = ap.codigo_proveedor
	,[descripcion] = a.nombre
	,[nombre_corto] = a.nombre_corto
	,[marca]=m.nombre
	,[idum] = a.idum_compra
	,[maneja_lote] = a.lotes
	,[costo_unitario] = (
		SELECT TOP 1 ISNULL(ctm.costo_unitario,0)
		FROM
			ew_com_transacciones_mov ctm
			LEFT JOIN ew_com_transacciones ct
				ON ct.idtran = ctm.idtran
		WHERE
			ct.cancelado = 0
			AND ctm.idarticulo = a.idarticulo
			AND ct.idmoneda = @idmoneda
		ORDER BY
			ct.fecha desc
	)
	,[existencia] = ISNULL(aa.existencia, 0)
	,[idsucursal] = s.idsucursal
	,[idalmacen] = aa.idalmacen

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
	LEFT JOIN ew_articulos_almacenes aa
		ON aa.idarticulo = a.idarticulo
		AND aa.idalmacen = @idalmacen
	LEFT JOIN ew_cat_impuestos imp
		ON imp.idimpuesto = a.idimpuesto1
	LEFT JOIN ew_cat_impuestos AS impr1
		ON impr1.idimpuesto = a.idimpuesto1_ret
	LEFT JOIN ew_articulos_sucursales s
		ON s.idarticulo = a.idarticulo
		AND s.idsucursal = @idsucursal
	LEFT JOIN ew_articulos_proveedores ap
		ON ap.idarticulo=a.idarticulo
		AND ap.idproveedor=@idproveedor
	LEFT JOIN ew_cat_marcas m
		ON a.idmarca=m.idmarca

	LEFT JOIN ew_cat_impuestos AS imp2
		ON imp2.idimpuesto = a.idimpuesto2
	LEFT JOIN ew_cat_impuestos AS impr2
		ON impr2.idimpuesto = a.idimpuesto2_ret
	LEFT JOIN ew_sys_sucursales AS suc
		ON suc.idsucursal = @idsucursal
WHERE
	a.activo = 1
	AND a.codigo IN (
		SELECT al.valor 
		FROM 
			dbo._sys_fnc_separarMultilinea(@codarticulo, CHAR(9)) AS al
	)

IF @@ROWCOUNT = 0
BEGIN
	RAISERROR('Error: Articulo inexistente o inactivo...', 16, 1)
	RETURN
END
GO
