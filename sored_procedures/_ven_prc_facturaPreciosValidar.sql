USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190123
-- Description:	Validar precios y costos de venta
-- =============================================
ALTER PROCEDURE _ven_prc_facturaPreciosValidar
	@idtran AS INT
	, @mostrar_costo AS BIT = 0
	, @error_mensaje AS VARCHAR(500) = NULL OUTPUT
AS

SET NOCOUNT ON

SELECT @error_mensaje = NULL

SELECT
	@error_mensaje = (
		'Error: No se puede vender el artículo '
		+ '[' + a.codigo + '] '
		+ a.nombre
		+ ', en ' + CONVERT(VARCHAR(25), CONVERT(DECIMAL(18,2), vtm.importe / vtm.cantidad_facturada))
		+ (
			CASE
				WHEN @mostrar_costo = 1 THEN
					', ya que queda por debajo del costo: '
					+ CONVERT(VARCHAR(25), CONVERT(DECIMAL(18, 2), (
						CASE
							WHEN c.mayoreo = 1 THEN (vtm.costo / vtm.cantidad_facturada)
							ELSE [dbo].[_ven_fnc_articuloPrecioMinimoPorSucursal](sa.idarticulo, sa.idsucursal, (vtm.costo / vtm.cantidad_facturada))
						END
					)))
					+ '; segun capas de almacén.'
				ELSE
					', por debajo del costo. ' 
			END
		)
	)
FROM
	ew_ven_transacciones_mov AS vtm
	LEFT JOIN ew_ven_transacciones AS vt
		ON vt.idtran = vtm.idtran
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vtm.idarticulo
	LEFT JOIN ew_articulos_sucursales AS sa
		ON sa.idsucursal = vt.idsucursal
		AND sa.idarticulo = vtm.idarticulo
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = vt.idcliente
WHERE
	vtm.idtran = @idtran
	AND sa.bajo_costo = 0
	AND a.inventariable = 1
	AND vtm.cantidad_facturada > 0
	AND (
		(vtm.importe / vtm.cantidad_facturada)
		<= (
			CASE
				WHEN c.mayoreo = 1 THEN (vtm.costo / vtm.cantidad_facturada)
				ELSE [dbo].[_ven_fnc_articuloPrecioMinimoPorSucursal](sa.idarticulo, sa.idsucursal, (vtm.costo / vtm.cantidad_facturada))
			END
		)
	)
GO
