USE db_comercial_final
GO
ALTER FUNCTION [dbo].[fn_sys_estadoActualNombre] (
	@idtran INT
)
RETURNS VARCHAR(50)
AS
BEGIN
	DECLARE
		@nombre AS VARCHAR(50)
	
	SELECT
		@nombre = e.nombre
	FROM
		ew_sys_transacciones AS t
		LEFT JOIN objetos AS o
			ON o.codigo = t.transaccion
		LEFT JOIN objetos_estados AS e
			ON e.idestado = t.idestado
			AND e.objeto = o.objeto
	WHERE
		t.idtran = @idtran

	SELECT @nombre = ISNULL(@nombre, '')

	RETURN(@nombre)
END
GO
