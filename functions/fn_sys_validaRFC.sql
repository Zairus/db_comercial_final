USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110428
-- Description:	Validar RFC
-- =============================================
ALTER FUNCTION [dbo].[fn_sys_validaRFC]
(
	@rfc AS VARCHAR(13)
)
RETURNS BIT
AS
BEGIN
	DECLARE
		@valido AS BIT
	
	DECLARE
		 @parte_letras AS VARCHAR(4)
		,@parte_fecha AS VARCHAR(6)
		,@parte_verif  AS VARCHAR(3)
	
	SELECT @valido = 1
	
	IF LEN(@rfc) NOT IN (12,13)
	BEGIN
		SELECT @valido = 0
	END
	
	IF LEN(@rfc) = 12
	BEGIN
		SELECT @parte_letras = LEFT(@rfc, 3)
		SELECT @parte_fecha = SUBSTRING(@rfc, 4, 6)
	END
	
	IF LEN(@rfc) = 13
	BEGIN
		SELECT @parte_letras = LEFT(@rfc, 4)
		SELECT @parte_fecha = SUBSTRING(@rfc, 5, 6)
	END
	
	SELECT @parte_verif = RIGHT(@rfc, 3)
	
	-- VALIDAR LETRAS
	IF PATINDEX('%[0-9]%',@parte_letras) > 0
	BEGIN
		SELECT @valido = 0
	END
	
	-- VALIDAR FECHA
	IF ISDATE(RIGHT(@parte_fecha, 2) + '/' + SUBSTRING(@parte_fecha, 3, 2) + '/' + LEFT(@parte_fecha, 2)) = 0
	BEGIN
		SELECT @valido = 0
	END
	
	-- VALIDAR DIGITO
	IF RIGHT(@parte_verif, 1) NOT IN ('1','2','3','4','5','6','7','8','9','0','A')
	BEGIN
		SELECT @valido = 0
	END
	
	RETURN @valido
END
GO
