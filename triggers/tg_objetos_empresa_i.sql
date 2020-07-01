USE db_comercial_final
GO
IF OBJECT_ID('tg_objetos_empresa_i') IS NOT NULL
BEGIN
	DROP TRIGGER tg_objetos_empresa_i
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091014
-- Description:	Inserta linea en blanco en 
--              permisos de rol por el objeto 
--              agregado, solo para roles de 
--              tipo Pesimista
-- =============================================
CREATE TRIGGER [dbo].[tg_objetos_empresa_i]
	ON [dbo].[ew_sys_objetos_empresa]
	FOR INSERT
AS 

SET NOCOUNT ON

DECLARE 
	@objeto AS INT
	, @tipo AS VARCHAR(3)
	, @codigo AS VARCHAR(10)

SELECT 
	@objeto = objeto 
FROM 
	inserted

SELECT 
	@tipo = tipo
	, @codigo = codigo 
FROM 
	objetos 
WHERE 
	objeto = @objeto

INSERT INTO ew_cat_roles_menus (
	idrol
	, tipo
	, codigo
	, activo
	, consultar
	, nuevo
	, modificar
	, cancelar
	, imprimir
	, exportar
	, acciones
	, autorizar
	, variable
	, referencia
)
SELECT
	[idrol] = s.idrol
	, [tipo] = @tipo
	, [codigo] = @codigo
	, [activo] = s.seguridad
	, [consultar] = s.seguridad
	, [nuevo] = s.seguridad
	, [modificar] = s.seguridad
	, [cancelar] = s.seguridad
	, [imprimir] = s.seguridad
	, [exportar] = s.seguridad
	, [acciones] = s.seguridad
	, [autorizar] = s.seguridad
	, [variable] = ''
	, [referencia] = ''
FROM 
	inserted AS a
	LEFT JOIN ew_cat_roles AS s
		ON s.idrol = s.idrol
WHERE
	a.objeto = @objeto
	AND s.seguridad = 0
	AND (
		SELECT COUNT(*) 
		FROM 
			ew_cat_roles_menus 
		WHERE 
			idrol = s.idrol 
			AND codigo = @codigo
	) = 0
GO
