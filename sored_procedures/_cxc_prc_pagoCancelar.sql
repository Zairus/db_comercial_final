USE [db_comercial_final]
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
	,@forzar AS BIT = 0
AS

SET NOCOUNT ON

DECLARE
	@tipo_cxc AS INT
	,@tipo_ban AS INT
	,@codigo_referencia AS VARCHAR(10)

SELECT
	@tipo_cxc = ct.tipo
	,@codigo_referencia = ISNULL(st.transaccion, '')
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = ct.idtran2
WHERE
	ct.idtran = @idtran

SELECT
	@tipo_ban = tipo
FROM
	ew_ban_transacciones
WHERE
	idtran = @idtran

IF @codigo_referencia = 'BDC3' AND @forzar = 0
BEGIN
	RAISERROR('Error: No se puede cancelar pago que se incluye en ficha de deposito.', 16, 1)
	RETURN
END

IF EXISTS (
	SELECT p.idr
	FROM
		ew_cxc_transacciones AS p
	WHERE
		DAY(GETDATE()) > 10
		AND (
			MONTH(p.fecha) < MONTH(GETDATE())
			OR YEAR(p.fecha) < YEAR(GETDATE())
		)
		AND p.idtran = @idtran
)
BEGIN
	RAISERROR('Error: No es permitid por el SAT, cancelar un REP cuyo pago afecta documentos de meses anteriores, cuando ya ha pasado eldia 10 del mes en curso.', 16, 1)
	RETURN
END

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

IF @tipo_cxc > 0
	EXEC [dbo].[_cxc_prc_cancelarTransaccion] @idtran, @cancelado_fecha, @idu

IF @tipo_ban > 0
	EXEC [dbo].[_ban_prc_cancelarTransaccion] @idtran, @cancelado_fecha, @idu

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

UPDATE ew_cxc_transacciones SET
	cancelado = 1
	,cancelado_fecha = @cancelado_fecha
WHERE
	idtran = @idtran
GO
