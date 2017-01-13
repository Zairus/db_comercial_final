USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091209
-- Description:	Función que regresa el valor alfanumérico de un parámetro
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
