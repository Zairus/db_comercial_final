USE db_comercial_final
GO
IF OBJECT_ID('ew_ban_cuentas_informacion') IS NOT NULL
BEGIN
	DROP VIEW ew_ban_cuentas_informacion
END
GO
CREATE VIEW ew_ban_cuentas_informacion
AS
SELECT
	[idcuenta] = bc.idcuenta
	, [cuenta] = bc.no_cuenta + ' - ' + bb.nombre
	, [cuenta_clabe] = ISNULL(NULLIF(bc.clabe, ''), bc.no_cuenta) + ' - ' + bb.nombre
	, [activo] = bc.activo
	, [idsucursal] = bc.idsucursal
	, [sucursal] = ISNULL(s.nombre, '-Todas-')
	, [idbanco] = bc.idbanco
	, [banco] = bb.nombre
	, [plaza] = bc.plaza
	, [no_cuenta] = bc.no_cuenta
	, [clabe] = bc.clabe
	, [idtipocuenta] = bc.tipo
	, [tipo] = bct.nombre
	, [idmoneda] = bc.idmoneda
	, [moneda] = bm.nombre
	, [saldo_inicial] = bc.saldo_inicial
	, [saldo_minimo] = bc.saldo_minimo
	, [saldo_actual] = bc.saldo_actual
	, [contabilidad] = bc.contabilidad1
	, [contabilidad_nombre] = cc.nombre
FROM 
	ew_ban_cuentas AS bc
	LEFT JOIN ew_ban_bancos AS bb
		ON bb.idbanco = bc.idbanco
	LEFT JOIN ew_ban_cuentas_tipos AS bct
		ON bct.idtipocuenta = bc.tipo
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = bc.idsucursal
	LEFT JOIN ew_ban_monedas AS bm
		ON bm.idmoneda = bc.idmoneda
	LEFT JOIN ew_ct_cuentas AS cc
		ON cc.cuenta = bc.contabilidad1
GO
SELECT * FROM ew_ban_cuentas_informacion
