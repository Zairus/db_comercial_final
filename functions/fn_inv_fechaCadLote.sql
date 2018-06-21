USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180620
-- Description:	Fecha de caducidad por lote
-- =============================================
ALTER FUNCTION fn_inv_fechaCadLote
(
	@lote AS VARCHAR(50)
)
RETURNS DATETIME
AS
BEGIN
	DECLARE
		@fecha_caducidad AS DATETIME

	SELECT
		@fecha_caducidad = MAX(ic.fecha_caducidad)
	FROM
		ew_inv_capas AS ic
	WHERE
		ic.fecha_caducidad IS NOT NULL
		AND ic.lote = @lote
		AND LEN(@lote) > 0

	RETURN @fecha_caducidad
END
GO

