USE db_comercial_final
GO
IF OBJECT_ID('ew_ban_bancos_datos') IS NOT NULL
BEGIN
	DROP VIEW ew_ban_bancos_datos
END
GO
CREATE VIEW ew_ban_bancos_datos
AS
SELECT
	[idbanco] = bb.idbanco
	, [nombre] = bb.nombre
	, [rfc] = bb.rfc
	, [cuentas] = (SELECT COUNT(*) FROM ew_ban_cuentas AS bc WHERE bc.idbanco = bb.idbanco)
FROM
	ew_ban_bancos AS bb
GO
