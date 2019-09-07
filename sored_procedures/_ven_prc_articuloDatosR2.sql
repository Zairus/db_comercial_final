USE db_comercial_final
GO
IF OBJECT_ID('_ven_prc_articuloDatosR2') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_prc_articuloDatosR2
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190131
-- Description:	Obtencion de datos de articulo para venta
-- =============================================
CREATE PROCEDURE [dbo].[_ven_prc_articuloDatosR2]
	@codarticulo AS VARCHAR(MAX)
	, @idalmacen AS SMALLINT
	, @idcliente AS INT
	, @idlista AS SMALLINT
	, @idpolitica AS SMALLINT
	, @idmoneda AS SMALLINT = 0
	, @tipocambio AS DECIMAL(18,6) = NULL
	, @credito AS BIT = 0
	, @cantidad AS DECIMAL(18,6) = 0
	, @precio_actual AS DECIMAL(18,6) = 0
AS

SET NOCOUNT ON

DECLARE
	@idzona_fiscal_emisor AS INT
	, @idsucursal AS INT
	, @decimales AS SMALLINT

DECLARE
	@idarticulo AS INT
	, @codarticulo_linea AS VARCHAR(30)

DECLARE
	@descuento1 AS DECIMAL(18,6)
	, @descuento2 AS DECIMAL(18,6)
	, @descuento3 AS DECIMAL(18,6)
	, @descuentos_codigos AS VARCHAR(100)
	, @precio_fijo AS DECIMAL(18,6) = 0
	, @bajo_costo AS BIT = 0

DECLARE
	@codarticulo_p AS VARCHAR(30)
	, @idpromocion AS INT
	, @cantidad_p AS DECIMAL(18,6)
	, @precio_p AS DECIMAL(18,6)

DECLARE
	@reg_id AS INT = 0
	, @reg_clave AS VARCHAR(20) = ''
	, @error_message AS VARCHAR(MAX) = NULL

DECLARE
	@idimpuesto1 AS INT
	, @idimpuesto1_valor AS DECIMAL(18, 6)
	, @idimpuesto1_cuenta AS VARCHAR(50)
	, @idimpuesto2 AS INT
	, @idimpuesto2_valor AS DECIMAL(18, 6)
	, @idimpuesto2_cuenta AS VARCHAR(50)
	, @idimpuesto1_ret AS INT
	, @idimpuesto1_ret_valor AS DECIMAL(18, 6)
	, @idimpuesto1_ret_cuenta AS VARCHAR(50)
	, @idimpuesto2_ret AS INT
	, @idimpuesto2_ret_valor AS DECIMAL(18, 6)
	, @idimpuesto2_ret_cuenta AS VARCHAR(50)
	
SELECT
	@idsucursal = alm.idsucursal
FROM
	ew_inv_almacenes AS alm
WHERE
	alm.idalmacen = @idalmacen

SELECT
	@idlista = s.idlista
FROM
	ew_sys_sucursales AS s
WHERE
	s.idsucursal = @idsucursal
	AND (
		SELECT COUNT(*) 
		FROM 
			ew_ven_listaprecios 
		WHERE 
			idlista = @idlista
	) = 0

IF NOT EXISTS(SELECT * FROM ew_ven_listaprecios WHERE idlista = @idlista)
BEGIN
	RAISERROR('La lista de precios asignada al cliente no existe. Vaya al Catálogo de Términos con Cliente y asígnele una lista válida.', 16, 1)
	RETURN
END

CREATE TABLE #_tmp_articulo_datos (
	[id] INT IDENTITY
	, [codarticulo] VARCHAR(30) NOT NULL DEFAULT ''
	, [idlista] INT NOT NULL DEFAULT 0
	, [idarticulo] INT NOT NULL DEFAULT 0
	, [idtipo] INT NOT NULL DEFAULT 0
	, [nombre] VARCHAR(500) NOT NULL DEFAULT ''
	, [descripcion] VARCHAR(500) NOT NULL DEFAULT ''
	, [nombre_corto] VARCHAR(100) NOT NULL DEFAULT ''
	, [marca] VARCHAR(200) NOT NULL DEFAULT ''
	, [clasif_SAT] VARCHAR(50) NOT NULL DEFAULT ''
	, [idum] INT NOT NULL DEFAULT 0
	, [maneja_lote] BIT NOT NULL DEFAULT 0
	, [autorizable] BIT NOT NULL DEFAULT 0
	, [factor] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [unidad] VARCHAR(10) NOT NULL DEFAULT ''
	, [idmoneda_m] SMALLINT NOT NULL DEFAULT 0
	, [tipocambio_m] DECIMAL(18,6) NOT NULL DEFAULT 1
	, [kit] BIT NOT NULL DEFAULT 0
	, [inventariable] BIT NOT NULL DEFAULT 0
	, [serie] BIT NOT NULL DEFAULT 0
	, [cantidad_facturada] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [precio_unitario] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [precio_unitario_m] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [precio_unitario_m2] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [precio_minimo] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [existencia] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [comprometida] DECIMAL(18,6) NOT NULL DEFAULT 0

	, [idimpuesto1] INT NOT NULL DEFAULT 1
	, [idimpuesto1_valor] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [idimpuesto1_cuenta] VARCHAR(20) NOT NULL DEFAULT ''
	, [idimpuesto2] INT NOT NULL DEFAULT 0
	, [idimpuesto2_valor] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [idimpuesto2_cuenta] VARCHAR(20) NOT NULL DEFAULT ''
	, [idimpuesto1_ret] INT NOT NULL DEFAULT 0
	, [idimpuesto1_ret_valor] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [idimpuesto1_ret_cuenta] VARCHAR(20) NOT NULL DEFAULT ''
	, [idimpuesto2_ret] INT NOT NULL DEFAULT 0
	, [idimpuesto2_ret_valor] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [idimpuesto2_ret_cuenta] VARCHAR(20) NOT NULL DEFAULT ''
	, [ingresos_cuenta] VARCHAR(20) NOT NULL DEFAULT ''

	, [cambiar_precio] BIT NOT NULL DEFAULT 0
	, [precio_congelado] BIT NOT NULL DEFAULT 0
	, [cantidad_mayoreo] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [max_descuento1] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [max_descuento2] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [cuenta_sublinea] VARCHAR(20) NOT NULL DEFAULT ''
	, [descuento1] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [descuento2] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [descuento3] DECIMAL(18,6) NOT NULL DEFAULT 0

	, [costo] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [costo_promedio] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [costo_ultimo] DECIMAL(18,6) NOT NULL DEFAULT 0

	, [costo_bajo] BIT NOT NULL DEFAULT 0

	, [objerrmsg] VARCHAR(MAX) NOT NULL DEFAULT ''
	, [mensaje] VARCHAR(MAX) NOT NULL DEFAULT ''
	, [objlevel] INT NOT NULL DEFAULT 0

	, [reg_clave] VARCHAR(20) NOT NULL DEFAULT ''
) ON [PRIMARY]

SELECT @precio_actual = 0

SELECT @decimales = CONVERT(SMALLINT, ISNULL(dbo.fn_sys_parametro('LISTAPRECIOS_DECIMALES'), '2'))

SELECT @idzona_fiscal_emisor = [dbo].[_ct_fnc_idzonaFiscal](@idsucursal)

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
	SELECT
		@idarticulo = a.idarticulo
	FROM
		ew_articulos AS a
	WHERE
		a.codigo = @codarticulo_linea
	
	SELECT
		@idimpuesto1 = cit.idimpuesto
		, @idimpuesto1_valor = cit.tasa
		, @idimpuesto1_cuenta = cit.contabilidad1
	FROM 
		ew_articulos_impuestos_tasas AS ait
		LEFT JOIN ew_cat_impuestos_tasas AS cit
			ON cit.idtasa = ait.idtasa
		LEFT JOIN ew_cat_impuestos AS ci
			ON ci.idimpuesto = cit.idimpuesto
	WHERE
		ait.idarticulo = @idarticulo
		AND (
			ait.idzona = @idzona_fiscal_emisor
			OR ait.idzona = 0
		)
		AND cit.tipo = 1
		AND ci.grupo = 'IVA'

	SELECT
		@idimpuesto2 = cit.idimpuesto
		, @idimpuesto2_valor = cit.tasa
		, @idimpuesto2_cuenta = cit.contabilidad1
	FROM 
		ew_articulos_impuestos_tasas AS ait
		LEFT JOIN ew_cat_impuestos_tasas AS cit
			ON cit.idtasa = ait.idtasa
		LEFT JOIN ew_cat_impuestos AS ci
			ON ci.idimpuesto = cit.idimpuesto
	WHERE
		ait.idarticulo = @idarticulo
		AND (
			ait.idzona = @idzona_fiscal_emisor
			OR ait.idzona = 0
		)
		AND cit.tipo = 1
		AND ci.grupo = 'IEPS'

	SELECT
		@idimpuesto1_ret = cit.idimpuesto
		, @idimpuesto1_ret_valor = cit.tasa
		, @idimpuesto1_ret_cuenta = cit.contabilidad1
	FROM 
		ew_articulos_impuestos_tasas AS ait
		LEFT JOIN ew_cat_impuestos_tasas AS cit
			ON cit.idtasa = ait.idtasa
		LEFT JOIN ew_cat_impuestos AS ci
			ON ci.idimpuesto = cit.idimpuesto
	WHERE
		ait.idarticulo = @idarticulo
		AND (
			ait.idzona = @idzona_fiscal_emisor
			OR ait.idzona = 0
		)
		AND cit.tipo = 2
		AND ci.grupo = 'IVA'

	SELECT
		@idimpuesto2_ret = cit.idimpuesto
		, @idimpuesto2_ret_valor = cit.tasa
		, @idimpuesto2_ret_cuenta = cit.contabilidad1
	FROM 
		ew_articulos_impuestos_tasas AS ait
		LEFT JOIN ew_cat_impuestos_tasas AS cit
			ON cit.idtasa = ait.idtasa
		LEFT JOIN ew_cat_impuestos AS ci
			ON ci.idimpuesto = cit.idimpuesto
	WHERE
		ait.idarticulo = @idarticulo
		AND (
			ait.idzona = @idzona_fiscal_emisor
			OR ait.idzona = 0
		)
		AND cit.tipo = 2
		AND ci.grupo = 'ISR'

	INSERT INTO #_tmp_articulo_datos
	EXEC [dbo].[_ven_prc_articuloDatosRegistro]
		@codarticulo_linea
		, @idlista
		, @idcliente
		, @idsucursal
		, @idalmacen

	UPDATE #_tmp_articulo_datos SET
		cantidad_facturada = @cantidad
	WHERE
		@cantidad IS NOT NULL
		AND @cantidad > 0

	EXEC [dbo].[_ven_prc_descuentosValores]
		@idsucursal
		, @idcliente
		, @credito
		, @idarticulo
		, @cantidad
		, @descuento1 OUTPUT
		, @descuento2 OUTPUT
		, @descuento3 OUTPUT
		, @descuentos_codigos OUTPUT
		, @precio_fijo OUTPUT
		, @bajo_costo OUTPUT
		
	UPDATE tad SET
		tad.descuento1 = @descuento1
		, tad.descuento2 = @descuento2
		, tad.descuento3 = @descuento3
		, tad.precio_unitario = (CASE WHEN @precio_fijo = 0 THEN tad.precio_unitario ELSE @precio_fijo END)
		, tad.precio_unitario_m = (CASE WHEN @precio_fijo = 0 THEN tad.precio_unitario_m ELSE @precio_fijo END)
		, tad.precio_unitario_m2 = (CASE WHEN @precio_fijo = 0 THEN tad.precio_unitario_m2 ELSE @precio_fijo END)
		, tad.precio_minimo = (CASE WHEN @precio_fijo = 0 THEN tad.precio_minimo ELSE @precio_fijo END)
	FROM
		#_tmp_articulo_datos AS tad
		
	UPDATE tad SET
		tad.precio_unitario = @precio_actual
		, tad.precio_unitario_m = @precio_actual
		, tad.precio_unitario_m2 = @precio_actual
		, tad.precio_minimo = @precio_actual
	FROM
		#_tmp_articulo_datos AS tad
	WHERE
		@precio_actual > 0

	IF @cantidad > 0
	BEGIN
		DECLARE cur_promociones CURSOR FOR
			SELECT DISTINCT
				 vpc.idpromocion
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

		WHILE @@FETCH_STATUS = 0
		BEGIN
			WHILE EXISTS (SELECT * FROM ew_ven_promociones_acciones WHERE @idpromocion = @idpromocion AND idr > @reg_id)
			BEGIN
				SELECT
					@reg_id = MIN(vpa.idr)
				FROM
					ew_ven_promociones_acciones AS vpa
				WHERE
					vpa.idpromocion = @idpromocion
					AND vpa.idr > @reg_id

				SELECT
					@codarticulo_p = a.codigo
					, @cantidad_p = vpa.cantidad
					, @precio_p = vpa.precio_venta
					, @reg_clave = 'promo' + LTRIM(RTRIM(STR(vpa.idr)))
				FROM
					ew_ven_promociones_acciones AS vpa
					LEFT JOIN ew_articulos AS a
						ON a.idarticulo = vpa.idarticulo
				WHERE
					vpa.idr = @reg_id

				INSERT INTO #_tmp_articulo_datos
				EXEC [dbo].[_ven_prc_articuloDatosRegistro]
					@codarticulo_p
					, @idlista
					, @idcliente
					, @idsucursal
					, @idalmacen
					, 0 --@precio_factor
					, 1 --@objlevel
					, @reg_clave --@reg_clave

				UPDATE tad SET
					tad.cantidad = @cantidad_p
					, tad.precio_unitario = @precio_p
					, tad.precio_unitario_m = @precio_p
					, tad.precio_unitario_m2 = @precio_p
					, tad.precio_minimo = @precio_p
				FROM
					#_tmp_articulo_datos AS tad
				WHERE
					tad.reg_clave = @reg_clave
			END
			
			FETCH NEXT FROM cur_promociones INTO
				@idpromocion
		END

		CLOSE cur_promociones
		DEALLOCATE cur_promociones
	END

	SELECT @reg_id = 0

	WHILE EXISTS (SELECT * FROM ew_articulos_insumos WHERE idarticulo_superior = @idarticulo AND idr > @reg_id)
	BEGIN
		SELECT @reg_id = MIN(idr)
		FROM
			ew_articulos_insumos
		WHERE
			idarticulo_superior = @idarticulo
			AND idr > @reg_id

		SELECT
			@codarticulo_p = a.codigo
			, @cantidad_p = ai.cantidad
			, @reg_clave = 'kit' + LTRIM(RTRIM(STR(ai.idr)))
		FROM
			ew_articulos_insumos AS ai
			LEFT JOIN ew_articulos AS a
				ON a.idarticulo = ai.idarticulo
		WHERE
			ai.idr = @reg_id
			
		INSERT INTO #_tmp_articulo_datos
		EXEC [dbo].[_ven_prc_articuloDatosRegistro]
			@codarticulo_p
			, @idlista
			, @idcliente
			, @idsucursal
			, @idalmacen
			, 0 --@precio_factor
			, 1 --@objlevel
			, @reg_clave --@reg_clave

		UPDATE tad SET
			tad.cantidad_facturada = @cantidad_p * @cantidad
		FROM
			#_tmp_articulo_datos AS tad
		WHERE
			tad.reg_clave = @reg_clave
	END

	FETCH NEXT FROM cur_articulosDatos INTO
		@codarticulo_linea
END

CLOSE cur_articulosDatos
DEALLOCATE cur_articulosDatos

UPDATE tad SET
	tad.precio_unitario = ci.precio_especial
	, tad.precio_unitario_m = ci.precio_especial
	, tad.precio_unitario_m2 = ci.precio_especial
	, tad.precio_minimo = ci.precio_especial
FROM
	#_tmp_articulo_datos AS tad
	LEFT JOIN ew_clientes_inventario AS ci
		ON ci.idcliente = @idcliente
		AND ci.idarticulo = tad.idarticulo
WHERE
	ci.id IS NOT NULL
	AND tad.reg_clave = ''

UPDATE tad SET
	tad.precio_unitario = tad.precio_unitario * (tad.tipocambio_m / @tipocambio)
	, tad.precio_unitario_m = tad.precio_unitario_m * (tad.tipocambio_m / @tipocambio)
	, tad.precio_unitario_m2 = tad.precio_unitario_m2 * (tad.tipocambio_m / @tipocambio)
	--, tad.precio_minimo = tad.precio_minimo * (tad.tipocambio_m / @tipocambio)
FROM
	#_tmp_articulo_datos AS tad
WHERE
	tad.idmoneda_m <> @idmoneda
	AND @tipocambio IS NOT NULL

UPDATE tad SET
	tad.idimpuesto1 = ISNULL(@idimpuesto1, tad.idimpuesto1)
	, tad.idimpuesto1_valor = ISNULL(@idimpuesto1_valor, tad.idimpuesto1_valor)
	, tad.idimpuesto1_cuenta = ISNULL(@idimpuesto1_cuenta, tad.idimpuesto1_cuenta)

	, tad.idimpuesto2 = ISNULL(@idimpuesto2, tad.idimpuesto2)
	, tad.idimpuesto2_valor = ISNULL(@idimpuesto2_valor, tad.idimpuesto2_valor)
	, tad.idimpuesto2_cuenta = ISNULL(@idimpuesto2_cuenta, tad.idimpuesto2_cuenta)

	, tad.idimpuesto1_ret = ISNULL(@idimpuesto1_ret, tad.idimpuesto1_ret)
	, tad.idimpuesto1_ret_valor = ISNULL(@idimpuesto1_ret_valor, tad.idimpuesto1_ret_valor)
	, tad.idimpuesto1_ret_cuenta = ISNULL(@idimpuesto1_ret_cuenta, tad.idimpuesto1_ret_cuenta)

	, tad.idimpuesto2_ret = ISNULL(@idimpuesto2_ret, tad.idimpuesto2_ret)
	, tad.idimpuesto2_ret_valor = ISNULL(@idimpuesto2_ret_valor, tad.idimpuesto2_ret_valor)
	, tad.idimpuesto2_ret_cuenta = ISNULL(@idimpuesto2_ret_cuenta, tad.idimpuesto2_ret_cuenta)
FROM
	#_tmp_articulo_datos AS tad

UPDATE tad SET
	tad.precio_unitario = ROUND(tad.precio_unitario, @decimales)
	, tad.precio_unitario_m = ROUND(tad.precio_unitario_m, @decimales)
	, tad.precio_unitario_m2 = ROUND(tad.precio_unitario_m2, @decimales)
	, tad.precio_minimo = ROUND(tad.precio_minimo, @decimales)
FROM
	#_tmp_articulo_datos AS tad

UPDATE tad SET
	tad.objerrmsg = (
		tad.objerrmsg
		+ 'El precio [' + CONVERT(VARCHAR(20), tad.precio_unitario) + '] es inferior al costo [' + CONVERT(VARCHAR(20), tad.costo_ultimo) + ']||'
	)
FROM
	#_tmp_articulo_datos AS tad
WHERE
	tad.precio_unitario < tad.costo_ultimo
	AND tad.costo_bajo = 0
	AND ABS(@precio_actual) > 0

SELECT
	@error_message = 
	(
		SELECT
			'[Codigo: ' + tad.codarticulo + ']'
			+ '||'
			+ tad.objerrmsg
			+ '||'
			+ ''
		FROM
			#_tmp_articulo_datos AS tad
		WHERE 
			LEN(ISNULL(objerrmsg, '')) > 0
		FOR XML PATH('')
	)

IF @error_message IS NOT NULL
BEGIN
	DROP TABLE #_tmp_articulo_datos

	SELECT @error_message = (
		'Los siguientes productos presentan problemas: '
		+ CHAR(13)
		+ '---------------------------------------------'
		+ CHAR(13)
		+ REPLACE(@error_message, '||', ChAR(13))
	)

	RAISERROR(@error_message, 16, 1)
	RETURN
END

SELECT * 
	, [cantidad_solicitada] = tad.cantidad_facturada
	, [cantidad_ordenada] = tad.cantidad_facturada
	, [cantidad_autorizada] = tad.cantidad_facturada
FROM 
	#_tmp_articulo_datos AS tad

DROP TABLE #_tmp_articulo_datos
GO
