 USE db_comercial_final
GO
ALTER TRIGGER [dbo].[tg_ven_listaprecios_mov_u]
	ON [dbo].[ew_ven_listaprecios_mov]
FOR UPDATE
AS

SET NOCOUNT ON

DECLARE
	@idr AS BIGINT
	,@idarticulo INT
	,@costo_base AS DECIMAL(15,4)
	,@u1 AS DECIMAL(8,4)
	,@u2 AS DECIMAL(8,4)
	,@u3 AS DECIMAL(8,4)
	,@u4 AS DECIMAL(8,4)
	,@u5 AS DECIMAL(8,4)
	,@factor AS DECIMAL(12,4)
	,@monto_desc AS DECIMAL(12,2)
	,@precio_anterior AS DECIMAL(15,4)
	,@p1 AS DECIMAL(15,4)
	,@p2 AS DECIMAL(15,4)
	,@p3 AS DECIMAL(15,4)
	,@p4 AS DECIMAL(15,4)
	,@p5 AS DECIMAL(15,4)
	,@decimales AS TINYINT
	,@calculo AS TINYINT
	,@idmoneda AS SMALLINT
	,@tipocambio AS DECIMAL(18,6)

-- Obtenemos el número de decimales para redondear precios
SELECT	
	@decimales = CONVERT(TINYINT, ISNULL(dbo.fn_sys_parametro('LISTAPRECIOS_DECIMALES'), 2))
	,@calculo = CONVERT(TINYINT, ISNULL(dbo.fn_sys_parametro('LISTAPRECIOS_CALCULO'), 0))
	
If UPDATE(costo_base)
BEGIN
	-- Cuando el campo "COSTO_BASE" es modificado 
	-- y el calculo no se encuentra congelado mediante el campo "PRECIO_CONGELADO"
	-- Se calculan automaticamente los nuevos precios de venta,
	-- Se utiliza el costo base y se le aplica el margen de utilidad del catalogo de articulos.
	DECLARE cur_art_lpd_u Cursor For
		SELECT 
			i.idr
			,i.idarticulo
			,[costo_base] = i.costo_base
			,i.precio1
			,[u1] = (CASE WHEN s.utilidad1 > 0 THEN s.utilidad1 ELSE CONVERT(DECIMAL(9,6), ISNULL(dbo.fn_sys_parametro('LISTAPRECIOS_UTILIDAD1'),0)) END)
			,[u2] = (CASE WHEN s.utilidad2 > 0 THEN s.utilidad2 ELSE CONVERT(DECIMAL(9,6), ISNULL(dbo.fn_sys_parametro('LISTAPRECIOS_UTILIDAD2'),0)) END)
			,[u3] = (CASE WHEN s.utilidad3 > 0 THEN s.utilidad3 ELSE CONVERT(DECIMAL(9,6), ISNULL(dbo.fn_sys_parametro('LISTAPRECIOS_UTILIDAD3'),0)) END)
			,[u4] = (CASE WHEN s.utilidad4 > 0 THEN s.utilidad4 ELSE CONVERT(DECIMAL(9,6), ISNULL(dbo.fn_sys_parametro('LISTAPRECIOS_UTILIDAD4'),0)) END)
			,[u5] = (CASE WHEN s.utilidad5 > 0 THEN s.utilidad5 ELSE CONVERT(DECIMAL(9,6), ISNULL(dbo.fn_sys_parametro('LISTAPRECIOS_UTILIDAD5'),0)) END)
			,lp.factor
			,i.idmoneda
			,bm.tipocambio
		FROM 
			inserted AS i 
			LEFT JOIN ew_ven_listaprecios AS lp 
				ON lp.idlista = i.idlista
			LEFT JOIN ew_articulos_sucursales AS s 
				ON s.idarticulo = i.idarticulo 
				AND s.idsucursal = lp.idsucursal
			LEFT JOIN ew_ban_monedas AS bm
				ON bm.idmoneda = i.idmoneda
		WHERE
			i.precio_congelado = 0
			AND i.costo_base > 0
			AND s.calcular_precios = 1
	
	OPEN cur_art_lpd_u
	
	FETCH NEXT FROM cur_art_lpd_u INTO
		@idr
		, @idarticulo
		, @costo_base
		, @precio_anterior
		, @u1
		, @u2
		, @u3
		, @u4
		, @u5
		, @factor
		, @idmoneda
		, @tipocambio

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @costo_base > 0 
		BEGIN
			-- Al costo base le sumamos el factor de precio de la lista
			IF ISNULL(@factor, 0.0) > 1.0
			BEGIN
				SELECT @costo_base = (@costo_base * @factor)
			END
		
			-- Calculamos los nuevos precios
			IF @calculo = 0
			BEGIN
				-- Se toma como base el costo
				SELECT @p1 = ROUND(@costo_base + (@costo_base * @u1), @decimales)
				SELECT @p2 = ROUND(@costo_base + (@costo_base * @u2), @decimales)
				SELECT @p3 = ROUND(@costo_base + (@costo_base * @u3), @decimales)
				SELECT @p4 = ROUND(@costo_base + (@costo_base * @u4), @decimales)
				SELECT @p5 = ROUND(@costo_base + (@costo_base * @u5), @decimales)
			END
				ELSE
			BEGIN
				-- Se toma como base el precio de venta
				SELECT @p1 = ROUND((@costo_base / (1 - @u1)), @decimales)
				SELECT @p2 = ROUND((@costo_base / (1 - @u2)), @decimales)
				SELECT @p3 = ROUND((@costo_base / (1 - @u3)), @decimales)
				SELECT @p4 = ROUND((@costo_base / (1 - @u4)), @decimales)
				SELECT @p5 = ROUND((@costo_base / (1 - @u5)), @decimales)
			END
			
			IF @idmoneda > 0
			BEGIN
				SELECT @p1 = @p1 / @tipocambio
				SELECT @p2 = @p2 / @tipocambio
				SELECT @p3 = @p3 / @tipocambio
				SELECT @p4 = @p4 / @tipocambio
				SELECT @p5 = @p5 / @tipocambio
			END

			-- Modificando el precio
			UPDATE ew_ven_listaprecios_mov SET 
				precio_anterior = @precio_anterior
				,precio1 = @p1
				,precio2 = @p2
				,precio3 = @p3
				,precio4 = @p4
				,precio5 = @p5
				,fecha = GETDATE()
			WHERE 
				idr = @idr
		END
		
		FETCH NEXT FROM cur_art_lpd_u INTO
			@idr
			, @idarticulo
			, @costo_base
			, @precio_anterior
			, @u1
			, @u2
			, @u3
			, @u4
			, @u5
			, @factor
			, @idmoneda
			, @tipocambio
	END
	
	CLOSE cur_art_lpd_u
	DEALLOCATE cur_art_lpd_u
END
GO
