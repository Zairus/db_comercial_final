USE [db_comercial_final]
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
AS

SET NOCOUNT ON

DECLARE
	@idarticulo AS INT
	,@descuento1 AS DECIMAL(18,6)
	,@descuento2 AS DECIMAL(18,6)
	,@descuento3 AS DECIMAL(18,6)
	,@descuentos_codigos AS VARCHAR(100)

DECLARE
	 @idpromocion AS INT
	,@cantidad_minima AS DECIMAL(18,6)

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

CREATE TABLE #_tmp_articuloDatos (
	[id] INT IDENTITY
	,[codarticulo] VARCHAR(30) NOT NULL DEFAULT ''
	,[idarticulo] INT NOT NULL
	,[descripcion] VARCHAR(500) NOT NULL DEFAULT ''
	,[idalmacen] INT NOT NULL
	,[idum] INT NOT NULL DEFAULT 0
	,[cantidad_facturada] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[precio_venta] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[idimpuesto1] INT NOT NULL DEFAULT 1
	,[idimpuesto1_valor] DECIMAL(15,2) NOT NULL DEFAULT 0
	,[descuento1] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[descuento2] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[descuento3] DECIMAL(18,6) NOT NULL DEFAULT 0
	,[descuentos_codigos] VARCHAR(100) NOT NULL DEFAULT ''
	,[contabilidad] VARCHAR(20)
	,[autorizable] BIT NOT NULL DEFAULT 0
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
	,descuento1
	,descuento2
	,descuento3
	,descuentos_codigos
	,contabilidad
	,autorizable
)

SELECT
	[codarticulo] = a.codigo
	,a.idarticulo
	,[descripcion] = a.nombre
	,[idalmacen] = @idalmacen
	,[idum] = a.idum_venta
	,[cantidad_facturada] = @cantidad
	,[precio_venta] = ISNULL(vlm.precio1, 0)
	,[idimpuesto1] = ci.idimpuesto
	,[idimpuesto1_valor] = ci.valor
	,[descuento1] = @descuento1
	,[descuento2] = @descuento2
	,[descuento3] = @descuento3
	,[descuentos_codigos] = @descuentos_codigos
	,[contabilidad] = an.contabilidad
	,[autorizable] = a.autorizable
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
			,cantidad_facturada
			,precio_venta
			,idimpuesto1
			,idimpuesto1_valor
			,contabilidad
		)
		SELECT
			[codarticulo] = a.codigo
			,[idarticulo] = a.idarticulo
			,[descripcion] = a.nombre
			,[idalmacen] = @idalmacen
			,[idum] = a.idum_venta
			,[cantidad_facturada] = vpa.cantidad
			,[precio_venta] = vpa.precio_venta
			,[idimpuesto1] = ci.idimpuesto
			,[idimpuesto1_valor] = ci.valor
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

SELECT * FROM #_tmp_articuloDatos

DROP TABLE #_tmp_articuloDatos
GO
