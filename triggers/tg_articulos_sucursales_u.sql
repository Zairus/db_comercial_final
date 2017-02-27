USE db_comercial_final
GO
ALTER TRIGGER [dbo].[tg_articulos_sucursales_u]
   ON  [dbo].[ew_articulos_sucursales]
   FOR UPDATE
AS

SET NOCOUNT ON

DECLARE
	@idarticulo AS INT
	,@idsucursal AS SMALLINT
	,@costo_base AS DECIMAL(15,2)
	,@calcular AS BIT

IF UPDATE(costo_base) OR UPDATE(calcular_precios)
BEGIN
	UPDATE a SET 
		a.costo_base = i.costo_base
	FROM 
		inserted AS i
		LEFT JOIN deleted AS d 
			ON d.idr = i.idr
		LEFT JOIN ew_ven_listaprecios_mov AS a 
			ON a.idarticulo = i.idarticulo
		LEFT JOIN ew_ven_listaprecios AS b 
			ON b.idlista = a.idlista 
	WHERE
		i.calcular_precios = 1
		AND i.costo_base > 0
		AND (
			i.costo_base != d.costo_base 
			OR i.calcular_precios != d.calcular_precios
		)
		AND b.idsucursal = i.idsucursal
END

IF  UPDATE(utilidad1)  OR UPDATE(utilidad2)  OR UPDATE(utilidad3)  OR UPDATE(utilidad4)  OR UPDATE(utilidad5)
BEGIN
	UPDATE a SET 
		a.costo_base = i.costo_base
	FROM 
		inserted AS i
		LEFT JOIN deleted AS d 
			ON d.idr = i.idr
		LEFT JOIN ew_ven_listaprecios_mov AS a 
			ON a.idarticulo = i.idarticulo
		LEFT JOIN ew_ven_listaprecios AS b 
			ON b.idlista = a.idlista 
	WHERE 
		i.calcular_precios = 1
		AND i.costo_base > 0
		AND b.idsucursal = i.idsucursal
END
GO
