USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160117
-- Description:	Calcular margen
-- =============================================
ALTER FUNCTION [dbo].[fn_sys_calcularMargen]
(
	@precio AS DECIMAL(18,6)
	,@costo AS DECIMAL(18,6)
)
RETURNS DECIMAL(18,6)
AS
BEGIN
	DECLARE
		@margen AS DECIMAL(18,6)
		,@utilidad AS DECIMAL(18,6)

	IF @costo > 0
	BEGIN
		SELECT @utilidad = @precio - @costo
		SELECT @margen = @utilidad / @costo
	END

	SELECT @margen = ISNULL(@margen, 0)

	IF @margen < 0
		SELECT @margen = 0

	RETURN @margen
END
GO
