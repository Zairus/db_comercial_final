USE db_comercial_final
GO
IF OBJECT_ID('_ven_rpt_gananciaSVenta') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_rpt_gananciaSVenta
END
GO
-- =============================================
-- Author:		Fernanda Corona
-- Create date: ABRIL 2012
-- Description:	Auxiliar de ganancia sobre venta
-- =============================================
CREATE PROCEDURE [dbo].[_ven_rpt_gananciaSVenta]
	@idmoneda AS SMALLINT = -1
	, @idsucursal AS SMALLINT = 0
	, @idalmacen AS SMALLINT = 0
	, @fecha1 AS DATETIME = NULL
	, @fecha2 AS DATETIME = NULL
	, @idcliente AS SMALLINT = 0
	, @idarticulo AS INT = 0
	, @detallado AS BIT = 1
AS

SET DATEFORMAT DMY
SET NOCOUNT ON

SELECT @fecha1 = CONVERT(VARCHAR(10), ISNULL(@fecha1, DATEADD(MONTH, -1, GETDATE())), 103) + ' 00:00'
SELECT @fecha2 = CONVERT(VARCHAR(10), ISNULL(@fecha2, GETDATE()), 103) + ' 23:59'

SELECT
	[moneda] = m.nombre
	, [sucursal] = s.nombre
	, [almacen] = a.nombre
	, [conteo] = (CASE WHEN ea.inventariable <> 0 THEN  'INVENTARIABLE' ELSE 'NO INVENTARIABLE' END)
	, [cliente] = ISNULL(ec.codigo, 'Sin Especificar') + ' - ' + ec.nombre
	, [idtran] = vt.idtran
	, [fecha] = vt.fecha
	, [folio] = vt.folio
	, [referencia] = o.folio
	, [articulo] = (CASE WHEN @detallado = 1 THEN '( '+ea.codigo+' ) .- '+ea.nombre ELSE '' END)
	, [cantidad_facturada] = vm.cantidad_facturada
	, [costo] = (
		CASE 
			WHEN vm.cantidad_facturada = 0 THEN 0 
			ELSE ROUND(vm.costo, 2) 
		END
	)
	, [imp_total] = (vm.importe * vt.tipocambio)
	, [tipocambio] = vt.tipocambio
	, [ganancia] = 0/*(
		CASE 
			WHEN vm.cantidad_facturada = 0 THEN 0 
			ELSE ROUND(((vm.importe * vt.tipocambio) - vm.costo), 2) 
		END
	)*/
	, [margen] = 0/*(
		CASE 
			WHEN (vm.cantidad_facturada = 0 OR vm.importe = 0) THEN 0 
			ELSE ((ROUND(((vm.importe * vt.tipocambio) - vm.costo), 2) / (vm.importe * vt.tipocambio)) * 100) 
		END
	)*/
	, [impuesto1] = vm.impuesto1
	, [descuento1] = vm.descuento1
	, [importe] = (vm.importe * vt.tipocambio)

	, [efa_idmov] = vm.idmov
	, [eor_idmov] = vm.idmov2
INTO 
	#Temporal
FROM 
	ew_ven_transacciones_mov AS vm
	LEFT JOIN ew_ven_transacciones AS vt 
		ON vt.idtran = vm.idtran
	LEFT JOIN ew_ven_ordenes AS o 
		ON o.idtran = vt.idtran2
	LEFT JOIN ew_sys_sucursales AS s 
		ON s.idsucursal = vt.idsucursal
	LEFT JOIN ew_inv_almacenes AS a 
		ON a.idalmacen = vt.idalmacen
	LEFT JOIN ew_clientes AS ec 
		ON ec.idcliente = vt.idcliente
	LEFT JOIN ew_articulos AS ea 
		ON ea.idarticulo = vm.idarticulo
	LEFT JOIN ew_ban_monedas AS m 
		ON m.idmoneda = vt.idmoneda
	LEFT JOIN conceptos AS cc 
		ON cc.idconcepto = vt.idconcepto
WHERE
	vt.cancelado = 0
	AND vt.transaccion IN ('EFA1', 'EFA4', 'EFA6')

	AND vt.idmoneda = ISNULL(NULLIF(@idmoneda, -1), vt.idmoneda)
	AND vt.idsucursal = ISNULL(NULLIF(@idsucursal, 0), vt.idsucursal)
	AND vt.idalmacen = ISNULL(NULLIF(@idalmacen, 0), vt.idalmacen)
	AND vt.idcliente = ISNULL(NULLIF(@idcliente, 0), vt.idcliente)
	AND vm.idarticulo = ISNULL(NULLIF(@idarticulo, 0), vm.idarticulo)
	AND vt.fecha BETWEEN @fecha1 AND @fecha2
ORDER BY
	vt.idsucursal
	, vt.idalmacen
	, vt.idmoneda
	, ea.inventariable DESC
	, vt.fecha
	, vm.idarticulo

UPDATE t SET
	t.costo = ISNULL((
		itm.costo
	), 0)
FROM
	#Temporal AS t
	LEFT JOIN ew_inv_transacciones_mov AS itm
		ON itm.tipo = 2
		AND itm.idmov2 = t.eor_idmov
WHERE
	t.costo = 0

UPDATE t SET
	t.ganancia = (
		CASE
			WHEN t.cantidad_facturada = 0 THEN 0
			ELSE ROUND((t.imp_total - t.costo), 2)
		END
	)
	, t.margen = (
		CASE
			WHEN t.cantidad_facturada = 0 OR t.imp_total = 0 THEN 0
			ELSE ((ROUND((t.imp_total - t.costo), 2) / t.imp_total) * 100)
		END
	)
FROM
	#Temporal AS t

IF @detallado = 1
BEGIN
	SELECT * FROM #Temporal
END
	ELSE
BEGIN
	SELECT
		[sucursal]
		, [almacen]
		, [moneda]
		, [conteo] = t.conteo
		, [cliente]
		, [idtran]
		, [fecha] = t.fecha
		, [folio]
		, [referencia]
		, [articulo]

		, [cantidad_facturada] = SUM(cantidad_facturada)
		, [costo] = (CASE WHEN SUM(cantidad_facturada) = 0 THEN 0 ELSE ROUND(SUM(costo), 2) END)
		, [imp_total] = (SUM(importe) * t.tipocambio)

		, [ganancia] = (CASE WHEN SUM(cantidad_facturada) = 0 THEN 0 ELSE ROUND(((SUM(importe) * t.tipocambio) - SUM(costo)), 2) END)
		, [margen] = (
			CASE 
				WHEN (SUM(cantidad_facturada) = 0 OR SUM(importe) = 0) THEN 0 
				ELSE ((ROUND(((SUM(importe) * t.tipocambio) - SUM(costo)), 2) / (SUM(importe) * t.tipocambio)) * 100) 
			END
		)
		, [impuesto1] = SUM(impuesto1)
		, [descuento1] = SUM(descuento1)
		, [importe] = (SUM(importe) * t.tipocambio)
	FROM #Temporal AS t
	LEFT JOIN ew_sys_sucursales AS s 
		ON s.nombre = t.sucursal
	LEFT JOIN ew_inv_almacenes AS a 
		ON a.nombre = t.almacen
	LEFT JOIN ew_ban_monedas AS m 
		ON m.codigo = t.moneda
	GROUP BY
		s.idsucursal
		, t.sucursal
		, a.idalmacen
		, t.almacen
		, m.idmoneda
		, t.moneda
		, t.conteo
		, [cliente]
		, idtran
		, t.fecha
		, folio
		, referencia
		, articulo
		, t.tipocambio
	ORDER BY
		s.idsucursal
		, a.idalmacen
		, m.idmoneda
		, t.conteo
		, t.fecha
END
GO
