USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180523
-- Description:	Regresa arbol a partir de cuenta indicada hasta raiz
-- =============================================
ALTER FUNCTION [dbo].[_ct_fnc_arbol] (
	@cuenta VARCHAR(20)
)
RETURNS @cuenta_arbol TABLE (
	id INT IDENTITY
	, cuenta VARCHAR(20)
)
AS
BEGIN
	DECLARE
		@cuentasup AS VARCHAR(20)
	
	SELECT @cuentasup = ''
	
	INSERT INTO @cuenta_arbol
		(cuenta) 
	VALUES
		(@cuenta)
	
	SELECT 
		@cuentasup = cuentasup
	FROM 
		ew_ct_cuentas
	WHERE 
		cuenta = @cuenta
	
	WHILE LEN(@cuentasup) > 0
	BEGIN
		INSERT INTO @cuenta_arbol
			(cuenta) 
		VALUES
			(@cuentasup)
		
		SELECT @cuenta = @cuentasup
		
		SELECT 
			@cuentasup = RTRIM(cuentasup) 
		FROM 
			ew_ct_cuentas 
		WHERE 
			cuenta = @cuenta
	END
	
	RETURN
END
GO
