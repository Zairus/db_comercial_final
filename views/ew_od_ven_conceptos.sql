USE db_comercial_final
GO
IF OBJECT_ID('ew_od_ven_conceptos') IS NOT NULL
BEGIN
	DROP VIEW ew_od_ven_conceptos
END
GO
CREATE VIEW ew_od_ven_conceptos
AS
SELECT
	[ven_idtran] = efa.idtran
	, [idsucursal] = efa.idsucursal
	, [transaccion] = efa.transaccion
	, [fecha] = efa.fecha
	, [ejercicio] = YEAR(efa.fecha)
	, [periodo] = MONTH(efa.fecha)

	, [factura_total] = efa.total
	, [factura_saldo] = cxc.saldo
	, [factura_proporcion_pago] = 1.00 - (cxc.saldo / efa.total)
	, [factura_idmoneda] = efa.idmoneda
	, [factura_tipocambio] = (CASE WHEN efa.idmoneda = 0 THEN 1 ELSE efa.tipocambio END)

	, [concepto_importe] = efad.importe * efa.tipocambio
	, [concepto_impuesto1_tasa] = COALESCE(NULLIF(efad.idimpuesto1_valor, 0), cxc.idimpuesto1_valor)
	, [concepto_impuesto1] = ISNULL(efad.impuesto1, cxc.impuesto1)
	, [concepto_impuesto2_tasa] = COALESCE(NULLIF(efad.idimpuesto2_valor, 0), cxc.idimpuesto2_valor)
	, [concepto_impuesto2] = ISNULL(efad.impuesto2, cxc.impuesto2)
	, [concepto_total] = (efad.total * efa.tipocambio)
FROM
	ew_ven_transacciones AS efa
	LEFT JOIN ew_cxc_transacciones AS cxc
		ON cxc.idtran = efa.idtran
	LEFT JOIN ew_ven_transacciones_mov AS efad
		ON efad.idtran = efa.idtran
WHERE
	efa.cancelado = 0
	AND efa.transaccion IN('EFA1', 'EFA6', 'EFA3')
GO
