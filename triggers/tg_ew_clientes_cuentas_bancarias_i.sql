USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20171120
-- Description:	Validar informacion de cuentas bancarias de cliente
-- =============================================
ALTER TRIGGER [dbo].[tg_ew_clientes_cuentas_bancarias_i]
	ON [dbo].[ew_clientes_cuentas_bancarias]
	FOR INSERT
AS 

SET NOCOUNT ON

IF EXISTS(
	SELECT *
	FROM 
		inserted AS i
	WHERE
		LEN(i.clabe) <> 18
		OR ISNUMERIC(i.clabe) = 0
)
BEGIN
	RAISERROR('Error: La cuenta CLABE es incorrecta.', 16, 1)
	RETURN
END
GO
