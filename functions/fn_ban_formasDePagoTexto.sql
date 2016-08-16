USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160720
-- Description:	Obtener cadena con formas de pago
-- =============================================
ALTER FUNCTION [dbo].[fn_ban_formasDePagoTexto]
(
	@formas AS VARCHAR(100)
)
RETURNS VARCHAR(200)
AS
BEGIN
	DECLARE
		@formas_concat AS VARCHAR(200) = ''

	SELECT
		@formas_concat = (
			@formas_concat
			+ (CASE WHEN (ROW_NUMBER() OVER(ORDER BY bf.idforma)) = 1 THEN '' ELSE ', ' END)
			+ '[' + bf.codigo + '] ' + bf.nombre
		)
	FROM 
		ew_ban_formas AS bf
	WHERE
		bf.codigo IN (
			SELECT
				[valor]
			FROM 
				dbo._sys_fnc_separarMultilinea(@formas, ',')
		)

	IF @formas_concat = ''
		SELECT @formas_concat = NULL

	RETURN @formas_concat
END
GO
