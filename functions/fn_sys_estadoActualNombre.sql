USE db_comercial_final
GO
ALTER FUNCTION [dbo].[fn_sys_estadoActualNombre] (@idtran INT)
RETURNS VARCHAR(50)
AS
BEGIN
	DECLARE
		@nombre AS VARCHAR(50)
	
	SELECT
		@nombre = e.nombre
	FROM
		ew_sys_transacciones AS t
		LEFT JOIN estados AS e
			ON e.idestado = t.idestado
	WHERE
		t.idtran = @idtran

	SELECT @nombre = ISNULL(@nombre, '')

	RETURN(@nombre)
END
GO
