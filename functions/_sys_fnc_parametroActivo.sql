USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091107
-- Description:	Obtener valor falso o verdadero de parámetro.
-- =============================================
ALTER FUNCTION [dbo].[_sys_fnc_parametroActivo]
(
	@codigo AS VARCHAR(50)
)
RETURNS BIT
AS
BEGIN
	DECLARE 
		@activo AS BIT

	SELECT
		@activo = [activo]
	FROM ew_sys_parametros
	WHERE
		codigo = @codigo
	
	RETURN ISNULL(@activo, 0)
END
GO