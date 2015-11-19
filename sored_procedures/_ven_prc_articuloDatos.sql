USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- modificado:	Arvin 2010FEB -- agregado lo de multimoneda
--				Arvin 2010ABRL -- Agregado la utilizacion de politicas de venta.
--				Arvin 2010MARZ -- Agregado descuentos
-- Create date: 20091211
-- Description:	Datos de art�culo para venta
-- EJEMPLO:		EXEC _ven_prc_articuloDatos 'MUESTRA', 1,1,2,1,1,0,-1
---				EXEC _ven_prc_articuloDatos '7010', 1,2,1, 0, 2, 1, 33, 0
-- =============================================
-- EXEC _ven_prc_articuloDatos '36360001640',0,1,1, 1, 1, 0, -1, 0
ALTER PROCEDURE [dbo].[_ven_prc_articuloDatos]
	@codarticulo AS VARCHAR(30)
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
	,@idarticulo AS SMALLINT
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
		
SELECT @decimales = CONVERT(SMALLINT, ISNULL(dbo.fn_sys_parametro('LISTAPRECIOS_DECIMALES'), '2'))

SELECT
	@tipocambio = ISNULL(@tipocambio, tipocambio1)
FROM
	ew_ban_monedas AS bm
WHERE
	bm.idmoneda = @idmoneda

-------------------------------------------------------
-- Seleccionamos el articulo
-------------------------------------------------------		
SELECT 
	 @idarticulo = a.idarticulo
	,@idum = CASE WHEN @idum = (-1) THEN a.idum_venta ELSE @idum END
	,@idimpuesto1 = a.idimpuesto1
FROM 
	ew_articulos a 
WHERE 
	a.codigo = @codarticulo

IF @@ROWCOUNT=0 
BEGIN
	RAISERROR('Error: Articulo inexistente...', 16, 1)
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
	,[cantidad_facturada] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[precio_unitario_m] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[precio_unitario_m2] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[precio_minimo] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[existencia] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[idimpuesto1] INT NOT NULL DEFAULT 1
	,[idimpuesto1_valor] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[idimpuesto2] INT NOT NULL DEFAULT 0
	,[idimpuesto2_valor] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[idimpuesto1_ret] INT NOT NULL DEFAULT 0
	,[idimpuesto1_ret_valor] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[precio_congelado] BIT NOT NULL DEFAULT 0
	,[cantidad_mayoreo] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[max_descuento1] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[max_descuento2] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[objerrmsg] VARCHAR(500) NOT NULL DEFAULT ''
	,[cuenta_sublinea] VARCHAR(20) NOT NULL DEFAULT ''
	,[descuento1] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[descuento2] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[descuento3] DECIMAL(18,6) NOT NULL DEFAULT 0
)

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
	,[max_descuento1]
	,[max_descuento2]
	,[objerrmsg]
	,[cuenta_sublinea]
	,[descuento1]
	,[descuento2]
	,[descuento3]
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
		ROUND((
			CASE
				WHEN sucar.bajo_costo = 1 THEN 0.01
				ELSE ISNULL(vlm.costo_base, 0)
			END
		) * @factor,@decimales)
		* (CASE WHEN vlm.idmoneda = @idmoneda THEN 1 ELSE bm.tipoCambio / @tipocambio END)
	)
	
	,[existencia] = (
		dbo.fn_inv_existenciaReal(a.idarticulo, @idalmacen)
		-dbo.fn_inv_existenciaComprometida(a.idarticulo, @idalmacen)
	)
	,[idimpuesto1] = i1.idimpuesto
	,[idimpuesto1_valor] = i1.valor
	,[idimpuesto2] = ISNULL(a.idimpuesto2, 0)
	,[idimpuesto2_valor] = ISNULL(i2.valor, 0)
	,[idimpuesto1_ret] = a.idimpuesto1_ret
	,[idimpuesto1_ret_valor] = i3.valor
	,[precio_congelado] = CONVERT(BIT, (CASE WHEN sucar.cambiar_precio = 1 THEN 0 ELSE 1 END))
	,[cantidad_mayoreo] = sucar.mayoreo
	,[max_descuento1] = @descuento_pol
	,[max_descuento2] = @descuento_linea
	,[objerrmsg] = ISNULL(sucar.comentario_ventas, '')
	,cuenta_sublinea=ISNULL(subl.contabilidad,'')

	,[descuento1] = @descuento1
	,[descuento2] = @descuento2
	,[descuento3] = @descuento3
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
	a.codigo = @codarticulo 

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
			,[marca] = m.nombre
			,[idum] = um.idum
			,[maneja_lote] = a.lotes
			,a.autorizable
			,um.factor
			,unidad = um.codigo
			,[idmoneda_m] = ISNULL(vlm.idmoneda, 0)
			,[tipocambio_m] = ISNULL(bm.tipocambio, 1)
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

SELECT * FROM #_tmp_articuloDatos

DROP TABLE #_tmp_articuloDatos
GO