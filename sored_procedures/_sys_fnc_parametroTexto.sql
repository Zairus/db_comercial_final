USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091209
-- Description:	Funci�n que regresa el valor alfanum�rico de un par�metro
-- =============================================
ALTER FUNCTION [dbo].[_sys_fnc_parametroTexto]
(
	@codigo AS VARCHAR(20)
)
RETURNS VARCHAR(500)
AS
BEGIN
	DECLARE 
		@texto AS VARCHAR(500)
	
	SELECT
		@texto = valor
	FROM ew_sys_parametros
	WHERE
		codigo = @codigo
	
	RETURN ISNULL(@texto, '')
END
GO
