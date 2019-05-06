USE db_comercial_final
GO
IF OBJECT_ID('ew_ban_transacciones_cuentas_formas') IS NOT NULL
BEGIN
	DROP VIEW ew_ban_transacciones_cuentas_formas
END
GO
CREATE VIEW ew_ban_transacciones_cuentas_formas
AS
SELECT DISTINCT
	[FormaNombre] = ISNULL(bf.nombre, '-No Definido-')
	, [FormaCodigo] = ISNULL(bf.codigo, '99')
	, [Id] = ct.idforma
	, ct.idcuenta
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_ban_formas AS bf
		ON bf.idforma = ct.idforma
GO
