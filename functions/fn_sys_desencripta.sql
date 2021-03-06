USE db_comercial_final
GO
ALTER FUNCTION [dbo].[fn_sys_desencripta] (@binario VARBINARY(256), @contraseņa VARCHAR(20))
RETURNS VARCHAR(256)
BEGIN
	DECLARE @return	VARCHAR(256)

	SELECT @return = CONVERT(VARCHAR(256), DecryptByPassPhrase(@contraseņa, @binario))

	SELECT @return = REPLACE(@return, '^', '^^')
	SELECT @return = REPLACE(@return, '&', '^&')
	
	RETURN (@return)
END
GO
