USE db_comercial_final
GO
IF OBJECT_ID('_com_fnc_importeEntradaPorCompra') IS NOT NULL
BEGIN
	DROP FUNCTION _com_fnc_importeEntradaPorCompra
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190101
-- Description:	Obtener importe de entrada directa a almacen por compra
-- =============================================
CREATE FUNCTION [dbo].[_com_fnc_importeEntradaPorCompra]
(
	@idtran AS INT
)
RETURNS DECIMAL(18,6)
AS
BEGIN
	DECLARE
		@importe AS DECIMAL(18,6)

	SELECT 
		@importe = SUM(itm.costo)
	FROM
		ew_inv_transacciones AS it
		LEFT JOIN ew_inv_transacciones_mov AS itm
			ON itm.idtran = it.idtran
	WHERE
		itm.tipo = 1
		AND it.idtran2 = @idtran
	HAVING
		SUM(itm.costo) > 0

	SELECT @importe = ISNULL(@importe, 0)

	RETURN @importe
END
GO
