USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170113
-- Description:	Cancelar deposito por pago de cliente
-- =============================================
ALTER PROCEDURE [dbo].[_ban_prc_depositoCancelar]
	@idtran AS INT
	,@cancelado_fecha AS SMALLDATETIME
	,@idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@idtran2 AS INT
	,@cancelado AS BIT

SELECT
	@cancelado = cancelado
FROM
	ew_ban_transacciones
WHERE
	idtran = @idtran

DECLARE cur_depositoPagosC CURSOR FOR
	SELECT
		idtran
	FROM
		ew_cxc_transacciones
	WHERE
		idtran2 = @idtran

OPEN cur_depositoPagosC

FETCH NEXT FROM cur_depositoPagosC INTO
	@idtran2

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC [dbo].[_cxc_prc_pagoCancelar] @idtran2, @cancelado_fecha, @idu

	INSERT INTO ew_sys_transacciones2
		(idtran, idestado, idu)
	VALUES
		(@idtran2, 255, @idu)

	EXEC [dbo].[_ct_prc_transaccionCancelarContabilidad] @idtran2, 1, @cancelado_fecha, @idu

	FETCH NEXT FROM cur_depositoPagosC INTO
		@idtran2
END

CLOSE cur_depositoPagosC
DEALLOCATE cur_depositoPagosC

IF @cancelado = 0
	EXEC [dbo].[_ban_prc_cancelarTransaccion] @idtran, @cancelado_fecha, @idu
GO
