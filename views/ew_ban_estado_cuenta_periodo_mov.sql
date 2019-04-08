USE db_comercial_final
GO
IF OBJECT_ID('ew_ban_estado_cuenta_periodo_mov') IS NOT NULL
BEGIN
	DROP VIEW ew_ban_estado_cuenta_periodo_mov
END
GO
CREATE VIEW ew_ban_estado_cuenta_periodo_mov
AS
SELECT
	[idr] = bec.idr
	, [idtran] = CONVERT(INT, (
		[dbo].[_sys_fnc_rellenar](YEAR(bec.fecha), 4, '0')
		+ [dbo].[_sys_fnc_rellenar](MONTH(bec.fecha), 2, '0')
		+ [dbo].[_sys_fnc_rellenar](bec.idcuenta, 3, '0')
	))
	, [idbanco] = bec.idbanco
	, [idcuenta] = bec.idcuenta
	, [fecha] = bec.fecha
	, [folio] = bec.folio
	, [concepto] = bec.concepto
	, [ingresos] = bec.ingresos
	, [egresos] = bec.egresos
	, [conciliado] = bec.conciliado
FROM 
	ew_ban_estado_cuenta AS bec
GO
SELECT * FROM ew_ban_estado_cuenta_periodo_mov ORDER BY idr
