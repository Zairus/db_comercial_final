USE db_comercial_final
GO
-- 	SP:		SPHOTKEY
--
--	Funcion:	Regresar la información de un artículo para realizar la consulta rapida CTRL+F1
--	Fecha:		Enero 2007
--
--	Autor:		Laurence Saavedra
-- EXEC spHotKey '0600009',0,''
ALTER PROCEDURE [dbo].[spHotKey]
	@codarticulo 		VARCHAR(20),
	@codsuc 			SMALLINT,
	@codcliente 		VARCHAR(15) = ''
AS
SET NOCOUNT ON
DECLARE @tot BIT
SELECT @tot=CASE WHEN @codsuc=0 THEN 1 ELSE 0 END, @codsuc=0


-- Para habilitar que siempre se regresen todas las sucursales :  SET @codsuc=0
--SET @codsuc=0


-- La ventana interpreta la siguiente tabla temporal, que se regresa en un query:
-- Los campos que se requieren son:
--	RENGLON = Numero de renglon
--	COLUMNA = Numero de columna
-- 	VALOR = Lo que mostrará la celda
--	PROPIEDADES = Las propiedades para formatear la celda
-- 		FORMAT 	Es la mascara de visualizacion
-- 		FONTNAME 	Nombre de  la letra
-- 		FONTSIZE 	Tamaño de la letra
-- 		FONTBOLD 	Verdadero si se muestra en negritas
-- 		FONTITALIC 	Verdadero si se muestra italico
-- 		FONTCOLOR	Color de la letra en decimal
-- 		BACKCOLOR 	Color de fondo
--	COMANDO = Es el comando que ejecutará al darle click al boton en la celda

CREATE TABLE #tmp_hotkey (	
				id 			INT IDENTITY, 
				renglon 	SMALLINT DEFAULT 1,
				columna 	SMALLINT DEFAULT 1,
				valor 		VARCHAR(1000) DEFAULT '',
				propiedades	VARCHAR(1000) DEFAULT '',
				comando		VARCHAR(1000) DEFAULT '')

DECLARE 
	@totales			BIT
	,@nombre			VARCHAR(100)
	,@existencia		DECIMAL(15,4)
	,@comprometida		DECIMAL(15,4)
	,@pedidoscliente	DECIMAL(15,4)
	,@pedidosprovee		DECIMAL(15,4)
	,@precio1			DECIMAL(15,4)
	,@precio2			DECIMAL(15,4)
	,@precio3			DECIMAL(15,4)
	,@precio4			DECIMAL(15,4)
	,@precio5			DECIMAL(15,4)
	,@ultimo_costo		DECIMAL(15,4)
	,@costo_prom		DECIMAL(15,4)
	,@codprecio			TINYINT
	,@codprecio_mayoreo	TINYINT
	,@codprecio3	TINYINT
	,@codprecio4	TINYINT
	,@codprecio5	TINYINT
	,@texistencia		DECIMAL(15,4)
	,@tcomprometida		DECIMAL(15,4)
	,@tpedidoscliente	DECIMAL(15,4)
	,@tpedidosprovee	DECIMAL(15,4)
	,@cadena			VARCHAR(250)
	,@cadena2			VARCHAR(250)
	,@moneda			VARCHAR(20)
	,@r					SMALLINT
	,@col				SMALLINT
	,@c1				SMALLINT
	,@c2				SMALLINT
	,@lista				SMALLINT
	,@descto			DECIMAL(5,2)
	,@lp				VARCHAR(50)
	,@idarticulo		SMALLINT
	,@idcliente			SMALLINT

IF @codsuc>0
BEGIN
	SET @c1=@codsuc
	SET @c2=@codsuc
	SET @totales=0
END
ELSE
BEGIN
	SET @c1=1
	SET @c2=99
	SET @totales=1
END
SET @codprecio=0
SELECT @lista=0, @codprecio=1, @codprecio_mayoreo=2, @codprecio3=3, @codprecio4=4,@codprecio5=5,@descto=0

-- Obtenemos el idarticulo en base al codarticulo y vefificamos si este existe
SELECT TOP 1 @idarticulo = idarticulo FROM ew_articulos WHERE codigo=@codarticulo
IF LEN(@idarticulo)=0 
BEGIN
	-- Salimos y Regresamos la tabla temporal
	SELECT * FROM #tmp_hotkey
	RETURN
END

IF @codcliente != ''
BEGIN
	SELECT 
		@lista=ISNULL(tc.idpolitica,0)
		--------------------- ANTES-----------------------
		--,@codprecio=ISNULL(cp.codprecio,1)
		--,@codprecio_mayoreo=ISNULL(cp.codprecio_mayoreo,2)
		--------------------------------------------------
		-------- DESPUES (Nov. 12, 2015 por VBP) ---------
		,@codprecio=1
		,@codprecio_mayoreo=2
		,@codprecio3=3
		,@codprecio4=4
		,@codprecio5=5
		--------------------------------------------------
		,@descto = ISNULL(cp.descuento_limite,0)
		,@idcliente = c.idcliente 
	FROM 
		ew_clientes c
		LEFT JOIN ew_clientes_terminos tc ON tc.idcliente = c.idcliente
		LEFT JOIN ew_ven_politicas cp ON cp.idpolitica=tc.idpolitica
		--LEFT JOIN art_listaprecios_det ld ON ld.idlista=c.idlista AND ld.codarticulo=@codarticulo
	WHERE 
		c.codigo = @codcliente		
END



-- Aqui declaramos los CAPTIONS de los renglones
INSERT INTO #tmp_hotkey (renglon, columna, valor, propiedades) VALUES(1,0,'Disponible para Venta:','ALIGNMENT LEFT')
INSERT INTO #tmp_hotkey (renglon, columna, valor, propiedades) VALUES(2,0,'-   Existencia','ALIGNMENT LEFT')
INSERT INTO #tmp_hotkey (renglon, columna, valor, propiedades) VALUES(3,0,'-   Comprometida','ALIGNMENT LEFT')

INSERT INTO #tmp_hotkey (renglon, columna, valor, propiedades) VALUES(5,0,'Pedidos a Proveedor  :','ALIGNMENT LEFT')

INSERT INTO #tmp_hotkey (renglon, columna, valor, propiedades) VALUES(7,0,'Lista de Precios','ALIGNMENT LEFT')
INSERT INTO #tmp_hotkey (renglon, columna, valor, propiedades) VALUES(8,0,'-  Moneda','ALIGNMENT LEFT')
INSERT INTO #tmp_hotkey (renglon, columna, valor, propiedades) VALUES(9,0,'-  Precio No. 1','ALIGNMENT LEFT')
INSERT INTO #tmp_hotkey (renglon, columna, valor, propiedades) VALUES(10,0,'-  Precio No. 2','ALIGNMENT LEFT')
INSERT INTO #tmp_hotkey (renglon, columna, valor, propiedades) VALUES(11,0,'-  Precio No. 3','ALIGNMENT LEFT')
INSERT INTO #tmp_hotkey (renglon, columna, valor, propiedades) VALUES(12,0,'-  Precio No. 4','ALIGNMENT LEFT')
INSERT INTO #tmp_hotkey (renglon, columna, valor, propiedades) VALUES(13,0,'-  Precio No. 5','ALIGNMENT LEFT')
--INSERT INTO #tmp_hotkey (renglon, columna, valor, propiedades) VALUES(10,0,'Ultimo Costo M.N.','ALIGNMENT LEFT')
--INSERT INTO #tmp_hotkey (renglon, columna, valor, propiedades) VALUES(11,0,'Costo Promedio M.N.','ALIGNMENT LEFT')
--INSERT INTO #tmp_hotkey (renglon, columna, valor, propiedades) VALUES(13,0,'Tipo de Cambio ','ALIGNMENT LEFT')
--INSERT INTO #tmp_hotkey (renglon, columna, valor) VALUES(10,2,'')

DECLARE @tc DECIMAL(10,3)
SELECT @tc = tipocambio FROM ew_ban_monedas where idmoneda =1

SET @r=0
SET @col=0
SELECT @texistencia=0, @tpedidoscliente=0, @tpedidosprovee=0
DECLARE cur_hotkey CURSOR FOR
	SELECT 	
		suc_art.idsucursal 
		,nombre = (SELECT TOP 1  nombre FROM ew_sys_sucursales WHERE idsucursal=suc_art.idsucursal)
		,existencia = dbo.fn_inv_existenciaSucursal(suc_art.idarticulo, suc_art.idsucursal)
		,pedidoscliente = dbo.fn_ven_pedidos(suc_art.idarticulo, suc_art.idsucursal,1)
		,pedidosprovee = dbo.fn_com_pedidos(suc_art.idarticulo, suc_art.idsucursal,1)
		,costo_ultimo
		,costo_promedio
		,precio1=(CASE @codprecio WHEN 2 THEN lp.precio2 WHEN 3 THEN lp.precio3 WHEN 4 THEN lp.precio4 WHEN 5 THEN lp.precio5 ELSE lp.precio1 END) 
		,precio2=(CASE @codprecio_mayoreo WHEN 2 THEN lp.precio2 WHEN 3 THEN lp.precio3 WHEN 4 THEN lp.precio4 WHEN 5 THEN lp.precio5 ELSE lp.precio1 END) 
		,precio3=(CASE @codprecio3 WHEN 2 THEN lp.precio2 WHEN 3 THEN lp.precio3 WHEN 4 THEN lp.precio4 WHEN 5 THEN lp.precio5 ELSE lp.precio1 END) 
		,precio4=(CASE @codprecio4 WHEN 2 THEN lp.precio2 WHEN 3 THEN lp.precio3 WHEN 4 THEN lp.precio4 WHEN 5 THEN lp.precio5 ELSE lp.precio1 END) 
		,precio5=(CASE @codprecio5 WHEN 2 THEN lp.precio2 WHEN 3 THEN lp.precio3 WHEN 4 THEN lp.precio4 WHEN 5 THEN lp.precio5 ELSE lp.precio1 END) 
		,moneda=(SELECT nombre FROM ew_ban_monedas WHERE idmoneda=lp.idmoneda)
		,[lp]=l.nombre
	FROM 
		ew_articulos_sucursales suc_art 
		LEFT JOIN ew_sys_sucursales s ON s.idsucursal = suc_art.idsucursal
		LEFT JOIN ew_ven_listaprecios l ON l.idlista=(CASE WHEN @codcliente='' THEN s.idlista ELSE @lista END)
		LEFT JOIN ew_ven_listaprecios_mov lp ON lp.idlista=@lista AND lp.idarticulo=@idarticulo
	WHERE 
		suc_art.idarticulo = @idarticulo
		AND suc_art.idsucursal BETWEEN @c1 AND @c2
	ORDER BY
		(CASE WHEN suc_art.idsucursal = @codsuc THEN  0 ELSE 1 END), suc_art.idsucursal
		

OPEN cur_hotkey
FETCH NEXT FROM cur_hotkey INTO @codsuc, @nombre, @existencia, @pedidoscliente, @pedidosprovee, @ultimo_costo, @costo_prom, @precio1, @precio2, @precio3, @precio4, @precio5, @moneda, @lp
WHILE @@fetch_status=0
BEGIN

	SET @col=@col+1
	IF @existencia IS NULL
		SET @existencia=0
	IF @comprometida IS NULL
		SET @comprometida=0
	IF @pedidoscliente IS NULL
		SET @pedidoscliente=0
	IF @pedidosprovee IS NULL
		SET @pedidosprovee=0
		
	-- Regresamos los valores para cada sucursal
	INSERT INTO #tmp_hotkey (renglon, columna, valor, propiedades) VALUES(0,@col,@nombre, 'ALIGNMENT CENTER')

	INSERT INTO #tmp_hotkey (renglon, columna, valor, comando, propiedades) 
	VALUES(1, @col, CONVERT(VARCHAR(15), @existencia-@pedidoscliente),
		'	
		SELECT 
			Almacen=aa.nombre
			,a.existencia
			,[comprometida] = dbo.fn_inv_existenciaComprometida(a.idarticulo, a.idalmacen)
			,disponible = a.existencia - dbo.fn_inv_existenciaComprometida(a.idarticulo, a.idalmacen)
		FROM 
			ew_articulos_almacenes a 
			LEFT JOIN ew_inv_almacenes aa ON aa.idalmacen=a.idalmacen 	
		WHERE 
			a.idarticulo = ' + CONVERT(VARCHAR(10),@idarticulo) + ' 
			AND aa.idsucursal = ' + CONVERT(VARCHAR(3),@codsuc)
		,'FORMAT #,##0
		FONTBOLD 1')
	INSERT INTO #tmp_hotkey (renglon, columna, valor, comando, propiedades) 
	VALUES(2, @col, CONVERT(VARCHAR(15), @existencia),
	'
		SELECT 
			Almacen=aa.nombre
			,a.existencia 
		FROM 
			ew_articulos_almacenes a 
			LEFT JOIN ew_inv_almacenes aa ON aa.idalmacen = a.idalmacen 
		WHERE 
			a.idarticulo = ' + CONVERT(VARCHAR(10),@idarticulo) + ' 
			AND aa.idsucursal = ' + CONVERT(VARCHAR(3),@codsuc)
		,'' )
	INSERT INTO #tmp_hotkey (renglon, columna, valor, comando, propiedades) 
	VALUES(3, @col, CONVERT(VARCHAR(15), @pedidoscliente),
		'SELECT 
			  o.folio
			  ,o.fecha
			  ,cantidad = ISNULL((cantidad_autorizada - om.cantidad_surtida + cantidad_devuelta),0)
			  ,estado = dbo.fn_sys_estadoActualNombre(o.idtran)	
			  ,codcliente = c.codigo
			  ,nombre = c.nombre
			  ,almacen = a.nombre	
		FROM 
			ew_ven_ordenes_mov om
			LEFT JOIN ew_ven_ordenes o ON o.idtran = om.idtran
			LEFT JOIN ew_clientes c ON c.idcliente = o.idcliente
			LEFT JOIN ew_inv_almacenes a ON a.idalmacen = o.idalmacen
		WHERE 
			cantidad_autorizada - om.cantidad_surtida + cantidad_devuelta   > 0
			AND om.idarticulo = ' + CONVERT(VARCHAR(10),@idarticulo) + '
			AND o.idsucursal = ' + CONVERT(VARCHAR(3),@codsuc) + '
			AND dbo.fn_sys_estadoActual(o.idtran) BETWEEN 3 AND 250 
		', 'FORMAT #,##0')


	INSERT INTO #tmp_hotkey (renglon, columna, valor, comando, propiedades) 
	VALUES(5, @col, CONVERT(VARCHAR(15), @pedidosprovee),
	'
		SELECT 
			  o.folio
			  ,o.fecha
			  ,cantidad = ISNULL((cantidad_autorizada - om.cantidad_surtida + cantidad_devuelta),0)
			  ,estado = dbo.fn_sys_estadoActualNombre(o.idtran)	
			  ,codprovee = p.codigo
			  ,nombre = p.nombre
			  ,almacen = a.nombre	
		FROM 
			ew_com_ordenes_mov om
			LEFT JOIN ew_com_ordenes o ON o.idtran = om.idtran
			LEFT JOIN ew_proveedores p ON p.idproveedor = o.idproveedor
			LEFT JOIN ew_inv_almacenes a ON a.idalmacen = om.idalmacen
		WHERE 
			cantidad_autorizada - om.cantidad_surtida + cantidad_devuelta   > 0
			AND om.idarticulo = ' + CONVERT(VARCHAR(10),@idarticulo) + '
			AND o.idsucursal = ' + CONVERT(VARCHAR(3),@codsuc) + '
			AND dbo.fn_sys_estadoActual(o.idtran) BETWEEN 3 AND 250 
	'
	, 'FORMAT #,##0')
	SET @cadena='FORMAT $ #,##0'
	IF @col=1
		SET @cadena2='
FONTBOLD 1
BACKCOLOR 48000'
	ELSE
		SET @cadena2=''
	INSERT INTO #tmp_hotkey (renglon, columna, valor, comando, propiedades) VALUES(7, @col, @lp, '', 'ALIGNMENT CENTER
FONTITALIC 1
FONTSIZE 10')
	INSERT INTO #tmp_hotkey (renglon, columna, valor, comando, propiedades) VALUES(8, @col,@moneda, '', 'ALIGNMENT RIGHT
FONTITALIC 1
FONTSIZE 10')

	INSERT INTO #tmp_hotkey (renglon, columna, valor, comando, propiedades) VALUES(9, @col, CONVERT(VARCHAR(15), @precio1),'','FORMAT $ #,##0.#0
FONTBOLD 1' )
	INSERT INTO #tmp_hotkey (renglon, columna, valor, comando, propiedades) VALUES(10, @col, CONVERT(VARCHAR(15), @precio2),'','FORMAT $ #,##0.#0' )
	INSERT INTO #tmp_hotkey (renglon, columna, valor, comando, propiedades) VALUES(11, @col, CONVERT(VARCHAR(15), @precio3),'','FORMAT $ #,##0.#0' )
	INSERT INTO #tmp_hotkey (renglon, columna, valor, comando, propiedades) VALUES(12, @col, CONVERT(VARCHAR(15), @precio4),'','FORMAT $ #,##0.#0' )
	INSERT INTO #tmp_hotkey (renglon, columna, valor, comando, propiedades) VALUES(13, @col, CONVERT(VARCHAR(15), @precio5),'','FORMAT $ #,##0.#0' )
	--INSERT INTO #tmp_hotkey (renglon, columna, valor, comando, propiedades) VALUES(11, @col, CONVERT(VARCHAR(15), @precio3),'','FORMAT $ #,##0.#0' + (CASE WHEN @codprecio=3 THEN  @cadena2 ELSE '' END))
	--INSERT INTO #tmp_hotkey (renglon, columna, valor, comando, propiedades) VALUES(12, @col, CONVERT(VARCHAR(15), @precio4),'','FORMAT $ #,##0.#0' + (CASE WHEN @codprecio=4 THEN  @cadena2 ELSE '' END))
	--INSERT INTO #tmp_hotkey (renglon, columna, valor, comando, propiedades) VALUES(13, @col, CONVERT(VARCHAR(15), @precio5),'','FORMAT $ #,##0.#0' + (CASE WHEN @codprecio=5 THEN  @cadena2 ELSE '' END))

	--INSERT INTO #tmp_hotkey (renglon, columna, valor, comando, propiedades) VALUES(10, @col, CONVERT(VARCHAR(15), @ultimo_costo),'','FORMAT $ #,##0.#0')
	--INSERT INTO #tmp_hotkey (renglon, columna, valor, comando, propiedades) VALUES(11, @col, CONVERT(VARCHAR(15), @costo_prom),'','FORMAT $ #,##0.#0')

	SELECT @texistencia=@texistencia + @existencia, @tpedidoscliente=@tpedidoscliente+@pedidoscliente, @tpedidosprovee=@tpedidosprovee+@pedidosprovee
	FETCH NEXT FROM cur_hotkey INTO @codsuc, @nombre, @existencia, @pedidoscliente, @pedidosprovee, @ultimo_costo, @costo_prom, @precio1, @precio2, @precio3, @precio4, @precio5, @moneda, @lp
END
CLOSE cur_hotkey
DEALLOCATE cur_hotkey
-- Regresamos los totales generales:

IF @tot=1 
BEGIN
	SET @col=@col+1
	INSERT INTO #tmp_hotkey (renglon, columna, valor) VALUES(0,@col,'T o t a l e s')

	INSERT INTO #tmp_hotkey (renglon, columna, valor, comando, propiedades) VALUES(1, @col , CONVERT(VARCHAR(15), @texistencia-@tpedidoscliente),'','FORMAT #,##0 
FONTBOLD 1
FONTSIZE 12
FONTCOLOR 16000' )
	INSERT INTO #tmp_hotkey (renglon, columna, valor, comando, propiedades) VALUES(2, @col , CONVERT(VARCHAR(15), @texistencia),'','FORMAT #,##0
FONTBOLD 1
FONTSIZE 11
FONTCOLOR 16000' )
	INSERT INTO #tmp_hotkey (renglon, columna, valor, comando, propiedades) VALUES(3, @col , CONVERT(VARCHAR(15), @tpedidoscliente),'','FORMAT #,##0
FONTBOLD 1
FONTSIZE 11
FONTCOLOR 16000' )
	INSERT INTO #tmp_hotkey (renglon, columna, valor, comando, propiedades) VALUES(5, @col , CONVERT(VARCHAR(15), @tpedidosprovee),'','FORMAT #,##0
FONTBOLD 1
FONTSIZE 11
FONTCOLOR 16000' )
	INSERT INTO #tmp_hotkey (renglon, columna, valor) VALUES(0, @col+1 , '...')
	--INSERT INTO #tmp_hotkey (renglon, columna, valor, propiedades) VALUES(13,1, CONVERT(VARCHAR(15), @TC),'FORMAT #,##0.##0' )
END
ELSE
BEGIN
	INSERT INTO #tmp_hotkey (renglon, columna, valor) VALUES(8,2,'')
END

-- Regresamos la tabla temporal
SELECT * FROM #tmp_hotkey
GO
