USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150713
-- Description:	Obtener turno actual para usuario
-- =============================================
ALTER FUNCTION [dbo].[fn_sys_turnoActualR2]
(
	@idu AS INT
	,@ultimo AS BIT
)
RETURNS INT
AS
BEGIN
	DECLARE @idturno AS INT

	SELECT TOP 1
		@idturno = idturno
	FROM
		ew_sys_turnos
	WHERE
		activo = 1
		AND fecha_fin IS NULL
		AND (
			(
				YEAR(fecha_inicio) = YEAR(GETDATE())
				AND MONTH(fecha_inicio) = MONTH(GETDATE())
				AND DAY(fecha_inicio) = DAY(GETDATE())
			)
			OR @ultimo = 1
		)
		AND idu = @idu
	ORDER BY
		fecha_inicio DESC

	RETURN @idturno
END
GO
