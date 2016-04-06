USE db_comercial_final
GO
ALTER VIEW [dbo].[vew_proveedores]
AS
SELECT
	idproveedor
	, [proveedor_codigo] = codigo
	, [proveedor_rfc] = rfc
	, [proveedor_cuenta] = contabilidad
	, [proveedor_nombre] = nombre
	, [proveedor_nombre_corto] = nombre_corto
	, activo
	, idmoneda
	, comentario
FROM
	dbo.ew_proveedores
WHERE
	dbo.ew_proveedores.activo = 1
GO
