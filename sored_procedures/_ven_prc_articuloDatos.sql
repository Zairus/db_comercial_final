USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- modificado:	Arvin 2010FEB -- agregado lo de multimoneda
--				Arvin 2010ABRL -- Agregado la utilizacion de politicas de venta.
--				Arvin 2010MARZ -- Agregado descuentos
-- Create date: 20091211
-- Description:	Datos de artículo para venta
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_articuloDatos]
	@codarticulo AS VARCHAR(MAX)
	,@idlista AS SMALLINT = 0
	,@idalmacen AS SMALLINT = 1
	,@idimpuesto AS SMALLINT = 0 
	,@idpolitica AS SMALLINT = 0
	,@idsucursal AS SMALLINT = 0
	,@idlista2 AS SMALLINT = 0
	,@idum AS SMALLINT = -1
	,@idmoneda AS SMALLINT = 0
	,@tipocambio AS DECIMAL(18,6) = NULL

	,@idcliente AS INT = 0
	,@credito AS BIT = 0
	,@cantidad AS DECIMAL(18,6) = 0
AS

SET NOCOUNT ON

DECLARE 
	@impuesto_valor AS DECIMAL(15,2)
	,@idprecio AS TINYINT
	,@idprecio_may AS TINYINT
	,@descuento_linea AS DECIMAL(15,2)
	,@descuento_pol AS DECIMAL(15,2)
	,@lista AS SMALLINT
	,@idarticulo INT
	,@idimpuesto1 AS SMALLINT
	,@tc AS DECIMAL (15,8)
	,@idmoneda2 AS SMALLINT
	,@tc2 AS DECIMAL (15,8)
	,@factor AS DECIMAL (15,8) = 1
	,@decimales AS TINYINT

DECLARE
	@descuento1 AS DECIMAL(18,6)
	,@descuento2 AS DECIMAL(18,6)
	,@descuento3 AS DECIMAL(18,6)
	,@descuentos_codigos AS VARCHAR(100)

DECLARE
	 @idpromocion AS INT
	,@cantidad_minima AS DECIMAL(18,6)
	,@precio_fijo AS DECIMAL(18,6) = 0
	,@bajo_costo AS BIT = 0

DECLARE
	@codarticulo_linea AS VARCHAR(30)

CREATE TABLE #_tmp_articuloDatos (
	[id] INT IDENTITY
	,[codarticulo] VARCHAR(30) NOT NULL DEFAULT ''
	,[idlista] INT NOT NULL DEFAULT 0
	,[idarticulo] INT NOT NULL DEFAULT 0
	,[descripcion] VARCHAR(500) NOT NULL DEFAULT ''
	,[nombre_corto] VARCHAR(100) NOT NULL DEFAULT ''
	,[marca] VARCHAR(100) NOT NULL DEFAULT ''
	,[idum] INT NOT NULL DEFAULT 0
	,[maneja_lote] BIT NOT NULL DEFAULT 0
	,[autorizable] BIT NOT NULL DEFAULT 0
	,[factor] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[unidad] VARCHAR(10) NOT NULL DEFAULT ''
	,[idmoneda_m] SMALLINT NOT NULL DEFAULT 0
	,[tipocambio_m] DECIMAL(18,6) NOT NULL DEFAULT 1
	,[kit] BIT NOT NULL DEFAULT 0
	,[inventariable] BIT NOT NULL DEFAULT 0
	,[cantidad_facturada] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[precio_unitario_m] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[precio_unitario_m2] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[precio_minimo] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[existencia] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[idimpuesto1] INT NOT NULL DEFAULT 1
	,[idimpuesto1_valor] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[idimpuesto1_cuenta] VARCHAR(20) NOT NULL DEFAULT ''
	,[idimpuesto2] INT NOT NULL DEFAULT 0
	,[idimpuesto2_valor] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[idimpuesto2_cuenta] VARCHAR(20) NOT NULL DEFAULT ''
	,[idimpuesto1_ret] INT NOT NULL DEFAULT 0
	,[idimpuesto1_ret_valor] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[idimpuesto1_ret_cuenta] VARCHAR(20) NOT NULL DEFAULT ''
	,[idimpuesto2_ret] INT NOT NULL DEFAULT 0
	,[idimpuesto2_ret_valor] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[idimpuesto2_ret_cuenta] VARCHAR(20) NOT NULL DEFAULT ''
	,[ingresos_cuenta] VARCHAR(20) NOT NULL DEFAULT ''
	,[precio_congelado] BIT NOT NULL DEFAULT 0
	,[cantidad_mayoreo] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[max_descuento1] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[max_descuento2] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[objerrmsg] VARCHAR(500) NOT NULL DEFAULT ''
	,[cuenta_sublinea] VARCHAR(20) NOT NULL DEFAULT ''
	,[descuento1] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[descuento2] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[descuento3] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[objlevel] INT NOT NULL DEFAULT 0
)

SELECT @decimales = CONVERT(SMALLINT, ISNULL(dbo.fn_sys_parametro('LISTAPRECIOS_DECIMALES'), '2'))

SELECT
	@tipocambio = ISNULL(@tipocambio, tipocambio1)
FROM
	ew_ban_monedas AS bm
WHERE
	bm.idmoneda = @idmoneda

DECLARE cur_articulosDatos CURSOR FOR
	SELECT
		[codigo] = valor 
	FROM 
		[dbo].[_sys_fnc_separarMultilinea](@codarticulo, CHAR(9))
		
OPEN cur_articulosDatos

FETCH NEXT FROM cur_articulosDatos INTO
	@codarticulo_linea

WHILE @@FETCH_STATUS = 0
BEGIN
	-------------------------------------------------------
	-- Seleccionamos el articulo
	-------------------------------------------------------		
	SELECT 
		 @idarticulo = a.idarticulo
		,@idum = (CASE WHEN @idum = (-1) THEN a.idum_venta ELSE @idum END)
		,@idimpuesto1 = a.idimpuesto1
	FROM 
		ew_articulos a 
	WHERE 
		a.activo = 1
		AND a.codigo = @codarticulo_linea
	
	IF @@ROWCOUNT = 0 
	BEGIN
		CLOSE cur_articulosDatos
		DEALLOCATE cur_articulosDatos

		RAISERROR('Error: Articulo inexistente o inactivo...', 16, 1)
		RETURN
	END

	-------------------------------------------------------
	-- Seleccionamos la Lista de Precios 
	-------------------------------------------------------
	SELECT TOP 1 
		@lista = idlista
		,@idmoneda2 = idmoneda
	FROM 
		ew_ven_listaprecios_mov
	WHERE
		idlista IN (@idlista, @idlista2, 0)
		AND idarticulo = @idarticulo
	ORDER BY
		(
			CASE
				WHEN idlista = @idlista THEN 1 
				ELSE (CASE WHEN idlista = @idlista2 THEN 2 ELSE 3 END)
			END
		)

	SELECT @tc = ISNULL(dbo.fn_ban_tipocambio(@idmoneda, 0),1)	
	SELECT @tc2 = ISNULL(dbo.fn_ban_tipocambio(@idmoneda2, 0),1)	

	-------------------------------------------------------
	-- Seleccionamos la Politica de Venta
	-------------------------------------------------------
	IF @idpolitica = 0
		SELECT @idpolitica = 1

	SELECT 
		@idprecio = codprecio
		,@idprecio_may = codprecio_mayoreo
		,@descuento_linea = descuento_linea
		,@descuento_pol = descuento_limite 
	FROM 
		ew_ven_politicas 
	WHERE 
		idpolitica = @idpolitica

	-------------------------------------------------------
	-- Impuesto
	-------------------------------------------------------
	IF @idimpuesto > 0 
	BEGIN
		SELECT @impuesto_valor = valor 
		FROM ew_cat_impuestos 
		WHERE idimpuesto = @idimpuesto		
	END

	EXEC [dbo].[_ven_prc_descuentosValores]
		@idsucursal
		,@idcliente
		,@credito
		,@idarticulo
		,@cantidad
		,@descuento1 OUTPUT
		,@descuento2 OUTPUT
		,@descuento3 OUTPUT
		,@descuentos_codigos OUTPUT
		,@precio_fijo OUTPUT
		,@bajo_costo OUTPUT

	INSERT INTO #_tmp_articuloDatos (
		[codarticulo]
		,[idlista]
		,[idarticulo]
		,[descripcion]
		,[nombre_corto]
		,[marca]
		,[idum]
		,[maneja_lote]
		,[autorizable]
		,[factor]
		,[unidad]
		,[idmoneda_m]
		,[tipocambio_m]
		,[inventariable]
		,[cantidad_facturada]
		,[precio_unitario_m]
		,[precio_unitario_m2]
		,[precio_minimo]
		,[existencia]
		,[idimpuesto1]
		,[idimpuesto1_valor]
		,[idimpuesto1_cuenta]
		,[idimpuesto2]
		,[idimpuesto2_valor]
		,[idimpuesto2_cuenta]
		,[idimpuesto1_ret]
		,[idimpuesto1_ret_valor]
		,[idimpuesto1_ret_cuenta]
		,[idimpuesto2_ret]
		,[idimpuesto2_ret_valor]
		,[idimpuesto2_ret_cuenta]
		,[ingresos_cuenta]
		,[precio_congelado]
		,[cantidad_mayoreo]
		,[max_descuento1]
		,[max_descuento2]
		,[objerrmsg]
		,[cuenta_sublinea]
		,[descuento1]
		,[descuento2]
		,[descuento3]
		,[objlevel]
	)

	SELECT
		[codarticulo] = a.codigo
		,[idlista] = @lista
		,a.idarticulo
		,[descripcion] = a.nombre
		,a.nombre_corto
		,[marca] = ISNULL(m.nombre, '')
		,[idum] = um.idum
		,[maneja_lote] = a.lotes
		,a.autorizable
		,um.factor
		,unidad = um.codigo
		,[idmoneda_m] = ISNULL(vlm.idmoneda, 0)
		,[tipocambio_m] = ISNULL(bm.tipocambio, 1)
	
		,[inventariable] = a.inventariable
		,[cantidad_facturada] = @cantidad
		,[precio_unitario_m] = (
			ISNULL(ROUND((
				CASE @idprecio 
					WHEN 2 THEN vlm.precio2
					WHEN 3 THEN vlm.precio3
					WHEN 4 THEN vlm.precio4
					WHEN 5 THEN vlm.precio5
					ELSE vlm.precio1
				END
			) * um.factor,@decimales), 0)
			* (CASE WHEN vlm.idmoneda = @idmoneda THEN 1 ELSE bm.tipoCambio / @tipocambio END)
		)

		,[precio_unitario_m2] = (
			ISNULL(ROUND((
				CASE @idprecio_may 
					WHEN 2 THEN vlm.precio2
					WHEN 3 THEN vlm.precio3
					WHEN 4 THEN vlm.precio4
					WHEN 5 THEN vlm.precio5
					ELSE vlm.precio1
				END
			) * @factor,@decimales), 0)
			* (CASE WHEN vlm.idmoneda = @idmoneda THEN 1 ELSE bm.tipoCambio / @tipocambio END)
		)

		,[precio_minimo] = (
			(
				sucar.costo_base
				*(
					1
					+(
						CASE 
							WHEN sucar.margen_minimo > 0 THEN sucar.margen_minimo
							ELSE (SELECT TOP 1 CONVERT(DECIMAL(18,6), valor) FROM ew_sys_parametros AS sp WHERE sp.codigo = 'LISTAPRECIOS_MARGENMINIMO')
						END
					)
				)
			)
		)
	
		,[existencia] = (
			dbo.fn_inv_existenciaReal(a.idarticulo, @idalmacen)
			-dbo.fn_inv_existenciaComprometida(a.idarticulo, @idalmacen)
		)
		--##########################################
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
		), a.idimpuesto1)
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
		), ISNULL((SELECT ci1.valor FROM ew_cat_impuestos AS ci1 WHERE ci1.idimpuesto = a.idimpuesto1), 0))
		,[idimpuesto1_cuenta] = ISNULL((
			SELECT TOP 1
				cit.contabilidad1
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
		), '')
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
		,[idimpuesto2_cuenta] = ISNULL((
			SELECT TOP 1
				cit.contabilidad1
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
		), ISNULL((SELECT ci1.contabilidad FROM ew_cat_impuestos AS ci1 WHERE ci1.idimpuesto = a.idimpuesto2), 0))
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
		,[idimpuesto1_ret_cuenta] = ISNULL((
			SELECT TOP 1
				cit.contabilidad1
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
		), ISNULL((SELECT ci1.contabilidad FROM ew_cat_impuestos AS ci1 WHERE ci1.idimpuesto = a.idimpuesto1_ret), 0))
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
		,[idimpuesto2_ret_cuenta] = ISNULL((
			SELECT TOP 1
				cit.contabilidad1
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
		), ISNULL((SELECT ci1.contabilidad FROM ew_cat_impuestos AS ci1 WHERE ci1.idimpuesto = a.idimpuesto2_ret), 0))
		,[ingresos_cuenta] = ISNULL((
			SELECT TOP 1
				CASE
					WHEN cit.descripcion LIKE '%exen%' THEN '4100003000'
					ELSE
						CASE
							WHEN cit.tasa = 0 THEN '4100002000'
							ELSE '4100001000'
						END
				END
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
		), '')
		--##########################################
		,[precio_congelado] = CONVERT(BIT, (CASE WHEN sucar.cambiar_precio = 1 THEN 0 ELSE 1 END))
		,[cantidad_mayoreo] = sucar.mayoreo
		,[max_descuento1] = @descuento_pol
		,[max_descuento2] = @descuento_linea
		,[objerrmsg] = ISNULL(sucar.comentario_ventas, '')
		,cuenta_sublinea=ISNULL(subl.contabilidad,'')

		,[descuento1] = @descuento1
		,[descuento2] = @descuento2
		,[descuento3] = @descuento3
		,[objlevel] = (CASE WHEN a.kit = 1 THEN 1 ELSE 0 END)
	FROM 
		ew_articulos AS a
		LEFT JOIN ew_ven_listaprecios_mov AS vlm 
			ON vlm.idarticulo = a.idarticulo
			AND vlm.idlista = @lista 
		LEFT JOIN ew_ban_monedas AS bm
			ON bm.idmoneda = vlm.idmoneda
		LEFT JOIN ew_articulos_almacenes AS aa 
			ON aa.idarticulo = a.idarticulo
			AND aa.idalmacen = @idalmacen
		LEFT JOIN ew_inv_almacenes AS al 
			ON al.idalmacen=aa.idalmacen
		LEFT JOIN ew_articulos_sucursales AS sucar
			ON sucar.idsucursal= @idsucursal
			AND sucar.idarticulo = a.idarticulo
		LEFT JOIN ew_sys_sucursales AS suc 
			ON suc.idsucursal = @idsucursal
		LEFT JOIN ew_cat_impuestos AS i1 
			ON i1.idimpuesto = (
				CASE
					WHEN a.idimpuesto1 > 2 THEN a.idimpuesto1
					ELSE @idimpuesto
				END
			)
		LEFT JOIN ew_cat_impuestos AS i2 
			ON i2.idimpuesto = a.idimpuesto2
		LEFT JOIN ew_cat_impuestos As i3
			ON i3.idimpuesto = a.idimpuesto1_ret
		LEFT JOIN ew_cat_unidadesMedida AS um 
			ON um.idum=a.idum_venta
		LEFT JOIN ew_cat_marcas AS m 
			ON a.idmarca = m.idmarca

		LEFT JOIN ew_articulos_niveles subl 
			ON subl.codigo=a.nivel3
	WHERE
		a.idarticulo = @idarticulo

	UPDATE #_tmp_articuloDatos SET
		precio_unitario_m = (CASE WHEN @precio_fijo = 0 THEN precio_unitario_m ELSE @precio_fijo END)
		,precio_unitario_m2 = (CASE WHEN @precio_fijo = 0 THEN precio_unitario_m2 ELSE @precio_fijo END)
		,precio_minimo = (CASE WHEN @precio_fijo = 0 THEN precio_minimo ELSE @precio_fijo END)

	IF @cantidad > 0
	BEGIN
		DECLARE cur_promociones CURSOR FOR
			SELECT DISTINCT
				 vpc.idpromocion
				,vpc.cantidad_minima
			FROM 
				ew_ven_promociones_condiciones AS vpc
				LEFT JOIN ew_ven_promociones AS vp
					ON vp.idpromocion = vpc.idpromocion
			WHERE
				vpc.articulo_grupo = 1
				AND vp.activo = 1
				AND vpc.cantidad_minima <> 0
				AND vp.fecha_final >= CONVERT(nvarchar(30), GETDATE(), 103)
				AND vpc.articulo_id = @idarticulo
				AND vpc.cantidad_minima <= @cantidad
				AND (CASE vp.idsucursal WHEN 0 THEN @idsucursal ELSE vp.idsucursal END) = @idsucursal
				AND (CASE WHEN vpc.cantidad_maxima = 0 THEN 9999999 ELSE vpc.cantidad_maxima END) >= @cantidad
	
		OPEN cur_promociones
	
		FETCH NEXT FROM cur_promociones INTO
			 @idpromocion
			,@cantidad_minima
	
		WHILE @@FETCH_STATUS = 0
		BEGIN
			INSERT INTO #_tmp_articuloDatos (
				 [codarticulo]
				,[idlista]
				,[idarticulo]
				,[descripcion]
				,[nombre_corto]
				,[marca]
				,[idum]
				,[maneja_lote]
				,[autorizable]
				,[factor]
				,[unidad]
				,[idmoneda_m]
				,[tipocambio_m]
				,[inventariable]
				,[cantidad_facturada]
				,[precio_unitario_m]
				,[precio_unitario_m2]
				,[precio_minimo]
				,[existencia]
				,[idimpuesto1]
				,[idimpuesto1_valor]
				,[idimpuesto2]
				,[idimpuesto2_valor]
				,[idimpuesto1_ret]
				,[idimpuesto1_ret_valor]
				,[precio_congelado]
				,[cantidad_mayoreo]
				,[objerrmsg]
				,[cuenta_sublinea]
			)
			SELECT
				 [codarticulo] = a.codigo
				,[idlista] = @lista
				,a.idarticulo
				,[descripcion] = a.nombre
				,a.nombre_corto
				,[marca] = ISNULL(m.nombre,'')
				,[idum] = um.idum
				,[maneja_lote] = a.lotes
				,a.autorizable
				,um.factor
				,unidad = um.codigo
				,[idmoneda_m] = ISNULL(vlm.idmoneda, 0)
				,[tipocambio_m] = ISNULL(bm.tipocambio, 1)
				,[inventariable] = a.inventariable
				,[cantidad_facturada] = vpa.cantidad
				,[precio_unitario_m] = vpa.precio_venta
				,[precio_unitario_m2] = vpa.precio_venta
				,[precio_minimo] = vpa.precio_venta
				,[existencia] = (
					dbo.fn_inv_existenciaReal(a.idarticulo, @idalmacen)
					-dbo.fn_ven_pedidos(a.idarticulo, @idalmacen, 1)
				)
				,[idimpuesto1] = i1.idimpuesto
				,[idimpuesto1_valor] = i1.valor
				,[idimpuesto2] = ISNULL(a.idimpuesto2, 0)
				,[idimpuesto2_valor] = ISNULL(i2.valor, 0)
				,[idimpuesto1_ret] = a.idimpuesto1_ret
				,[idimpuesto1_ret_valor] = i3.valor
				,[precio_congelado] = CONVERT(BIT, (CASE WHEN sucar.cambiar_precio = 1 THEN 0 ELSE 1 END))
				,[cantidad_mayoreo] = sucar.mayoreo
				,[objerrmsg] = ISNULL(sucar.comentario_ventas, '')
				,cuenta_sublinea=ISNULL(subl.contabilidad,'')
			FROM
				ew_ven_promociones_acciones AS vpa
				LEFT JOIN ew_articulos AS a
					ON a.idarticulo = vpa.idarticulo
				LEFT JOIN ew_ven_listaprecios_mov AS vlm 
					ON vlm.idarticulo = a.idarticulo
					AND vlm.idlista = @lista 
				LEFT JOIN ew_ban_monedas AS bm
					ON bm.idmoneda = vlm.idmoneda
				LEFT JOIN ew_articulos_almacenes AS aa 
					ON aa.idarticulo = a.idarticulo
					AND aa.idalmacen = @idalmacen
				LEFT JOIN ew_inv_almacenes AS al 
					ON al.idalmacen=aa.idalmacen
				LEFT JOIN ew_articulos_sucursales AS sucar
					ON sucar.idsucursal= @idsucursal
					AND sucar.idarticulo = a.idarticulo
				LEFT JOIN ew_sys_sucursales AS suc 
					ON suc.idsucursal = @idsucursal
				LEFT JOIN ew_cat_impuestos AS i1 
					ON i1.idimpuesto = (
						CASE
							WHEN a.idimpuesto1 > 2 THEN a.idimpuesto1
							ELSE @idimpuesto
						END
					)
				LEFT JOIN ew_cat_impuestos AS i2 
					ON i2.idimpuesto = a.idimpuesto2
				LEFT JOIN ew_cat_impuestos As i3
					ON i3.idimpuesto = a.idimpuesto1_ret
				LEFT JOIN ew_cat_unidadesMedida AS um 
					ON um.idum=a.idum_venta
				LEFT JOIN ew_cat_marcas AS m 
					ON a.idmarca = m.idmarca

				LEFT JOIN ew_articulos_niveles subl 
					ON subl.codigo=a.nivel3
			WHERE
				vpa.idpromocion = @idpromocion
		
			FETCH NEXT FROM cur_promociones INTO
				 @idpromocion
				,@cantidad_minima
		END
	
		CLOSE cur_promociones
		DEALLOCATE cur_promociones
	END

	INSERT INTO #_tmp_articuloDatos (
		[codarticulo]
		,[idlista]
		,[idarticulo]
		,[descripcion]
		,[nombre_corto]
		,[marca]
		,[idum]
		,[maneja_lote]
		,[autorizable]
		,[factor]
		,[unidad]
		,[idmoneda_m]
		,[tipocambio_m]
		,[kit]
		,[inventariable]
		,[cantidad_facturada]
		,[precio_unitario_m]
		,[precio_unitario_m2]
		,[precio_minimo]
		,[existencia]
		,[objlevel]
	)
	SELECT
		[codarticulo] = a.codigo
		,[idlista] = @idlista
		,[idarticulo] = ai.idarticulo
		,[descripcion] = a.nombre
		,[nombre_corto] = a.nombre_corto
		,[marca] = ISNULL(m.nombre, '')
		,[idum] = a.idum_venta
		,[maneja_lote] = 0
		,[autorizable] = a.autorizable
		,[factor] = um.factor
		,[unidad] = um.codigo
		,[idmoneda_m] = 0
		,[tipocambio_m] = 1
		,[kit] = 1
		,[inventariable] = a.inventariable
		,[cantidad_facturada] = ai.cantidad * @cantidad
		,[precio_unitario_m] = 0
		,[precio_unitario_m2] = 0
		,[precio_minimo] = 0
		,[existencia] = ISNULL(aa.existencia, 0)
		,[objlevel] = 2
	FROM
		ew_articulos_insumos AS ai
		LEFT JOIN ew_articulos AS a
			ON a.idarticulo = ai.idarticulo
		LEFT JOIN ew_cat_marcas AS m 
			ON a.idmarca = m.idmarca
		LEFT JOIN ew_cat_unidadesMedida AS um 
			ON um.idum = a.idum_venta
		LEFT JOIN ew_articulos_almacenes AS aa 
			ON aa.idarticulo = a.idarticulo
			AND aa.idalmacen = @idalmacen
	WHERE
		ai.idarticulo_superior = @idarticulo

	FETCH NEXT FROM cur_articulosDatos INTO
		@codarticulo_linea
END

CLOSE cur_articulosDatos
DEALLOCATE cur_articulosDatos

SELECT
	[codarticulo] = tad.codarticulo
	,[idlista] = tad.idlista
	,[idarticulo] = tad.idarticulo
	,[descripcion] = tad.descripcion
	,[nombre_corto] = tad.nombre_corto
	,[marca] = tad.marca
	,[idum] = tad.idum
	,[maneja_lote] = tad.maneja_lote
	,[autorizable] = tad.autorizable
	,[factor] = tad.factor
	,[unidad] = tad.unidad
	,[idmoneda_m] = tad.idmoneda_m
	,[tipocambio_m] = tad.tipocambio_m
	,[kit] = tad.kit
	,[inventariable] = tad.inventariable
	,[cantidad_ordenada] = tad.cantidad_facturada
	,[cantidad_facturada] = tad.cantidad_facturada
	,[precio_unitario_m] = tad.precio_unitario_m
	,[precio_unitario_m2] = tad.precio_unitario_m2
	,[precio_minimo] = (
		CASE
			WHEN @bajo_costo = 0 THEN tad.precio_minimo / (1 - (tad.descuento1 / 100)) / (1 - (tad.descuento2 / 100))
			ELSE tad.precio_minimo
		END
	)
	,[existencia] = (CASE WHEN tad.inventariable = 0 THEN 0 ELSE tad.existencia END)
	,[idimpuesto1] = tad.idimpuesto1
	,[idimpuesto1_valor] = tad.idimpuesto1_valor
	,[idimpuesto1_cuenta] = tad.idimpuesto1_cuenta
	,[idimpuesto2] = tad.idimpuesto2
	,[idimpuesto2_valor] = tad.idimpuesto2_valor
	,[idimpuesto2_cuenta] = tad.idimpuesto2_cuenta
	,[idimpuesto1_ret] = tad.idimpuesto1_ret
	,[idimpuesto1_ret_valor] = tad.idimpuesto1_ret_valor
	,[idimpuesto1_ret_cuenta] = tad.idimpuesto1_ret_cuenta
	,[idimpuesto2_ret] = tad.idimpuesto2_ret
	,[idimpuesto2_ret_valor] = tad.idimpuesto2_ret_valor
	,[idimpuesto2_ret_cuenta] = tad.idimpuesto2_ret_cuenta
	,[ingresos_cuenta] = tad.ingresos_cuenta
	,[precio_congelado] = tad.precio_congelado
	,[cantidad_mayoreo] = tad.cantidad_mayoreo
	,[max_descuento1] = tad.descuento1
	,[max_descuento2] = tad.descuento2
	,[objerrmsg] = tad.objerrmsg
	,[cuenta_sublinea] = tad.cuenta_sublinea
	,[descuento1] = 0
	,[descuento2] = tad.descuento2
	,[descuento3] = tad.descuento3
	,[objlevel] = tad.objlevel
FROM 
	#_tmp_articuloDatos AS tad

DROP TABLE #_tmp_articuloDatos
GO