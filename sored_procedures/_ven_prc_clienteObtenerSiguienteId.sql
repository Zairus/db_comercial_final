USE db_comercial_final
GO
IF OBJECT_ID('_ven_prc_clienteObtenerSiguienteId') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_prc_clienteObtenerSiguienteId
END
GO
CREATE PROCEDURE [dbo].[_ven_prc_clienteObtenerSiguienteId]
	@idcliente AS INT OUTPUT
	, @codcliente AS VARCHAR(30) OUTPUT
AS

SET NOCOUNT ON

DECLARE
	@existe AS BIT = 1
	, @cont AS INT = 0

SELECT 
	@idcliente = MAX(idcliente)
FROM 
	ew_clientes

SELECT @idcliente = ISNULL(@idcliente, 0) + 1

WHILE @existe = 1
BEGIN
	SELECT @codcliente = 'C' + [dbo].[_sys_fnc_rellenar](@idcliente + @cont, 4, '0')

	IF EXISTS(SELECT * FROM ew_clientes WHERE codigo = @codcliente)
	BEGIN
		SELECT @cont = @cont + 1
	END
		ELSE
	BEGIN
		SELECT @existe = 0
	END
END
GO
