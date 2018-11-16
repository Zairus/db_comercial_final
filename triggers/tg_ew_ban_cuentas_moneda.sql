USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20181102
-- Description:	Validar cambio de moneda en cuenta
-- =============================================
ALTER TRIGGER tg_ew_ban_cuentas_moneda
	ON ew_ban_cuentas
	FOR UPDATE
AS 

SET NOCOUNT ON

DECLARE
	@idmoneda_old AS INT
	, @idmoneda_new AS INT
	, @idcuenta AS INT

SELECT
	@idmoneda_old = idmoneda
FROM
	deleted

SELECT
	@idmoneda_new = idmoneda
	, @idcuenta = idcuenta
FROM
	inserted

IF 
	@idmoneda_old <> @idmoneda_new
	AND EXISTS(SELECT * FROM ew_ban_transacciones WHERE cancelado = 0 AND idcuenta = @idcuenta)
BEGIN
	RAISERROR('Error: No se permite cambiar de moneda cuando hay movimietos.', 16, 1)
	RETURN
END
GO

