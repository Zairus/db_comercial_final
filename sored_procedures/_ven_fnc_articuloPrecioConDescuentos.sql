USE db_comercial_final
GO
IF OBJECT_ID('_ven_fnc_articuloPrecioConDescuentos') IS NOT NULL
BEGIN
	DROP FUNCTION _ven_fnc_articuloPrecioConDescuentos
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20191114
-- Description:	Obtener precio de articulo con descuentos aplicados
-- =============================================
CREATE FUNCTION [dbo].[_ven_fnc_articuloPrecioConDescuentos]
(
	@idsucursal AS INT
	, @articulo_codigo AS VARCHAR(30)
	, @cliente_codigo AS VARCHAR(30)
	, @credito AS BIT
	, @cantidad AS DECIMAL(18, 6)
)
RETURNS DECIMAL (18,6)
AS
BEGIN
	DECLARE
		@precio_unitario AS DECIMAL(18,6)
		, @preciodesc AS DECIMAL (18, 6)
		, @idcliente AS INT
		, @idpolitica AS INT
		, @idarticulo AS INT

	DECLARE
		@articulos_descuento_valor AS DECIMAL(18,6) = 100.00
		, @descuento2 AS DECIMAL(18, 6)

	SELECT
		@idcliente = c.idcliente
		, @idpolitica = ctr.idpolitica
	FROM
		ew_clientes AS c
		LEFT JOIN ew_clientes_terminos AS ctr
			ON ctr.idcliente = c.idcliente
	WHERE
		c.codigo = @cliente_codigo

	SELECT
		@idarticulo = a.idarticulo
	FROM
		ew_articulos AS a
	WHERE
		a.codigo = @articulo_codigo

	SELECT
		@precio_unitario = ISNULL((
			CASE 
				WHEN vp.codprecio IS NULL THEN vlm.precio1
				WHEN vp.codprecio = 1 THEN vlm.precio1
				WHEN vp.codprecio = 2 THEN vlm.precio2
				WHEN vp.codprecio = 3 THEN vlm.precio3
				WHEN vp.codprecio = 4 THEN vlm.precio4
				WHEN vp.codprecio = 5 THEN vlm.precio5
			END
		), 0)
	FROM 
		ew_articulos AS a
		LEFT JOIN ew_sys_sucursales AS s
			ON s.idsucursal = @idsucursal
		LEFT JOIN ew_clientes AS c
			ON c.codigo = @cliente_codigo
		LEFT JOIN ew_clientes_terminos AS ctr
			ON ctr.idcliente = c.idcliente
		LEFT JOIN ew_ven_politicas AS vp
			ON vp.idpolitica = ctr.idpolitica
		LEFT JOIN ew_ven_listaprecios_mov AS vlm
			ON vlm.idlista = ISNULL(ctr.idlista, s.idlista)
			AND vlm.idarticulo = a.idarticulo
	WHERE
		a.codigo = @articulo_codigo

	SELECT @precio_unitario = ISNULL(@precio_unitario, 0)	
	SELECT @preciodesc = ISNULL(@preciodesc, 0)

	SELECT
		@articulos_descuento_valor = (@articulos_descuento_valor - (@articulos_descuento_valor * (vd.valor / 100)))
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
								AND vda.codigo = ISNULL((
									SELECT anl.codigo
									FROM 
										ew_articulos AS a
										LEFT JOIN ew_articulos_niveles AS anl
											ON anl.nivel = 2
											AND anl.codigo = a.nivel2
									WHERE
										a.codigo = @articulo_codigo
								), '')
							)
							OR (
								vda.grupo = 3
								AND vda.codigo = ISNULL((
									SELECT anl.codigo
									FROM 
										ew_articulos AS a
										LEFT JOIN ew_articulos_niveles AS anl
											ON anl.nivel = 3
											AND anl.codigo = a.nivel3
									WHERE
										a.codigo = @articulo_codigo
								), '')
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

	SELECT @descuento2 = 100.0 - @articulos_descuento_valor

	SELECT @preciodesc = @precio_unitario - (@precio_unitario * (@descuento2 / 100))

	SELECT @preciodesc = ISNULL(@preciodesc, 0)

	RETURN @preciodesc
END
GO
