USE db_comercial_final
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: yyyymmdd
-- Description:	Cancelar transaccion de bancos
-- =============================================
ALTER PROCEDURE [dbo].[_ban_prc_cancelarTransaccion]
	@idtran AS BIGINT
	, @cancelado_fecha AS SMALLDATETIME
	, @idu AS SMALLINT
	, @desaplicar_referencias AS BIT = 1
	, @forzar AS BIT = 0
AS

SET NOCOUNT ON

DECLARE
	@idtran2 AS BIGINT
	, @aplicado AS BIT
	, @tipo AS TINYINT
	, @idconcepto AS SMALLINT
	, @idcuenta AS SMALLINT
	, @importe AS DECIMAL(15,2)
	, @total AS DECIMAL(15,2)
	, @moneda AS SMALLINT
	, @msg AS VARCHAR(250)
	, @fecha AS SMALLDATETIME
	, @password AS VARCHAR(20)
	, @transaccionref AS VARCHAR(4)

SELECT 
	@idtran2 = bt.idtran2
	, @aplicado = bt.aplicado
	, @idcuenta = bt.idcuenta
	, @tipo = bt.tipo
	, @idconcepto = (bt.idconcepto + 1000)
	, @importe = bt.importe
	, @fecha = bt.fecha
	, @transaccionref = ISNULL(st.transaccion, '')
FROM
	ew_ban_transacciones AS bt
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = bt.idtran2
WHERE
	bt.idtran = @idtran
	AND bt.cancelado = 0

IF @transaccionref IN ('BDT1', 'DDA4') AND @forzar = 0
BEGIN
	SELECT 
		@msg = 'Error 1: BAN_TRANSACCIONES, la transaccion proviene de ' + o.nombre + ', se debe cancelar dicha transaccion.'
	FROM
		objetos AS o
	WHERE
		o.codigo = @transaccionref

	RAISERROR (@msg, 16, 1)
	RETURN
END

SELECT
	@password = [password]
FROM
	evoluware_usuarios
WHERE
	idu = @idu

IF @@rowcount = 0
BEGIN
	SELECT @msg = 'Error 1: BAN_TRANSACCIONES, no se logró cancelar la transaccion.'
	RAISERROR (@msg, 16, 1)
	RETURN
END

--------------------------------------------------------------------------------
-- Cancelamos los movimientos del libro de bancos (BAN_MOVIMIENTOS) 
--------------------------------------------------------------------------------
INSERT INTO ew_ban_movimientos (
	idtran
	,idtran2
	,idcuenta
	,tipo
	,idconcepto
	,fecha
	,importe
	,idu
)
SELECT 
	idtran
	,idtran2
	,idcuenta
	,tipo
	,[idconcepto] = @idconcepto 
	,[fecha] = @cancelado_fecha
	,[importe] = (importe * -1)
	,[idu] = @idu
FROM 
	ew_ban_movimientos 
WHERE 
	idtran = @idtran 

--------------------------------------------------------------------------------
-- Cancelamos el movimiento en (ban_TRANSACCIONES)
--------------------------------------------------------------------------------
UPDATE ew_ban_transacciones SET
	cancelado = 1
	,cancelado_fecha = @cancelado_fecha
WHERE
	idtran = @idtran

--------------------------------------------------------------------------------
-- Cancelamos el movimiento en Contabilidad
--------------------------------------------------------------------------------
EXEC [dbo].[_ct_prc_transaccionCancelarContabilidad]
	 @idtran
	,1
	,@fecha
	,@idu

--------------------------------------------------------------------------------
-- Cancelamos el movimiento en Cuentas por Pagar
--------------------------------------------------------------------------------
IF (@idtran2 > 0 AND @desaplicar_referencias = 1)
BEGIN
	IF EXISTS(
		SELECT idtran 
		FROM ew_cxc_transacciones 
		WHERE idtran = @idtran2
	)
	BEGIN
		EXEC _cxc_prc_desaplicarTransaccion @idtran2, @idu

		INSERT INTO ew_sys_transacciones2 (
			idtran
			,idestado
			,idu
		)
		SELECT
			[idtran] = @idtran2
			,[idestado] = dbo.fn_sys_estadoID('RACT')
			,[idu] = @idu
	END

	IF EXISTS(
		SELECT idtran 
		FROM ew_cxp_transacciones 
		WHERE idtran = @idtran2
	)
	BEGIN
		EXEC _cxp_prc_desaplicarTransaccion @idtran2, @cancelado_fecha, @idu

		INSERT INTO ew_sys_transacciones2 (
			idtran
			,idestado
			,idu
		)
		SELECT
			[idtran] = @idtran2
			,[idestado] = dbo.fn_sys_estadoID('PROG')
			,[idu] = @idu
	END
END
GO
