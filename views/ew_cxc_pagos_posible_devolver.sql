USE db_comercial_final
GO
IF OBJECT_ID('ew_cxc_pagos_posible_devolver') IS NOT NULL
BEGIN
	DROP VIEW ew_cxc_pagos_posible_devolver
END
GO
CREATE VIEW [dbo].[ew_cxc_pagos_posible_devolver]
AS
SELECT
	[idtran] = p.idtran
	, [fecha] = CONVERT(VARCHAR(10), p.fecha, 103)
	, [folio] = p.folio
	, [cliente] = c.nombre
	, [idcliente] = p.idcliente
	, [cuenta] = bc.cuenta
	, [devoluciones] = ISNULL((
		SELECT
			'F:' + f.folio + ' DEV:' + dev.folio + ' '
		FROM
			ew_cxc_transacciones_mov AS pm
			LEFT JOIN ew_cxc_transacciones AS f
				ON f.idtran = pm.idtran2
			LEFT JOIN ew_cxc_transacciones AS dev
				ON dev.cancelado = 0
				AND dev.tipo = 2
				AND dev.idtran2 = f.idtran
				AND dev.transaccion LIKE 'EDE%'
		WHERE
			pm.idtran = p.idtran
			AND dev.idtran IS NOT NULL
		FOR XML PATH('')
	), '')
	, [total] = p.total
FROM 
	ew_cxc_transacciones AS p
	LEFT JOIN ew_ban_transacciones AS bt
		ON bt.idtran = p.idtran
	LEFT JOIN ew_ban_cuentas_informacion AS bc
		ON bc.idcuenta = bt.idcuenta
	LEFT JOIN vew_clientes AS c
		ON c.idcliente = p.idcliente
WHERE
	p.cancelado = 0
	AND p.transaccion = 'BDC2'
	AND (
		SELECT COUNT(*) 
		FROM 
			ew_ban_transacciones_mov AS devm
			LEFT JOIN ew_ban_transacciones AS dev
				ON dev.idtran = devm.idtran
		WHERE 
			devm.idmov2 = p.idmov
			AND dev.cancelado = 0
	) = 0
	AND (
		(
			SELECT COUNT(*)
			FROM
				ew_cxc_transacciones_mov AS pm
				LEFT JOIN ew_cxc_transacciones AS f
					ON f.idtran = pm.idtran2
				LEFT JOIN ew_cxc_transacciones AS dev
					ON dev.cancelado = 0
					AND dev.tipo = 2
					AND dev.idtran2 = f.idtran
					AND dev.transaccion LIKE 'EDE%'
			WHERE
				pm.idtran = p.idtran
				AND dev.idtran IS NOT NULL
		) > 0
		OR (
			SELECT COUNT(*)
			FROM
				ew_cxc_transacciones_mov AS pm
			WHERE
				pm.idtran = p.idtran
		) = 0
	)
GO
