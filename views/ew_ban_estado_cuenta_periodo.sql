USE db_comercial_final
GO
IF OBJECT_ID('ew_ban_estado_cuenta_periodo') IS NOT NULL
BEGIN
	DROP VIEW ew_ban_estado_cuenta_periodo
END
GO
CREATE VIEW ew_ban_estado_cuenta_periodo
AS
SELECT DISTINCT
	[idr] = DENSE_RANK() OVER (
		ORDER BY 
			CONVERT(INT, (
				[dbo].[_sys_fnc_rellenar](YEAR(bec.fecha), 4, '0')
				+ [dbo].[_sys_fnc_rellenar](MONTH(bec.fecha), 2, '0')
				+ [dbo].[_sys_fnc_rellenar](bec.idcuenta, 3, '0')
			))
			, bec.idbanco
			, bec.idcuenta
	)
	, [idtran] = CONVERT(INT, (
		[dbo].[_sys_fnc_rellenar](YEAR(bec.fecha), 4, '0')
		+ [dbo].[_sys_fnc_rellenar](MONTH(bec.fecha), 2, '0')
		+ [dbo].[_sys_fnc_rellenar](bec.idcuenta, 3, '0')
	))
	, [transaccion] = 'BPR4'
	, [idbanco] = bec.idbanco
	, [banco] = bb.nombre
	, [idcuenta] = bec.idcuenta
	, [cuenta] = bc.no_cuenta
	, [periodo] = MONTH(bec.fecha)
	, [ejercicio] = YEAR(bec.fecha)
FROM
	ew_ban_estado_cuenta AS bec
	LEFT JOIN ew_ban_bancos AS bb
		ON bb.idbanco = bec.idbanco
	LEFT JOIN ew_ban_cuentas AS bc
		ON bc.idcuenta = bec.idcuenta
GO
SELECT * FROM ew_ban_estado_cuenta_periodo ORDER BY idr
