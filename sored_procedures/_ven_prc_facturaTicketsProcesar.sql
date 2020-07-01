USE db_comercial_final
GO
IF OBJECT_ID('_ven_prc_facturaTicketsProcesar') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_prc_facturaTicketsProcesar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20121112
-- Description:	Procesar factura de tickets
-- =============================================
CREATE PROCEDURE [dbo].[_ven_prc_facturaTicketsProcesar]
	@idtran AS INT
	, @idu SMALLINT
AS

SET NOCOUNT ON

DECLARE
	 @total_detalle AS DECIMAL(18,6)
	, @total_documento AS DECIMAL(18,6)
	, @error_mensaje AS VARCHAR(1000)
	, @fecha AS DATETIME

INSERT INTO ew_ven_transacciones_mov (
	idtran
	, consecutivo
	, idmov2
	, idarticulo
	, idum
	, idalmacen
	, tipo
	, cantidad_ordenada
	, cantidad_autorizada
	, cantidad_surtida
	, cantidad_facturada
	, cantidad_devuelta
	, series
	, precio_unitario
	, descuento1
	, descuento2
	, descuento3
	, descuento_pp1
	, descuento_pp2
	, descuento_pp3
	, idimpuesto1
	, idimpuesto2
	, idimpuesto1_ret
	, idimpuesto2_ret
	, importe
	, impuesto1
	, impuesto2
	, impuesto3
	, impuesto4
	, costo
	, gastos
	, comentario
)
SELECT
	[idtran] = @idtran
	, [consecutivo] = ROW_NUMBER() OVER (ORDER BY @idtran)
	, [idmov2] = vtm.idmov
	, [idarticulo] = vtm.idarticulo
	, [idum] = vtm.idum
	, [idalmacen] = vtm.idalmacen
	, [tipo] = vtm.tipo
	, [cantidad_ordenada] = vtm.cantidad_ordenada
	, [cantidad_autorizada] = vtm.cantidad_autorizada
	, [cantidad_surtida] = vtm.cantidad_surtida
	, [cantidad_facturada] = vtm.cantidad_facturada
	, [cantidad_devuelta] = vtm.cantidad_devuelta
	, [series] = vtm.series
	, [precio_unitario] = vtm.precio_unitario
	, [descuento1] = vtm.descuento1
	, [descuento2] = vtm.descuento2
	, [descuento3] = vtm.descuento3
	, [descuento_pp1] = vtm.descuento_pp1
	, [descuento_pp2] = vtm.descuento_pp2
	, [descuento_pp3] = vtm.descuento_pp3
	, [idimpuesto1] = (CASE WHEN vtm.idimpuesto1 = 0 THEN 1 ELSE vtm.idimpuesto1 END)
	, [idimpuesto2] = (CASE WHEN vtm.idimpuesto2 = 0 THEN 11 ELSE vtm.idimpuesto2 END)
	, [idimpuesto1_ret] = 0
	, [idimpuesto2_ret] = 0
	, [importe] = vtm.importe
	, [impuesto1] = vtm.impuesto1
	, [impuesto2] = vtm.impuesto2
	, [impuesto3] = vtm.impuesto3
	, [impuesto4] = vtm.impuesto4
	, [costo] = vtm.costo
	, [gastos] = vtm.gastos
	, [comentario] = vtm.comentario
FROM 
	ew_ven_transacciones_mov AS vtm 
WHERE 
	vtm.idtran IN (
		SELECT ctr.idtran2
		FROM ew_cxc_transacciones_rel AS ctr 
		WHERE ctr.idtran = @idtran
	)
	
INSERT INTO ew_ven_transacciones_mov (
	idtran
	, consecutivo
	, idarticulo
	, idum
	, idalmacen
	, tipo
	, cantidad_autorizada
	, cantidad_surtida
	, cantidad_facturada
	, precio_unitario
	, idimpuesto1
	, idimpuesto2
	, importe
	, comentario
)
SELECT
	[idtran] = @idtran
	, [consecutivo] = ISNULL((SELECT MAX(vtm.consecutivo) FROM ew_ven_transacciones_mov AS vtm WHERE vtm.idtran = @idtran), 0) + 1
	, [idarticulo] = a.idarticulo
	, [idum] = a.idum_venta
	, [idalmacen] = vt.idalmacen
	, [tipo] = 1
	, [cantidad_autorizada] = 1
	, [cantidad_surtida] = 1
	, [cantidad_facturada] = 1
	, [precio_unitario] = SUM(t.redondeo)
	, [idimpuesto1] = 1
	, [idimpuesto2] = 11
	, [importe] = SUM(t.redondeo)
	, [comentario] = 'AJUSTE POR REDONDEO'
FROM
	ew_cxc_transacciones_rel AS ctr
	LEFT JOIN ew_articulos AS a
		ON a.codigo = 'EWREDONDEO'
	LEFT JOIN ew_ven_transacciones AS vt
		ON vt.idtran = @idtran
	LEFT JOIN ew_cxc_transacciones AS t
		ON t.idtran = ctr.idtran2
WHERE
	a.idarticulo IS NOT NULL
	AND ctr.idtran = @idtran
GROUP BY
	a.idarticulo
	, a.idum_venta
	, vt.idalmacen
HAVING
	SUM(t.redondeo) <> 0
	
SELECT
	@fecha = ct.fecha
FROM
	ew_cxc_transacciones AS ct
WHERE
	ct.idtran = @idtran

EXEC [dbo].[_cxc_prc_desaplicarTransaccion] @idtran, @idu

EXEC [dbo].[_ven_prc_facturaProcesarImpuestos] @idtran

UPDATE vt SET
	vt.subtotal = ISNULL((SELECT SUM(vtm.importe) FROM ew_ven_transacciones_mov AS vtm WHERE vtm.idtran = vt.idtran), 0)
	, vt.impuesto1 = ISNULL((SELECT SUM(vtm.impuesto1) FROM ew_ven_transacciones_mov AS vtm WHERE vtm.idtran = vt.idtran), 0)
	, vt.impuesto2 = ISNULL((SELECT SUM(vtm.impuesto2) FROM ew_ven_transacciones_mov AS vtm WHERE vtm.idtran = vt.idtran), 0)
FROM
	ew_ven_transacciones AS vt
WHERE
	vt.idtran = @idtran

UPDATE ct SET
	ct.subtotal = vt.subtotal
	, ct.impuesto1 = vt.impuesto1
	, ct.impuesto2 = vt.impuesto2
	, ct.saldo = vt.total
	/*
	, ct.cfd_iduso = ISNULL((
		SELECT TOP 1
			tv.cfd_iduso
		FROM
			ew_cxc_transacciones_rel AS ctrel
			LEFT JOIN ew_cxc_transacciones AS tv
				ON tv.idtran = ctrel.idtran2
		WHERE
			ctrel.idtran = ct.idtran
		ORDER BY
			tv.total DESC
	), c.cfd_iduso)
	*/
	, ct.idmetodo = ISNULL((
		SELECT TOP 1
			(
				CASE 
					WHEN tv.credito = 0 THEN 1 
					ELSE 2 
				END
			)
		FROM
			ew_cxc_transacciones_rel AS ctrel
			LEFT JOIN ew_cxc_transacciones AS tv
				ON tv.idtran = ctrel.idtran2
		WHERE
			ctrel.idtran = ct.idtran
		ORDER BY
			tv.total DESC
	), (
		CASE
			WHEN ctr.credito = 0 THEN 1
			ELSE 2
		END
	))
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_ven_transacciones AS vt
		ON vt.idtran = ct.idtran
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = ct.idcliente
	LEFT JOIN ew_clientes_terminos AS ctr
		ON ctr.idcliente = c.idcliente
WHERE
	ct.idtran = @idtran
	
UPDATE ct SET
	ct.saldo = (
		ct.total 
		- ISNULL((
			SELECT SUM(t.total/* - t.redondeo*/) 
			FROM 
				ew_cxc_transacciones_rel AS ctr 
				LEFT JOIN ew_cxc_transacciones AS t
					ON t.idtran = ctr.idtran2
			WHERE 
				ctr.idtran = ct.idtran
		), 0)
		+ ISNULL((
			SELECT SUM(ctr.saldo) 
			FROM 
				ew_cxc_transacciones_rel AS ctr 
			WHERE 
				ctr.idtran = ct.idtran
		), 0)
	)
FROM
	ew_cxc_transacciones As ct
WHERE
	ct.idtran = @idtran

EXEC [dbo].[_cxc_prc_aplicarTransaccion] @idtran, @fecha, @idu

SELECT
	@total_documento = ct.total -- - ct.redondeo
FROM
	ew_cxc_transacciones AS ct
WHERE
	ct.idtran = @idtran

SELECT
	@total_detalle = SUM(vt.total)
FROM
	ew_ven_transacciones_mov AS vt
WHERE
	vt.idtran = @idtran

SELECT @total_detalle = ISNULL(@total_detalle, 0)

IF ABS(@total_documento - @total_detalle) > 0.10
BEGIN
	SELECT @error_mensaje = (
		'Error: El total del detalle [' 
		+ CONVERT(VARCHAR(20), @total_detalle) 
		+ '] no coincide con el total del documento [' 
		+ CONVERT(VARCHAR(20), @total_documento) 
		+ '].'
	)

	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

EXEC [dbo].[_ven_prc_existenciaComprometer]

INSERT INTO ew_sys_transacciones2 (
	idtran
	, idestado
	, idu
)
SELECT
	[idtran] = idtran2
	, [idestado] = 51
	, [idu] = @idu
FROM
	ew_cxc_transacciones_rel
WHERE
	idtran = @idtran

EXEC [dbo].[_cxc_prc_ticketSaldoTrasladarFactura] @idtran
GO
