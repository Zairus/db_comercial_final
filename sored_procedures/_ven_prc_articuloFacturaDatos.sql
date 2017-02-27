USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110224
-- Description:	Datos de articulo en factura de ventas
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_articuloFacturaDatos] 
	 @codarticulo AS VARCHAR(30)
	,@idalmacen AS SMALLINT
	,@idcliente AS INT
	,@idmoneda AS SMALLINT
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACION DE VARIABLES ####################################################

DECLARE
	@idarticulo AS INT

DECLARE
	 @idsucursal AS SMALLINT
	,@iva AS DECIMAL(12,2)
	,@idlista AS SMALLINT

DECLARE
	 @idmoneda_venta AS SMALLINT
	,@tipocambio AS DECIMAL(15,4)
	,@tipocambio_venta AS DECIMAL(15,4)
	,@tipocambio_lista AS DECIMAL(15,4)
	,@precio_venta AS DECIMAL(18,6)
	,@precio_venta_validar AS DECIMAL(18,6)
	,@precio_mayoreo AS DECIMAL(18,6)
	,@costo_ultimo AS DECIMAL(18,6)

DECLARE
	 @negociado AS BIT
	,@precio_especial AS DECIMAL(18,6)

DECLARE
	@error_mensaje AS VARCHAR(500)

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

SELECT
	@idarticulo = idarticulo
FROM
	ew_articulos AS a
WHERE
	a.codigo = @codarticulo

SELECT
	 @idsucursal = alm.idsucursal
	,@iva = s.iva
	,@idlista = s.idlista
FROM
	ew_inv_almacenes AS alm
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = alm.idsucursal
WHERE
	alm.idalmacen = @idalmacen

IF @iva = 0 OR @iva IS NULL
BEGIN
	SELECT @iva = 16.00
END

SELECT 
	@tipocambio_venta = tipocambio
FROM
	ew_ban_monedas
WHERE
	idmoneda = @idmoneda

SELECT
	@costo_ultimo = [as].costo_ultimo
FROM
	ew_articulos_sucursales AS [as]
WHERE
	[as].idsucursal = @idsucursal
	AND [as].idarticulo = @idarticulo
	
--------------------------------------------------------------------------------
-- CALCULAR TIPO DE CAMBIO POR MONEDA DE PRECIO Y MONEDA DE VENTA ##############
SELECT
	 @idmoneda_venta = vlm.idmoneda
	,@tipocambio_lista = bm.tipocambio
	,@precio_venta = (
		CASE vp.codprecio
			WHEN 1 THEN vlm.precio1
			WHEN 2 THEN vlm.precio2
			WHEN 3 THEN vlm.precio3
			WHEN 4 THEN vlm.precio4
			ELSE vlm.precio5
		END
	)
	,@precio_venta_validar = (CASE WHEN vlm.idmoneda = 0 THEN vlm.precio1 ELSE vlm.precio1 * bm.tipocambio END)
	,@precio_mayoreo = vlm.precio3
FROM
	ew_ven_listaprecios_mov AS vlm
	LEFT JOIN ew_ban_monedas AS bm
		ON bm.idmoneda = vlm.idmoneda
	LEFT JOIN ew_clientes_terminos AS ctr
		ON ctr.idcliente = @idcliente
	LEFT JOIN ew_ven_politicas AS vp
		ON vp.idpolitica = ctr.idpolitica
WHERE
	vlm.idlista = @idlista
	AND vlm.idarticulo = @idarticulo

SELECT @tipocambio = (@tipocambio_lista / @tipocambio_venta)

--------------------------------------------------------------------------------
-- CALCULANDO PRECIO PARA EL CLIENTE ###########################################

SELECT
	 @negociado = negociado
	,@precio_especial = precio_especial
FROM
	ew_clientes_inventario
WHERE
	idcliente = @idcliente
	AND idarticulo = @idarticulo

SELECT @negociado = ISNULL(@negociado, 0)
SELECT @precio_especial = ISNULL(@precio_especial, 0)

IF @negociado = 1 AND @precio_especial > 0
BEGIN
	SELECT @precio_venta = @precio_especial
END
	ELSE
BEGIN
	SELECT @precio_venta = (@precio_venta * @tipocambio)
END

--------------------------------------------------------------------------------
-- VALIDAR PRECIO Y COSTO ######################################################

IF @precio_venta_validar < @costo_ultimo
BEGIN
	SELECT @error_mensaje = 'Error: El precio [' + LTRIM(RTRIM(STR(@precio_venta_validar))) + '] es inferior al costo [' + LTRIM(RTRIM(STR(@costo_ultimo))) + '].'
	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

--------------------------------------------------------------------------------
-- PRESENTAR DATOS #############################################################

SELECT
	 [codarticulo] = a.codigo
	,a.nombre
	,a.idarticulo
	,[existencia] = aa.existencia
	,[iva] = @iva
	,[precio_unitario] = @precio_venta
	,[mensaje] = 'Ok'
	,[tipocambio] = @tipocambio
	,[costo_promedio] = aa.costo_promedio
	,[precio_minimo] = (CASE WHEN [as].bajo_costo = 1 THEN 0 ELSE aa.costo_ultimo END)
	,[costo] = aa.costo_ultimo
	,[costo_ultimo] = aa.costo_ultimo
	,[cambiar_precio] = [as].cambiar_precio
FROM
	ew_articulos AS a
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idarticulo = a.idarticulo
		AND aa.idalmacen = @idalmacen
	LEFT JOIN ew_articulos_sucursales AS [as]
		ON [as].idarticulo = a.idarticulo
		AND [as].idsucursal = @idsucursal
WHERE
	a.idarticulo = @idarticulo
GO
