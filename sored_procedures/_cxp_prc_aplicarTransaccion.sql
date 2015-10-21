USE [db_comercial_final]
GO
-- ==========================================================================================
-- Autor:		Laurence Saavedra
-- Fecha:		2010-02
-- Descripcion:	Aplica el importe de la transaccion en la cartera modificando el saldo del proveedor
--				si existen afectaciones a transacciones en diferente moneda
--				se deberán realizar movimientos de ajuste para cada moneda.
--
--				SET DATEFORMAT DMY EXEC _cxp_prc_aplicarTransaccion 610,'26/02/10',1
-- ==========================================================================================
ALTER PROCEDURE [dbo].[_cxp_prc_aplicarTransaccion]
	@idtran AS BIGINT
	,@aplicado_fecha AS SMALLDATETIME
	,@idu AS SMALLINT
AS

SET NOCOUNT ON

DECLARE
	@error_mensaje AS VARCHAR(200)
	,@idestado AS SMALLINT

--------------------------------------------------------------------------------
-- Validando la transaccion
--------------------------------------------------------------------------------
SELECT @idestado = dbo.fn_sys_estadoActual(@idtran)

IF @idestado < 0
BEGIN
	SELECT @error_mensaje = 'Error 1: EW_SYS_TRANSACCIONES, 
Transacción Inválida.'
	RAISERROR (@error_mensaje, 16, 1)
	RETURN
END

IF @idestado = 255
BEGIN
	SELECT @error_mensaje = 'Error 2: EW_SYS_TRANSACCIONES, 
Transacción se encuentra cancelada.'
	RAISERROR (@error_mensaje, 16, 1)
	RETURN
END

IF NOT EXISTS(SELECT idtran FROM ew_cxp_transacciones WHERE idtran = @idtran)
BEGIN
	SELECT @error_mensaje = 'Error 3: EW_CXP_TRANSACCIONES, 
Transacción no es de cartera.'
	RAISERROR (@error_mensaje, 16, 1)
	RETURN
END

--------------------------------------------------------------------------------
-- EW_CXP_MOVIMIENTOS. Aplicando la transaccion en la cartera 
--
--------------------------------------------------------------------------------
IF NOT EXISTS (
	SELECT idtran
	FROM ew_cxp_movimientos
	WHERE
		idtran = @idtran
		AND idtran2 = 0
)
BEGIN
	--------------------------------------------------------------------------------
	-- Registrando en la cartera
	--------------------------------------------------------------------------------
	INSERT INTO ew_cxp_movimientos 
		(idtran, idtran2, tipo, idconcepto, idmoneda, idproveedor, fecha, importe, idu)
	SELECT
		idtran, 0, tipo, idconcepto, idmoneda, idproveedor, @aplicado_fecha, total, @idu
	FROM
		ew_cxp_transacciones
	WHERE
		idtran = @idtran

	IF (@@error != 0) OR (@@ROWCOUNT=0)
	BEGIN
		SELECT @error_mensaje = 'Error 4: EW_CXP_MOVIMIENTOS, 
Error al registrar el movimiento.'
		RAISERROR(@error_mensaje, 16, 1)
		RETURN
	END

	--------------------------------------------------------------------------------
	-- Modificando el Estatus a APLICADO
	--------------------------------------------------------------------------------
	INSERT INTO ew_sys_transacciones2
		(idtran, idestado, idu)
	VALUES 
		(@idtran, dbo.fn_sys_estadoID('APL'), @idu)
	
END

--------------------------------------------------------------------------------
-- EW_CXP_TRANSACCIONES. Indicando que ha sido aplicada
--------------------------------------------------------------------------------
UPDATE ew_cxp_transacciones SET 
	aplicado = 1
	,aplicado_fecha = @aplicado_fecha
	,saldo = total
WHERE 
	idtran = @idtran
	AND aplicado = 0

EXEC _cxp_prc_referenciaAplicar @idtran

--------------------------------------------------------------------------------
-- EW_CXP_TRANSACCIONES_MOV. Cuando una transaccion (IDTRAN) se encuentra en una moneda 
-- y las transacciones referenciadas (IDTRAN2) se encuentran en moneda diferente
-- es necesario realizar ajustes a los saldos de cartera por cada moneda.
--------------------------------------------------------------------------------
IF EXISTS(
	SELECT	
		i.idtran
	FROM	
		ew_cxp_transacciones_mov i
		LEFT JOIN ew_cxp_movimientos AS m1 
			ON m1.idtran = i.idtran 
			AND m1.idtran2 = 0 
		LEFT JOIN ew_cxp_movimientos AS m2 
			ON m2.idtran = i.idtran2 
			AND m2.idtran2 = 0 
		LEFT JOIN ew_cxp_movimientos AS m3 
			ON m3.idtran = i.idtran 
			AND m3.idtran2 = i.idtran2 
			AND m3.tipo = m1.tipo 
			AND m3.idconcepto = 999 
			AND m3.idmoneda = m1.idmoneda
	WHERE
		i.idtran = @idtran
		AND i.importe != 0
		AND m1.idtran IS NOT NULL
		AND m2.idtran IS NOT NULL
		AND m1.idmoneda != m2.idmoneda
		AND m3.idtran IS NULL
)
BEGIN
	--------------------------------------------------------------------------------
	-- EW_CXP_MOVIMIENTOS. Modificacion al saldo de la cartera en la moneda IDTRAN
	--------------------------------------------------------------------------------
	INSERT INTO ew_cxp_movimientos (
		idtran
		,idtran2
		,tipo
		,idconcepto
		,idmoneda
		,idproveedor
		,fecha
		,importe
		,idu
	)
	SELECT	
		i.idtran
		,i.idtran2
		,m1.tipo
		,[idconcepto] = 999
		,m1.idmoneda
		,m1.idproveedor
		,@aplicado_fecha
		,[importe] = (i.importe*(-1))
		,@idu
	FROM	
		ew_cxp_transacciones_mov i
		LEFT JOIN ew_cxp_movimientos AS m1 
			ON m1.idtran = i.idtran 
			AND m1.idtran2 = 0 
		LEFT JOIN ew_cxp_movimientos AS m2 
			ON m2.idtran = i.idtran2 
			AND m2.idtran2 = 0 
		LEFT JOIN ew_cxp_movimientos AS m3 
			ON m3.idtran = i.idtran 
			AND m3.idtran2 = i.idtran2 
			AND m3.tipo = m1.tipo 
			AND m3.idconcepto = 999 
			AND m3.idmoneda = m1.idmoneda
	WHERE
		i.idtran = @idtran
		AND i.importe != 0
		AND m1.idtran IS NOT NULL
		AND m2.idtran IS NOT NULL
		AND m1.idmoneda != m2.idmoneda
		AND m3.idtran IS NULL

	IF (@@error != 0) OR (@@ROWCOUNT=0)
	BEGIN
		SELECT @error_mensaje = 'Error 5: EW_CXP_MOVIMIENTOS, 
Error al registrar el ajuste para la moneda 1.'
		RAISERROR(@error_mensaje, 16, 1)
		RETURN
	END	

	--------------------------------------------------------------------------------
	-- EW_CXP_MOVIMIENTOS. Modificacion al saldo de la cartera en la moneda IDTRAN2
	--------------------------------------------------------------------------------
	INSERT INTO ew_cxp_movimientos (
		idtran
		,idtran2
		,tipo
		,idconcepto
		,idmoneda
		,idproveedor
		,fecha
		,importe
		,idu
	)
	SELECT	
		i.idtran
		,i.idtran2
		,m2.tipo
		,[idconcepto] = 999
		,m2.idmoneda
		,m2.idproveedor
		,@aplicado_fecha
		,[importe] = (i.importe2*(-1))
		,@idu
	FROM	
		ew_cxp_transacciones_mov i
		LEFT JOIN ew_cxp_movimientos AS m1 
			ON m1.idtran = i.idtran 
			AND m1.idtran2 = 0 
		LEFT JOIN ew_cxp_movimientos AS m2 
			ON m2.idtran = i.idtran2 
			AND m2.idtran2 = 0 
		LEFT JOIN ew_cxp_movimientos AS m3 
			ON m3.idtran = i.idtran 
			AND m3.idtran2 = i.idtran2 
			AND m3.tipo = m1.tipo 
			AND m3.idconcepto = 999 
			AND m3.idmoneda = m2.idmoneda
	WHERE
		(i.idtran=@idtran)
		AND (i.importe!=0)
		AND (m1.idtran IS NOT NULL)
		AND (m2.idtran IS NOT NULL)
		AND (m1.idmoneda!=m2.idmoneda)
		AND (m3.idtran IS NULL)

	IF (@@error != 0) OR (@@ROWCOUNT=0)
	BEGIN
		SELECT @error_mensaje = 'Error 6: EW_CXP_MOVIMIENTOS, 
Error al registrar el ajuste para la moneda 2.'
		RAISERROR(@error_mensaje, 16, 1)
		RETURN
	END			
	--------------------------------------------------------------------------------
	-- EW_CT_POLIZAMOV. Acumulando los registros contables pendientes de aplicacion IDTRAN.
	--------------------------------------------------------------------------------
	UPDATE ew_ct_poliza_mov SET
		acumulado = 1
	WHERE
		idtran2 = @idtran
		AND acumulado = 0

	IF (@@error != 0)
	BEGIN
		SELECT @error_mensaje = 'Error 7: EW_CT_POLIZA_MOV, 
Error al acumular los movimientos contables.'
		RAISERROR(@error_mensaje, 16, 1)
		RETURN
	END	
END
GO
