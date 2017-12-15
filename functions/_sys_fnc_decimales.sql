USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20171207
-- Description:	Regresa un valor con los decimales especificados
-- =============================================
ALTER FUNCTION _sys_fnc_decimales
(
	@numero AS DECIMAL(18, 6)
	,@decimales AS INT
)
RETURNS VARCHAR(50)
AS
BEGIN
	DECLARE
		@valor AS VARCHAR(50)

	SELECT @decimales = ISNULL(@decimales, 6)

	SELECT @valor = LTRIM(RTRIM(STR(@numero, 20, @decimales)))

	RETURN @valor
END
GO

