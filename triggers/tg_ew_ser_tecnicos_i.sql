USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190312
-- Description:	Validar insertar tecnico
-- =============================================
ALTER TRIGGER [dbo].[tg_ew_ser_tecnicos_i]
	ON [dbo].[ew_ser_tecnicos]
	FOR INSERT, UPDATE
AS 

SET NOCOUNT ON

IF EXISTS(
	SELECT * 
	FROM inserted AS i
	WHERE i.idu NOT IN (
		SELECT u.idu 
		FROM evoluware_usuarios AS u
	)
)
BEGIN
	RAISERROR('Error: Debe existir un usuario para registro de operador/tecnico.', 16, 1)
	RETURN
END
GO
