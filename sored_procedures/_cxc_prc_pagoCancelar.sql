USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091203
-- Description:	Cancelar pago de cliente
-- =============================================
ALTER PROCEDURE [dbo].[_cxc_prc_pagoCancelar]
	@idtran AS INT
	,@cancelado_fecha AS SMALLDATETIME
	,@idu AS SMALLINT
AS

SET NOCOUNT ON

INSERT INTO ew_sys_transacciones2 (
	idtran
	,idestado
	,idu
)
SELECT
	[idtran] = ct.idtran2
	,[idestado] = 0
	,[idu] = @idu
FROM
	ew_cxc_transacciones_mov AS ct
WHERE
	ct.idtran = @idtran

EXEC dbo._cxc_prc_cancelarTransaccion @idtran, @cancelado_fecha, @idu

EXEC dbo._ban_prc_cancelarTransaccion @idtran, @cancelado_fecha, @idu

UPDATE ew_ven_transacciones_pagos SET
	idforma = 0
	,forma_referencia = ''
	,subtotal = 0
	,impuesto1 = 0
	,total = 0	
WHERE
	idtran2 = @idtran

UPDATE ew_ven_transacciones_pagos SET
	idforma2 = 0
	,forma_referencia2 = ''
	,total2 = 0	
WHERE
	idtran_pago2 = @idtran

UPDATE dbo.ew_cxc_transacciones SET
	cancelado = 1
	,cancelado_fecha = @cancelado_fecha
WHERE
	idtran = @idtran
GO
