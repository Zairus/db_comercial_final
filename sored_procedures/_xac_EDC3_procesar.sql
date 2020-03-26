USE db_comercial_final
GO
IF OBJECT_ID('_xac_EDC3_procesar') IS NOT NULL
BEGIN
	DROP PROCEDURE _xac_EDC3_procesar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200310
-- Description:	Procesar nota de venta recibo provisional
-- =============================================
CREATE PROCEDURE [dbo].[_xac_EDC3_procesar]
	@idtran AS INT
	, @idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@credito AS BIT
	, @pago_total AS DECIMAL(18,6)
	, @total AS DECIMAL(18,6)

DECLARE
	@error_mensaje AS VARCHAR(1000)

SELECT
	@credito = ct.credito
	, @total = ct.total
FROM
	ew_cxc_transacciones AS ct
WHERE
	ct.idtran = @idtran

SELECT
	@pago_total = SUM(vtp.total + vtp.total2)
FROM
	ew_ven_transacciones_pagos AS vtp
WHERE
	vtp.idtran = @idtran

--Validar que sea pagado si no hay credito
IF @credito = 0 AND @pago_total < @total
BEGIN
	SELECT 
		@error_mensaje = (
			'Error: Nota de contado debe ser pagada totalmente. '
			+ 'credito: ' + CONVERT(VARCHAR(50), ISNULL(@credito, 0))
			+ ', pago_total: ' + CONVERT(VARCHAR(50), ISNULL(@pago_total, 0))
			+ ', total: ' + CONVERT(VARCHAR(50), ISNULL(@total, 0))
		)

	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

IF @credito = 1 AND @pago_total >= @total
BEGIN
	UPDATE ew_cxc_transacciones SET
		credito = 0
	WHERE
		idtran = @idtran
END

--Pagar
IF (
	@pago_total > 0 
	AND EXISTS(
		SELECT * 
		FROM 
			ew_ven_transacciones_pagos 
		WHERE 
			consecutivo = 0 
			AND (
				total > 0
				OR total2 > 0
			)
			AND idtran = @idtran
	)
)
BEGIN
	EXEC [dbo].[_ven_prc_ticketVentaPagos] @idtran, @idu
END

EXEC _ven_prc_facturaPagos @idtran

EXEC [dbo].[_ct_prc_polizaAplicarDeConfiguracion] @idtran, 'EFA6', @idtran

IF EXISTS(
	SELECT * 
	FROM 
		ew_ven_comprobacion_ventas 
	WHERE 
		ABS(total_documento - total_detalle) > 0.01 
		AND idtran = @idtran
)
BEGIN
	SELECT
		@error_mensaje = (
			ISNULL(@error_mensaje, '')
			+ CHAR(13)
			+ 'Error: El total de la venta no coincide con la suma de sus partidas.'
		)

	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END
GO
