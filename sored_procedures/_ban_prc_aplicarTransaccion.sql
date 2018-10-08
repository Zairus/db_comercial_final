USE [db_comercial_final]
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 20071001
-- Description:	Funcion que aplica una transaccion de bancos pendiente de aplicación,
--              en ban_TRANSACCIONES y genera una afectacion en la cartera ban_movimientos
-- =============================================
ALTER PROCEDURE [dbo].[_ban_prc_aplicarTransaccion]
	@idtran AS INT
	,@aplicado_fecha AS SMALLDATETIME
	,@idu AS SMALLINT
AS

SET NOCOUNT ON

DECLARE	
	@id AS BIGINT
	,@idtran2 AS BIGINT
	,@aplicado AS BIT
	,@idcuenta AS SMALLINT
	,@tipo AS TinyInt
	,@idconcepto AS SMALLINT
	,@importe AS DECIMAL(15,2)
	,@fecha AS SMALLDATETIME
	,@cont AS SMALLINT
	,@msg AS VARCHAR(250)
	,@idestado AS INT
	
-- Obtenemos los datos de la transaccion y se exige que no se encuentre cancelada ó inactiva
SELECT 
	@aplicado = aplicado
	, @idcuenta = idcuenta
	, @idtran2 = idtran2
	, @tipo = tipo
	, @idconcepto = idconcepto
	, @importe = importe
FROM 
	ew_ban_transacciones 
WHERE
	idtran = @idtran 
	AND cancelado = 0

IF @@ROWCOUNT = 0
BEGIN
	SELECT @msg = 'Error 1: BAN_TRANSACCIONES, no se permitió aplicar la transaccion.'
	
	RAISERROR(@msg, 16, 1)
	RETURN
END

-- Si el movimiento en ban_TRANSACCIONES no ha sido aplicado, se aplica completo a CXC
IF @aplicado = 0 AND @tipo In (1,2)
BEGIN
	INSERT INTO ew_ban_movimientos(
		idtran
		, idtran2
		, idcuenta
		, tipo
		, idconcepto
		, fecha
		, importe
		, idu
	)
	VALUES (
		@idtran
		, @idtran2
		, @idcuenta
		, @tipo
		, @idconcepto
		, @aplicado_fecha
		, @importe
		, @idu
	)
	
	IF @@ERROR != 0 OR @@ROWCOUNT = 0
	BEGIN
		SELECT @msg='Error. Al intentar aplicar el movimiento de la cuenta de bancos en BAN_MOVIMIENTOS)'
		
		RAISERROR(@msg, 16, 1)
		RETURN
	END
	
	-- Modificando el Estatus a APL
	IF NOT EXISTS(SELECT [a] = 'No' WHERE dbo.fn_sys_estadoActual(@idtran) = dbo.fn_sys_estadoID('APL'))
	BEGIN		
		INSERT INTO ew_sys_transacciones2
			(idtran,  idestado, idu)
		VALUES 
			(@idtran, dbo.fn_sys_estadoID('APL'), @idu)
	END

	-- Modificando la bandera de aplicado
	UPDATE ew_ban_transacciones SET 
		aplicado = 1
		,aplicado_fecha = @aplicado_fecha
	WHERE 
		idtran = @idtran

	-- Aplicando en Cuentas por Pagar
	IF @idtran2 > 0
	BEGIN
		IF EXISTS(SELECT idtran FROM ew_cxc_transacciones WHERE cancelado = 0 AND idtran = @idtran2)
		BEGIN
			EXEC _cxc_prc_aplicarTransaccion @idtran2, @aplicado_fecha, @idu

			SELECT @idestado = dbo.fn_sys_estadoID('PAGA')

			EXEC _sys_prc_transaccionEstado @idtran2, @idestado, @idu
		END

		IF EXISTS(SELECT idtran FROM ew_cxp_transacciones WHERE cancelado = 0 AND idtran = @idtran2)
		BEGIN
			EXEC _cxp_prc_aplicarTransaccion @idtran2, @aplicado_fecha, @idu

			SELECT @idestado = dbo.fn_sys_estadoID('PAGA')

			EXEC _sys_prc_transaccionEstado @idtran2, @idestado, @idu
		END
	END
END
GO
