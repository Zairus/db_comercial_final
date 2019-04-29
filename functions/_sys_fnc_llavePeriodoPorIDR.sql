USE db_comercial_final
GO
IF OBJECT_ID('_sys_fnc_llavePeriodoPorIDR') IS NOT NULL
BEGIN
	DROP FUNCTION _sys_fnc_llavePeriodoPorIDR
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190417
-- Description:	Obtiene llave EJERCICIO+IDMODULO por idr de periodo
-- =============================================
CREATE FUNCTION _sys_fnc_llavePeriodoPorIDR
(
	@idr AS INT
)
RETURNS VARCHAR(6)
AS
BEGIN
	DECLARE
		@llave AS VARCHAR(6)

	SELECT
		@llave = (
			dbo._sys_fnc_rellenar(sp.ejercicio, 4, '0')
			+ dbo._sys_fnc_rellenar(sp.idmodulo, 2, '0')
		)
	FROM
		ew_sys_periodos AS sp
	WHERE
		sp.idr = @idr

	SELECT @llave = ISNULL(@llave, '')

	RETURN @llave
END
GO
