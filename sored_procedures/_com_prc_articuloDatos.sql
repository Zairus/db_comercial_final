USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20080919
-- Description:	Datos de artículo para compras
-- Ejemplo: EXEC _com_prc_articuloDatos 1, 0,1,2,1
-- =============================================
ALTER PROCEDURE [dbo].[_com_prc_articuloDatos]
	@idarticulo AS VARCHAR(20)
	,@idsucursal AS SMALLINT
	,@idalmacen AS SMALLINT
	,@idimpuesto AS TINYINT = 0
	,@idproveedor AS SMALLINT
	,@idmoneda AS SMALLINT = 0
AS

DECLARE
	@costo_unitario AS DECIMAL(18,6)

--Seleccionar sucursal, en caso de que no se le haya enviado
IF @idsucursal = 0
BEGIN
	SELECT top 1
		@idsucursal = idsucursal
	FROM
		ew_inv_almacenes
	WHERE 
		idalmacen = @idalmacen
END

SELECT
	[codarticulo] = a.codigo
	,a.idarticulo
	,ap.codigo_proveedor	
	,[descripcion] = a.nombre
	,a.nombre_corto
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
			AND ctm.idarticulo = @idarticulo
			AND ct.idmoneda = @idmoneda
		ORDER BY
			ct.fecha desc
	)
	,[existencia] = ISNULL(aa.existencia, 0)
	,s.idsucursal
	,aa.idalmacen
	,[idimpuesto1] = (
		CASE
			WHEN a.idimpuesto1 = 0
				THEN
					CASE
						WHEN @idimpuesto = 0 THEN (SELECT idimpuesto FROM ew_sys_sucursales WHERE idsucursal = @idsucursal)
						ELSE (SELECT idimpuesto FROM ew_cat_impuestos WHERE idimpuesto = @idimpuesto)
					END
			ELSE a.idimpuesto1
		END
	)
	,[idimpuesto1_valor] = (
		CASE
			WHEN a.idimpuesto1 = 0 THEN
				CASE
					WHEN @idimpuesto = 0 THEN (
						SELECT imp2.valor 
						FROM 
							ew_sys_sucursales ss 
							LEFT JOIN ew_cat_impuestos imp2 
								ON imp2.idimpuesto = ss.idimpuesto 
							WHERE 
								ss.idsucursal=@idsucursal
					) 
					ELSE (
						SELECT valor
						FROM ew_cat_impuestos 
						WHERE idimpuesto = @idimpuesto
					)
				END
			ELSE
				imp.valor 
		END
	)
	,a.idimpuesto1_ret
	,[idimpuesto1_ret_valor] = impr1.valor

	,[idimpuesto2] = ISNULL((
		SELECT TOP 1 ait.idimpuesto FROM ew_articulos_impuestos_tasas AS ait WHERE ait.idarticulo = a.idarticulo
	), ISNULL(imp2.idimpuesto, 0))
	,[idimpuesto2_valor] = ISNULL((
		SELECT TOP 1 ait.tasa FROM ew_articulos_impuestos_tasas AS ait WHERE ait.idarticulo = a.idarticulo
	), ISNULL(imp2.valor, 0))
	,a.idimpuesto2_ret
	,[idimpuesto2_ret_valor] = impr2.valor
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
WHERE
	a.idarticulo = @idarticulo
GO
