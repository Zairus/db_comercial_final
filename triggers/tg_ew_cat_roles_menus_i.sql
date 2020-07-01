USE db_comercial_final
GO
IF OBJECT_ID('tg_ew_cat_roles_menus_i') IS NOT NULL
BEGIN
	DROP TRIGGER tg_ew_cat_roles_menus_i
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200401
-- Description:	Validar no existan duplicados en permisos de rol
-- =============================================
CREATE TRIGGER [dbo].[tg_ew_cat_roles_menus_i]
	ON [dbo].[ew_cat_roles_menus]
	FOR INSERT
AS 

SET NOCOUNT ON

DECLARE
	@error_mensaje AS VARCHAR(5000)
	
SELECT
	@error_mensaje = (
		+ 'Los siguientes permisos estan dplicados: '
		+ (
			SELECT
				'Rol: ' + cr.nombre + ': Codigo: ' + crm.codigo + ', '
			FROM 
				ew_cat_roles_menus AS crm
				LEFT JOIN ew_cat_roles AS cr
					ON cr.idrol = crm.idrol
			WHERE
				(
					SELECT COUNT(*) 
					FROM 
						ew_cat_roles_menus AS crm1 
					WHERE 
						crm1.codigo = crm.codigo
						AND crm1.idrol = crm.idrol
				) > 1
			FOR XML PATH('')
		)
	)

IF @error_mensaje IS NOT NULL
BEGIN
	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END
GO
