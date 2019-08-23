USE db_comercial_final
GO
IF OBJECT_ID('_com_prc_proveedorContactoDatos') IS NOT NULL
BEGIN
	DROP PROCEDURE _com_prc_proveedorContactoDatos
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190820
-- Description:	Datos de contacto de proveedor
-- =============================================
CREATE PROCEDURE [dbo].[_com_prc_proveedorContactoDatos]
	@idproveedor AS INT
	, @idcontacto AS INT
AS

SET NOCOUNT ON

SELECT
	[idcontacto] = p.idcontacto
	, [contacto] = cc.nombre
	, [horario] = pc.horario
	, [contacto_telefono] = ISNULL((
		SELECT TOP 1
			ccc.dato1
		FROM ew_cat_contactos_contacto AS ccc
		WHERE
			ccc.idcontacto = cc.idcontacto
			AND ccc.tipo = 1
	), p.telefono1)
	, [contacto_email] = ISNULL((
		SELECT TOP 1
			ccc.dato1
		FROM ew_cat_contactos_contacto AS ccc
		WHERE
			ccc.idcontacto = cc.idcontacto
			AND ccc.tipo = 4
	), p.email)
FROM
	ew_proveedores AS p
	LEFT JOIN ew_proveedores_contactos AS pc 
		ON pc.idcontacto = @idcontacto
		AND pc.idproveedor = p.idproveedor 
	LEFT JOIN ew_cat_contactos AS cc 
		ON cc.idcontacto = pc.idcontacto
WHERE
	p.idproveedor = @idproveedor
GO
