USE db_comercial_final
GO
IF OBJECT_ID('_sys_fnc_cadenaReemplazarMultiple') IS NOT NULL
BEGIN
	DROP FUNCTION _sys_fnc_cadenaReemplazarMultiple
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190611
-- Description:	Regresa cadeba reemplazando ocurrencias 
-- de str_code por str_value en una tabla del tipo 
-- EWValueReplacementType (str_code VARCHAR(500), str_value VARCHAR(500))
-- =============================================
CREATE FUNCTION [dbo].[_sys_fnc_cadenaReemplazarMultiple] (
	@cadena AS VARCHAR(MAX)
	, @tabla_valores AS EWValueReplacementType READONLY
)
RETURNS VARCHAR(MAX)
AS
BEGIN
	SELECT
		@cadena = REPLACE(@cadena, tv.str_code, tv.str_value)
	FROM
		@tabla_valores AS tv

	RETURN @cadena
END
GO
