USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20181219
-- Description:	Regresa etiqueta de grupo por objeto
-- =============================================
ALTER FUNCTION [dbo].[_sys_fnc_objetoGrupoNombre]
(
	@idtran AS INT
)
RETURNS VARCHAR(100)
AS
BEGIN
	DECLARE
		@grupo_nombre AS VARCHAR(100)
		, @codigo AS VARCHAR(5)

	SELECT
		@codigo = st.transaccion
		, @grupo_nombre = o.nombre
	FROM
		ew_sys_transacciones AS st
		LEFT JOIN objetos AS o
			ON o.codigo = st.transaccion
	WHERE
		st.idtran = @idtran

	IF @codigo IN ('EFA1', 'EFA6')
	BEGIN
		SELECT @grupo_nombre = 'Factura de Venta'
	END

	IF @codigo IN ('EFA3')
	BEGIN
		SELECT @grupo_nombre = 'Nota de Venta'
	END

	IF @codigo IN ('EFA4', 'EFA7')
	BEGIN
		SELECT @grupo_nombre = 'Factura Fiscal'
	END

	RETURN @grupo_nombre
END
GO
