USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160215
-- Description:	Proporcion de pago de factura a una fecha
-- =============================================
ALTER FUNCTION [dbo].[_cxc_prc_facturaPagoProporcion]
(
	@idtran AS INT
	,@fecha AS SMALLDATETIME
	,@abonos AS BIT
)
RETURNS DECIMAL(18,6)
AS
BEGIN
	DECLARE
		@proporcion AS DECIMAL(18,6)
		,@total AS DECIMAL(18,6)
		,@pagos AS DECIMAL(18,6)

	SELECT
		@total = ct.total
	FROM
		ew_cxc_transacciones AS ct
	WHERE
		ct.idtran = @idtran

	SELECT 
		@pagos = SUM(ctm1.importe2)
	FROM
		ew_cxc_transacciones AS ct
		LEFT JOIN ew_cxc_transacciones_mov AS ctm1
			ON ctm1.idtran2 = ct.idtran
		LEFT JOIN ew_cxc_transacciones AS ct1
			ON ct1.idtran = ctm1.idtran
		LEFT JOIN ew_ban_transacciones AS bt
			ON bt.idtran = ct1.idtran
	WHERE
		(
			bt.idr IS NOT NULL
			OR @abonos = 1
		)
		AND ct1.tipo <> ct.tipo
		AND CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ct1.fecha, 3) + ' 00:00') <= @fecha
		AND ct.idtran = @idtran

	SELECT @pagos = ISNULL(@pagos, 0)
	SELECT @proporcion = @pagos / @total
	SELECT @proporcion = ISNULL(@proporcion, 0)

	IF @proporcion > 1.0
		SELECT @proporcion = 1.0

	RETURN @proporcion
END
GO
