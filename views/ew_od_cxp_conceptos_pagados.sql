USE db_comercial_final
GO
IF OBJECT_ID('ew_od_cxp_conceptos_pagados') IS NOT NULL
BEGIN
	DROP VIEW ew_od_cxp_conceptos_pagados
END
GO
CREATE VIEW [dbo].[ew_od_cxp_conceptos_pagados]
AS
SELECT
	[cxp_idtran] = f.idtran
	, [idsucursal] = f.idsucursal
	, [transaccion] = f.transaccion
	, [fecha] = f.fecha
	, [ejercicio] = YEAR(f.fecha)
	, [periodo] = MONTH(f.fecha)

	, [factura_folio] = f.folio
	, [factura_total] = f.total
	, [factura_saldo] = f.saldo
	, [factura_proporcion_pago] = (
		CASE
			WHEN f.total = 0 THEN 1.00
			ELSE 1.00 - (f.saldo / f.total)
		END
	)
	, [factura_idmoneda] = f.idmoneda
	, [factura_tipocambio] = f.tipocambio

	, [concepto_id] = ISNULL(fd.idr, f.idr)
	, [concepto_importe] = ISNULL(fd.importe, f.subtotal) * (CASE WHEN f.idmoneda = 0 THEN 1 ELSE f.tipocambio END)
	, [concepto_impuesto1_tasa] = ISNULL(NULLIF(fd.idimpuesto1_valor, 0), f.idimpuesto1_valor)
	, [concepto_impuesto1] = ISNULL(fd.impuesto1, f.impuesto1) * (CASE WHEN f.idmoneda = 0 THEN 1 ELSE f.tipocambio END)
	, [concepto_impuesto2_tasa] = ISNULL(NULLIF(fd.idimpuesto2_valor, 0), f.idimpuesto2_valor)
	, [concepto_impuesto2] = ISNULL(fd.impuesto2, f.impuesto2) * (CASE WHEN f.idmoneda = 0 THEN 1 ELSE f.tipocambio END)
	, [concepto_total] = ISNULL(fd.total, f.total) * (CASE WHEN f.idmoneda = 0 THEN 1 ELSE f.tipocambio END)

	, [tipo] = (
		CASE LEFT(f.transaccion, 3) 
			WHEN 'CFA' THEN 'Compra' 
			WHEN 'AFA' THEN 'Gasto' 
			ELSE 'Otro' 
		END
	)
FROM
	ew_cxp_transacciones AS f
	LEFT JOIN ew_com_transacciones_mov AS fd
		ON fd.idtran = f.idtran
WHERE
	f.tipo = 1
	AND f.cancelado = 0
GO
