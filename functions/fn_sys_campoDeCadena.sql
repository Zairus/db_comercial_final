USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160123
-- Description:	Regresa un valor dependiendo de una posicion en una cadena delimitada
-- =============================================
ALTER FUNCTION [dbo].[fn_sys_campoDeCadena]
(
	@cadena AS VARCHAR(MAX)
	,@delimitador AS VARCHAR(4)
	,@posicion AS INT
)
RETURNS VARCHAR(MAX)
AS
BEGIN
	DECLARE
		@valor AS VARCHAR(MAX)

	SELECT
		@valor = valor
	FROM 
		dbo._sys_fnc_separarMultilinea(@cadena, @delimitador)
	WHERE
		idr = @posicion

	RETURN @valor
END
GO
