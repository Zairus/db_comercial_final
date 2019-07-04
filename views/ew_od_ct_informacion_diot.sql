USE db_comercial_final
GO
IF OBJECT_ID('ew_od_ct_informacion_diot') IS NOT NULL
BEGIN
	DROP VIEW ew_od_ct_informacion_diot
END
GO
CREATE VIEW ew_od_ct_informacion_diot
AS
SELECT
	[idtran] = ct.idtran
	, [ejercicio] = YEAR(ct.fecha)
	, [periodo] = MONTH(ct.fecha)
	, [transaccion] = ct.transaccion
	, [transaccion_nombre] = o.nombre
	, [importe] = ct.subtotal
	, [total] = ct.total
	, [saldo] = ct.saldo
	, [iva_porcentaje] = ROUND(ct.impuesto1 / ct.subtotal, 2)
	, [proporcion_pago] = IIF(ABS(ct.total) > 0, (ct.saldo / ct.total), 0)
	, [proporcion_pagado] = (1.00 - IIF(ABS(ct.total) > 0, (ct.saldo / ct.total), 0))

	, [tipo_tercero] = ISNULL(pcd.codigo, '04')
	, [tipo_operacion] = '85'
	, [rfc] = IIF(p.extranjero = 0, (REPLACE(REPLACE(p.rfc, '-', ''), ' ', '')), '')
	, [campo_id] = IIF(p.extranjero = 1, (REPLACE(REPLACE(p.rfc, '-', ''), ' ', '')), '')
	, [nombre_extranjero] = IIF(p.extranjero = 1, p.nombre, '')
	, [pais_residencia] = ISNULL(IIF(p.extranjero = 1, csp.descripcion, ''), '')
	, [nacionalidad] = ISNULL(IIF(p.extranjero = 1, csp.descripcion, ''), '')
	, [valor_actos_16] = (IIF(ROUND(ct.impuesto1 / ct.subtotal, 2) BETWEEN 0.13 AND 0.17, ct.subtotal, 0) * (1.00 - IIF(ABS(ct.total) > 0, (ct.saldo / ct.total), 0)) * IIF(ct.tipo = 1, 1, 0)) * ct.tipocambio
	, [valor_actos_15] = (IIF(ROUND(ct.impuesto1 / ct.subtotal, 2) = 0.15, ct.subtotal, 0) * (1.00 - IIF(ABS(ct.total) > 0, (ct.saldo / ct.total), 0)) * IIF(ct.tipo = 1, 1, 0)) * ct.tipocambio
	, [iva_no_acreditable_16] = 0
	, [valor_actos_11] = (IIF(ROUND(ct.impuesto1 / ct.subtotal, 2) BETWEEN 0.11 AND 0.12, ct.subtotal, 0) * (1.00 - IIF(ABS(ct.total) > 0, (ct.saldo / ct.total), 0)) * IIF(ct.tipo = 1, 1, 0)) * ct.tipocambio
	, [valor_actos_10] = (IIF(ROUND(ct.impuesto1 / ct.subtotal, 2) = 0.10, ct.subtotal, 0) * (1.00 - IIF(ABS(ct.total) > 0, (ct.saldo / ct.total), 0)) * IIF(ct.tipo = 1, 1, 0)) * ct.tipocambio
	, [valor_actos_8] = (IIF(ROUND(ct.impuesto1 / ct.subtotal, 2) = 0.08, ct.subtotal, 0) * (1.00 - IIF(ABS(ct.total) > 0, (ct.saldo / ct.total), 0)) * IIF(ct.tipo = 1, 1, 0)) * ct.tipocambio
	, [iva_no_acreditable_11] = 0
	, [iva_no_acreditable_8] = 0

	, [valor_actos_importacion_16] = (IIF(ct.idconcepto = 43, ct.subtotal, 0) * IIF(ct.tipo = 1, 1, 0)) * ct.tipocambio
	, [iva_no_acreditable_importacion_16] = 0
	, [valor_actos_importacion_11] = 0
	, [iva_no_acreditable_importacion_11] = 0
	, [valor_actos_importacion_0] = 0
	, [valor_actos_0] = (IIF(ct.impuesto1 = 0, ct.subtotal, 0) * IIF(ct.tipo = 1, 1, 0)) * ct.tipocambio
	, [valor_actos_E] = 0
	, [iva_retenido] = (ct.impuesto1_ret * (1.00 - IIF(ABS(ct.total) > 0, (ct.saldo / ct.total), 0)) * IIF(ct.tipo = 1, 1, 0)) * ct.tipocambio
	, [iva_devoluciones] = IIF(ct.tipo = 2 AND ct.transaccion NOT IN ('DDA3', 'DDA4'), ct.impuesto1, 0) * ct.tipocambio
FROM
	ew_cxp_transacciones AS ct
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
	LEFT JOIN ew_proveedores AS p
		ON p.idproveedor = ct.idproveedor
	LEFT JOIN ew_sys_clasificacion AS pcd
		ON pcd.idclasificacion = p.idclasificacion_diot
	LEFT JOIN ew_sys_ciudades AS cd
		ON cd.idciudad = p.idciudad
	LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_pais AS csp
		ON csp.c_pais = cd.c_pais
WHERE
	ct.tipo IN (1,2)
	AND ct.cancelado = 0
	AND ct.transaccion NOT IN ('DDA3', 'DDA4')
	AND ct.subtotal > 0
GO
