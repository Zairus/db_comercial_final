USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150615
-- Description:	Datos de articulo en ticket de venta
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_ticketVentaArticuloDatos]
	@codigo AS VARCHAR(30)
	,@idsucursal AS SMALLINT
	,@idalmacen AS SMALLINT
	,@idcliente AS SMALLINT
	,@idlista AS SMALLINT

	,@credito AS BIT = 0
	,@cantidad AS DECIMAL(18,6) = 0

	,@llave AS VARCHAR(8) = ''
AS

SET NOCOUNT ON

DECLARE
	@idarticulo AS INT
	,@descuento1 AS DECIMAL(18,6)
	,@descuento2 AS DECIMAL(18,6)
	,@descuento3 AS DECIMAL(18,6)
	,@descuentos_codigos AS VARCHAR(100)
	,@precio_fijo AS DECIMAL(18,6) = 0

DECLARE
	@idpromocion AS INT
	,@cantidad_minima AS DECIMAL(18,6)
	,@no_incluir_iva INT = 0

DECLARE
	@i AS TINYINT

SELECT @no_incluir_iva = CONVERT(INT, ISNULL(dbo.fn_sys_parametro('NOTAS_VENTA_SIN_IVA'), '0'))

IF LEN(@llave) = 0
BEGIN
	SELECT @i = 0

	WHILE @i < 8
	BEGIN
		SELECT @llave = @llave + CONVERT(VARCHAR(1), FLOOR(RAND() *  10))
		SELECT @i = @i + 1
	END
END

SELECT
	@idarticulo = idarticulo
FROM
	ew_articulos
WHERE
	codigo = @codigo

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

CREATE TABLE #_tmp_articuloDatos (
	[id] INT IDENTITY
	,[codarticulo] VARCHAR(30) NOT NULL DEFAULT ''
	,[idarticulo] INT NOT NULL
	,[descripcion] VARCHAR(500) NOT NULL DEFAULT ''
	,[idalmacen] INT NOT NULL
	,[idum] INT NOT NULL DEFAULT 0
	,[promocion] TINYINT NOT NULL DEFAULT 0
	,[cantidad_facturada] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[precio_venta] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[idimpuesto1] INT NOT NULL DEFAULT 1
	,[idimpuesto1_valor] DECIMAL(15,2) NOT NULL DEFAULT 0
	,[idimpuesto1_cuenta] VARCHAR(20) NOT NULL DEFAULT ''
	,[idimpuesto2] INT NOT NULL DEFAULT 1
	,[idimpuesto2_valor] DECIMAL(15,2) NOT NULL DEFAULT 0
	,[idimpuesto2_cuenta] VARCHAR(20) NOT NULL DEFAULT ''
	,[idimpuesto1_ret] INT NOT NULL DEFAULT 0
	,[idimpuesto1_ret_valor] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[idimpuesto1_ret_cuenta] VARCHAR(20) NOT NULL DEFAULT ''
	,[idimpuesto2_ret] INT NOT NULL DEFAULT 0
	,[idimpuesto2_ret_valor] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[idimpuesto2_ret_cuenta] VARCHAR(20) NOT NULL DEFAULT ''
	,[ingresos_cuenta] VARCHAR(20) NOT NULL DEFAULT ''
	,[descuento1] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[descuento2] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[descuento3] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[descuentos_codigos] VARCHAR(100) NOT NULL DEFAULT ''
	,[contabilidad] VARCHAR(20)
	,[autorizable] BIT NOT NULL DEFAULT 0
	,[inventariable] BIT NOT NULL DEFAULT 1
)

INSERT INTO #_tmp_articuloDatos (
	codarticulo
	,idarticulo
	,descripcion
	,idalmacen
	,idum
	,cantidad_facturada
	,precio_venta
	,idimpuesto1
	,idimpuesto1_valor
	,idimpuesto1_cuenta
	,idimpuesto2
	,idimpuesto2_valor
	,idimpuesto2_cuenta
	,idimpuesto1_ret
	,idimpuesto1_ret_valor
	,idimpuesto1_ret_cuenta
	,idimpuesto2_ret
	,idimpuesto2_ret_valor
	,idimpuesto2_ret_cuenta
	,ingresos_cuenta
	,descuento1
	,descuento2
	,descuento3
	,descuentos_codigos
	,contabilidad
	,autorizable
	,inventariable
)

SELECT
	[codarticulo] = a.codigo
	,a.idarticulo
	,[descripcion] = a.nombre
	,[idalmacen] = @idalmacen
	,[idum] = a.idum_venta
	,[cantidad_facturada] = @cantidad
	,[precio_venta] = (
		CASE 
			WHEN @precio_fijo = 0 THEN ISNULL((
				CASE vp.codprecio 
					WHEN 1 THEN vlm.precio1 
					WHEN 2 THEN vlm.precio2 
					WHEN 3 THEN vlm.precio3 
					WHEN 4 THEN vlm.precio4 
					ELSE vlm.precio5 
				END
			), 0) 
			ELSE @precio_fijo 
		END
	)
	--########################################################
	,[idimpuesto1] = ISNULL((
		SELECT TOP 1
			(CASE WHEN @no_incluir_iva = 1 THEN 0 ELSE cit.idimpuesto END)
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
	), ci.idimpuesto)
	,[idimpuesto1_valor] = ISNULL((
		SELECT TOP 1
			(CASE WHEN @no_incluir_iva = 1 THEN 0 ELSE cit.tasa END)
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
	), ci.valor)
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
	), ci.contabilidad)
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
	), ISNULL((SELECT TOP 1 ci1.contabilidad FROM ew_cat_impuestos AS ci1 WHERE ci1.idimpuesto = a.idimpuesto2), 0))
	,[idimpuesto1_ret] = 0
	,[idimpuesto1_ret_valor] = 0
	,[idimpuesto1_ret_cuenta] = ''
	,[idimpuesto2_ret] = 0
	,[idimpuesot2_ret_valor] = 0
	,[idimpuesto2_ret_cuenta] = ''
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
	), '4100001000')
	--########################################################
	,[descuento1] = @descuento1
	,[descuento2] = @descuento2
	,[descuento3] = @descuento3
	,[descuentos_codigos] = @descuentos_codigos
	,[contabilidad] = an.contabilidad
	,[autorizable] = a.autorizable
	,[inventariable] = a.inventariable
FROM
	ew_articulos AS a
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = @idsucursal
	LEFT JOIN ew_cat_impuestos AS ci
		ON ci.idimpuesto = (CASE WHEN a.idimpuesto1 = 0 THEN s.idimpuesto ELSE a.idimpuesto1 END)
	LEFT JOIN ew_ven_listaprecios_mov AS vlm
		ON vlm.idlista = @idlista
		AND vlm.idarticulo = a.idarticulo
	LEFT JOIN ew_articulos_almacenes AS ea
		ON ea.idarticulo = a.idarticulo
		AND ea.idalmacen = @idalmacen
	LEFT JOIN ew_articulos_niveles AS an
		ON an.codigo = a.nivel3

	LEFT JOIN ew_clientes_terminos AS ctr
		ON ctr.idcliente = @idcliente
	LEFT JOIN ew_ven_politicas AS vp
		ON vp.idpolitica = ctr.idpolitica
WHERE
	a.codigo = @codigo

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
			codarticulo
			,idarticulo
			,descripcion
			,idalmacen
			,idum
			,promocion
			,cantidad_facturada
			,precio_venta
			,idimpuesto1
			,idimpuesto1_valor
			,idimpuesto2
			,idimpuesto2_valor
			,contabilidad
		)
		SELECT
			[codarticulo] = a.codigo
			,[idarticulo] = a.idarticulo
			,[descripcion] = a.nombre
			,[idalmacen] = @idalmacen
			,[idum] = a.idum_venta
			,[promocion] = 1
			,[cantidad_facturada] = vpa.cantidad
			,[precio_venta] = vpa.precio_venta
			--########################################################
			,[idimpuesto1] = ISNULL((
				SELECT
					(CASE WHEN @no_incluir_iva = 1 THEN 0 ELSE cit.idimpuesto END)
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
			), ci.idimpuesto)
			,[idimpuesto1_valor] = ISNULL((
				SELECT
					CASE WHEN @no_incluir_iva = 1 THEN 0 ELSE cit.tasa END
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
			), ci.valor)
			,[idimpuesto2] = ISNULL((
				SELECT
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
				SELECT
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
			--########################################################
			,[contabilidad] = an.contabilidad
		FROM
			ew_ven_promociones_acciones AS vpa
			LEFT JOIN ew_articulos AS a
				ON a.idarticulo = vpa.idarticulo
			LEFT JOIN ew_sys_sucursales AS s
				ON s.idsucursal = @idsucursal
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = (CASE WHEN a.idimpuesto1 = 0 THEN s.idimpuesto ELSE a.idimpuesto1 END)
			LEFT JOIN ew_articulos_niveles AS an
				ON an.codigo = a.nivel3
		WHERE
			vpa.idpromocion = @idpromocion
		
		FETCH NEXT FROM cur_promociones INTO
			 @idpromocion
			,@cantidad_minima
	END
	
	CLOSE cur_promociones
	DEALLOCATE cur_promociones
END

SELECT
	 [tad].[codarticulo]
	, [tad].[idarticulo]
	, [tad].[descripcion]
	, [tad].[idalmacen]
	, [tad].[idum]
	, [tad].[promocion]
	, [tad].[cantidad_facturada]
	, [tad].[precio_venta]
	, [tad].[idimpuesto1]
	, [tad].[idimpuesto1_valor]
	, [tad].[idimpuesto1_cuenta]
	, [tad].[idimpuesto2]
	, [tad].[idimpuesto2_valor]
	, [tad].[idimpuesto2_cuenta]
	, [tad].[idimpuesto1_ret]
	, [tad].[idimpuesto1_ret_valor]
	, [tad].[idimpuesto1_ret_cuenta]
	, [tad].[idimpuesto2_ret]
	, [tad].[idimpuesto2_ret_valor]
	, [tad].[idimpuesto2_ret_cuenta]
	, [tad].[ingresos_cuenta]
	, [max_descuento1] = [tad].[descuento1]
	, [max_descuento2] = [tad].[descuento2]
	, [max_descuento3] = [tad].[descuento3]
	, [descuento1] = 0.00
	, [descuento2] =[tad].[descuento2]
	, [descuento3] = [tad].[descuento3]
	, [tad].[descuentos_codigos]
	, [tad].[contabilidad]
	, [tad].[autorizable]
	, [tad].[inventariable]
	, [llave] = @llave 
FROM 
	#_tmp_articuloDatos AS tad

DROP TABLE #_tmp_articuloDatos
GO
