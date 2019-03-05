USE db_comercial_final
GO
IF OBJECT_ID('_sys_fnc_fechaLarga') IS NOT NULL
BEGIN
	DROP FUNCTION [dbo].[_sys_fnc_fechaLarga]
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190222
-- Description:	Regresa cadena con fecha larga a partir de fecha
-- =============================================
CREATE FUNCTION [dbo].[_sys_fnc_fechaLarga]
(
	@fecha AS DATETIME
)
RETURNS VARCHAR(50)
AS
BEGIN
	DECLARE
		@tfecha AS VARCHAR(50)

	SELECT
		@tfecha = (
			[dbo].[_sys_fnc_rellenar](DAY(@fecha), 2, '0')
			+ ' de '
			+ pd.descripcion
			+ ' de '
			+ [dbo].[_sys_fnc_rellenar](YEAR(@fecha), 4, '0')
		)
	FROM
		ew_sys_periodos_datos AS pd
	WHERE
		pd.grupo = 'meses'
		AND pd.id = MONTH(@fecha)

	RETURN @tfecha
END
GO
