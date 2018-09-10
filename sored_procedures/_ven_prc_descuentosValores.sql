USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20151030
-- Description:	Valores de descuentos
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_descuentosValores]
	@idsucursal AS INT
	,@idcliente AS INT
	,@credito AS BIT
	,@idarticulo AS INT
	,@cantidad AS DECIMAL(18,6)
	,@descuento1 AS DECIMAL(18,6) OUTPUT
	,@descuento2 AS DECIMAL(18,6) OUTPUT
	,@descuento3 AS DECIMAL(18,6) OUTPUT
	,@codigos AS VARCHAR(200) OUTPUT
	,@precio AS DECIMAL(18,6) = 0 OUTPUT
	,@bajo_costo AS BIT = 0 OUTPUT
AS

SET NOCOUNT ON

DECLARE
	@articulos_descuento_valor AS DECIMAL(18,6) = 100.00
	,@idpolitica AS INT
	,@articulo_codigo AS VARCHAR(30)
	,@iddescuento AS INT

SELECT @descuento1 = 0
SELECT @descuento2 = 0
SELECT @descuento3 = 0
SELECT @codigos = ''

SELECT
	@articulo_codigo = a.codigo
FROM
	ew_articulos AS a
WHERE
	a.idarticulo = @idarticulo

SELECT
	@descuento1 = vp.descuento_linea
	,@idpolitica = vp.idpolitica
FROM 
	ew_clientes_terminos AS ctr
	LEFT JOIN ew_ven_politicas AS vp
		ON vp.idpolitica = ctr.idpolitica
WHERE 
	ctr.idcliente = @idcliente

--Articulos
--#1;Artículo|#2;Linea|#3;Sublinea|#255;Todos

--Clientes
--#1,Un Cliente|#2,Grupo Políticas de Ventas|#3,Clasificación de Clientes|#255,Todos
--idcondicionpago
--0,Credito ó Contado|1,Solo Contado|2,Solo Credito|

SELECT
	@codigos = @codigos + vd.coddescuento + ', '
	,@articulos_descuento_valor = @articulos_descuento_valor - (@articulos_descuento_valor * (vd.valor / 100))
	,@iddescuento = vd.iddescuento
FROM
	ew_ven_descuentos AS vd
WHERE
	vd.activo = 1
	AND GETDATE() BETWEEN vd.fecha_inicio AND vd.fecha_final
	AND (
		@idsucursal IN (SELECT s.valor FROM dbo._sys_fnc_separarMultilinea(vd.condicion, ',') AS s)
		OR vd.condicion = '0'
	)
	AND (
		(
			(
				SELECT COUNT(*)
				FROM
					ew_ven_descuentos_articulos AS vda
				WHERE
					vda.iddescuento  = vd.iddescuento
					AND vda.activo = 1
					AND @cantidad BETWEEN vda.cantidad_minima AND (CASE WHEN vda.cantidad_maxima = 0 THEN 9999999999999 ELSE vda.cantidad_maxima END)
					AND (
						(
							vda.grupo = 1
							AND vda.codigo = @articulo_codigo
						)
						OR (
							vda.grupo = 2
						)
						OR (
							vda.grupo = 3
						)
						OR vda.grupo = 255
					)
			) > 0
			OR (
				SELECT COUNT(*)
				FROM
					ew_ven_descuentos_articulos AS vda
				WHERE
					vda.iddescuento = vd.iddescuento
			) = 0
		)
		AND (
			(
				SELECT COUNT(*)
				FROM
					ew_ven_descuentos_clientes AS vdc
				WHERE
					vdc.iddescuento = vd.iddescuento
					AND vdc.activo = 1
					AND (
						(
							vdc.grupo = 1
							AND vdc.codigo = @idcliente
						)
						OR (
							vdc.grupo = 2
							AND vdc.codigo = @idpolitica
						)
						OR (
							vdc.grupo = 3
						)
						OR vdc.grupo = 255
					)
					AND (
						(
							vdc.idcondicionpago = 1
							AND 0 = @credito
						)
						OR (
							vdc.idcondicionpago = 2
							AND 1 = @credito
						)
						OR vdc.idcondicionpago = 0
					)
			) > 0
			OR (
				SELECT COUNT(*) 
				FROM 
					ew_ven_descuentos_clientes AS vdc 
				WHERE 
					vdc.iddescuento = vd.iddescuento
			) = 0
		)
	)

IF LEN(@codigos) > 0
	SELECT @codigos = LEFT(@codigos, LEN(@codigos) - 1)

SELECT @descuento2 = 100.0 - @articulos_descuento_valor

SELECT @iddescuento = ISNULL(@iddescuento, 0)

SELECT
	@descuento2 = 0
	,@precio = vda.precio
FROM
	ew_ven_descuentos_articulos AS vda
WHERE
	vda.precio > 0
	AND @iddescuento > 0
	AND vda.iddescuento = @iddescuento
	AND vda.codigo = @articulo_codigo

SELECT
	@bajo_costo = vda.bajo_costo
FROM
	ew_ven_descuentos_articulos AS vda
WHERE
	vda.iddescuento = @iddescuento
	AND vda.codigo = @articulo_codigo

SELECT
	@descuento1 = ISNULL(@descuento1, 0)
	,@descuento2 = ISNULL(@descuento2, 0)
	,@descuento3 = ISNULL(@descuento3, 0)
	,@codigos = ISNULL(@codigos, '')
GO
