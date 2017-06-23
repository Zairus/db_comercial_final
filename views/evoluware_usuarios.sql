USE db_comercial_final
GO
ALTER VIEW [dbo].[evoluware_usuarios]
AS
SELECT
	idr
	, idu
	, usuario
	, nombre
	, [password]
	, idrol
	, sucursales
	, capturafecha
	, email
	, parametros
	, idcuenta
	, idcuenta_ventas
	, activo
	, turnos
FROM
	dbo.ew_cat_usuarios
GO
