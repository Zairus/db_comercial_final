USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20141110
-- Description:	Saldo de documento a una fecha determinada
-- =============================================
ALTER FUNCTION [dbo].[_cxc_fnc_documentoSaldoR2]
(
	 @idtran AS INT
	,@fecha AS DATETIME
)
RETURNS DECIMAL(18,6)
AS
BEGIN
	DECLARE
		 @saldo AS DECIMAL(18,6)

	SELECT TOP 1
		@saldo = cts.saldo
	FROM
		ew_cxc_transacciones_saldos AS cts
	WHERE
		cts.idtran = @idtran
		AND cts.fecha <= @fecha
	ORDER BY
		cts.idr DESC

	SELECT @saldo = ISNULL(@saldo, 0)

	RETURN @saldo
END
GO
