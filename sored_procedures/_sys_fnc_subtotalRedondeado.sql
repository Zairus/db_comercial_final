USE db_comercial_final
GO
IF OBJECT_ID('_sys_fnc_subtotalRedondeado') IS NOT NULL
BEGIN
	DROP FUNCTION _sys_fnc_subtotalRedondeado
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190830
-- Description:	Calcula el subtotal a partir de un total e impuestos
-- =============================================
CREATE FUNCTION [dbo].[_sys_fnc_subtotalRedondeado]
(
	@valor AS DECIMAL(18,6)
	, @incremento AS DECIMAL(18, 6)
)
RETURNS DECIMAL(18, 6)
AS
BEGIN
	DECLARE
		@resultado AS DECIMAL(18, 6)

	SELECT @resultado = @valor / @incremento

	--SELECT @resultado = @valor - ROUND((@resultado * (@incremento - 1)), 2)

	RETURN @resultado
END
GO
