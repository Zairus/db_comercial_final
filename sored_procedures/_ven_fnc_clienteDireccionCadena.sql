USE db_comercial_final
GO
IF OBJECT_ID('_ven_fnc_clienteDireccionCadena') IS NOT NULL
BEGIN
	DROP FUNCTION _ven_fnc_clienteDireccionCadena
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200319
-- Description:	Cadena con direccion de cliente a partir de id facturacion
-- =============================================
CREATE FUNCTION [dbo].[_ven_fnc_clienteDireccionCadena]
(
	@idcliente AS INT
	, @idfacturacion AS INT
)
RETURNS VARCHAR(MAX)
AS
BEGIN
	DECLARE
		@direccion AS VARCHAR(MAX)

	SELECT
		@direccion = [dbo].[_sys_fnc_direccionCadena](
			cfa.calle
			, cfa.noExterior
			, cfa.noInterior
			, cfa.referencia
			, cfa.colonia
			, cfa.idciudad
			, cfa.codpostal
		)
	FROM
		ew_clientes_facturacion AS cfa
	WHERE
		cfa.idcliente = @idcliente
		AND cfa.idfacturacion = @idfacturacion

	SELECT @direccion = ISNULL(@direccion, '')

	RETURN @direccion
END
GO
