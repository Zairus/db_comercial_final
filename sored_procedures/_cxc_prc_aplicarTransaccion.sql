USE db_comercial_final
GO
-- ==========================================================================================
-- Autor:		Laurence Saavedra
-- Fecha:		2010-02
-- Descripcion:	Aplica el importe de la transaccion en la cartera modificando el saldo del cliente
--				si existen afectaciones a transacciones en diferente moneda
--				se deberán realizar movimientos de ajuste para cada moneda.
--
--				SET DATEFORMAT DMY EXEC _cxc_prc_aplicarTransaccion 610,'26/02/10',1
-- ==========================================================================================
ALTER PROCEDURE [dbo].[_cxc_prc_aplicarTransaccion]
	@idtran AS INT
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

IF NOT EXISTS(SELECT idtran FROM ew_cxc_transacciones WHERE idtran=@idtran)
BEGIN
	SELECT @error_mensaje = 'Error 3: EW_cxc_TRANSACCIONES, 
Transacción no es de cartera.'
	RAISERROR (@error_mensaje, 16, 1)
	RETURN
END
	
--------------------------------------------------------------------------------
-- EW_cxc_MOVIMIENTOS. Aplicando la transaccion en la cartera 
--------------------------------------------------------------------------------
IF NOT EXISTS (
	SELECT idtran 
	FROM ew_cxc_movimientos 
	WHERE 
		idtran2 = 0
		AND idtran = @idtran
)
BEGIN
	--------------------------------------------------------------------------------
	-- Registrando en la cartera
	--------------------------------------------------------------------------------
	INSERT INTO ew_cxc_movimientos 
		(idtran, idtran2, tipo, idconcepto, idmoneda, idcliente, fecha, importe, idu)
	SELECT
		idtran, 0, tipo, idconcepto, idmoneda, idcliente, @aplicado_fecha, total, @idu
	FROM
		ew_cxc_transacciones
	WHERE
		idtran = @idtran

	IF (@@error != 0) OR (@@ROWCOUNT=0)
	BEGIN
		SELECT @error_mensaje = 'Error 4: EW_cxc_MOVIMIENTOS, 
Error al registrar el movimiento.'
		RAISERROR(@error_mensaje, 16, 1)
		RETURN
	END
	
	--------------------------------------------------------------------------------
	-- Modificando el Estatus a APLICADO
	--------------------------------------------------------------------------------
	EXEC _sys_prc_trnAplicarEstado @idtran, 'APL', @idu, 1
END

--------------------------------------------------------------------------------
-- EW_cxc_TRANSACCIONES. Indicando que ha sido aplicada
--------------------------------------------------------------------------------
UPDATE ew_cxc_transacciones SET 
	aplicado = 1
	,aplicado_fecha = @aplicado_fecha
WHERE 
	idtran = @idtran
	AND aplicado = 0

--------------------------------------------------------------------------------
--- insertamos el detalle en ew_ban_transacciones_mov 
--------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM ew_ban_transacciones WHERE idtran = @idtran )
BEGIN
	-- Aplicar la transaccion en Bancos
	EXEC _ban_prc_aplicarTransaccion 
		@idtran
		,@aplicado_fecha
		,@idu

	-- Insertar el detalle de la transaccion en Bancos
	IF NOT EXISTS(
		SELECT idtran 
		FROM ew_ban_transacciones_mov 
		WHERE idtran = @idtran
	)
	BEGIN
		INSERT INTO ew_ban_transacciones_mov (
			consecutivo
			,idconcepto
			,importe
			,idimpuesto
			,impuesto_tasa
			,impuesto,idtran
		)
		SELECT     
			[consecutivo] = ROW_NUMBER() OVER (ORDER BY ordenes_pagos_clientes.idtran2)
			,idconcepto
			,importe
			,idimpuesto
			,impuesto_tasa
			,[impuesto] = importe * impuesto_tasa
			,[idtran] = idtran2
		FROM
			ordenes_pagos_clientes
		WHERE
			idtran2 = @idtran
	END
END

--------------------------------------------------------------------------------
-- EW_cxc_TRANSACCIONES_MOV. Cuando una transaccion (IDTRAN) se encuentra en una moneda 
-- y las transacciones referenciadas (IDTRAN2) se encuentran en moneda diferente
-- es necesario realizar ajustes a los saldos de cartera por cada moneda.
--------------------------------------------------------------------------------
IF EXISTS(
	SELECT	
		i.idtran
	FROM	
		ew_cxc_transacciones_mov AS i
		LEFT JOIN ew_cxc_movimientos AS m1 
			ON m1.idtran = i.idtran 
			AND m1.idtran2 = 0 
		LEFT JOIN ew_cxc_movimientos AS m2 
			ON m2.idtran = i.idtran2 
			AND m2.idtran2 = 0 
		LEFT JOIN ew_cxc_movimientos AS m3 
			ON m3.idtran = i.idtran 
			AND m3.idtran2 = i.idtran2 
			AND m3.tipo=m1.tipo 
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
	-- EW_cxc_MOVIMIENTOS. Modificacion al saldo de la cartera en la moneda IDTRAN
	--------------------------------------------------------------------------------
	INSERT INTO ew_cxc_movimientos (
		idtran
		, idtran2
		, tipo
		, idconcepto
		, idmoneda
		, idcliente
		, fecha
		, importe
		, idu
	)
	SELECT	
		i.idtran
		,i.idtran2
		,m1.tipo
		,999
		,m1.idmoneda
		,m1.idcliente
		,@aplicado_fecha
		,(i.importe*(-1))
		,@idu
	FROM	
		ew_cxc_transacciones_mov AS i
		LEFT JOIN ew_cxc_movimientos AS m1 
			ON m1.idtran = i.idtran 
			AND m1.idtran2 = 0 
		LEFT JOIN ew_cxc_movimientos AS m2 
			ON m2.idtran = i.idtran2 
			AND m2.idtran2 = 0 
		LEFT JOIN ew_cxc_movimientos AS m3 
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
	
	UNION ALL

	SELECT	
		i.idtran
		,i.idtran2
		,m2.tipo
		,999
		,m2.idmoneda
		,m2.idcliente
		,@aplicado_fecha
		,(i.importe2*(-1))
		,@idu
	FROM	
		ew_cxc_transacciones_mov AS i
		LEFT JOIN ew_cxc_movimientos AS m1 
			ON m1.idtran = i.idtran 
			AND m1.idtran2 = 0 
		LEFT JOIN ew_cxc_movimientos AS m2 
			ON m2.idtran = i.idtran2 
			AND m2.idtran2 = 0 
		LEFT JOIN ew_cxc_movimientos AS m3 
			ON m3.idtran = i.idtran 
			AND m3.idtran2 = i.idtran2 
			AND m3.tipo != m1.tipo 
			AND m3.idconcepto = 999 
			AND m3.idmoneda = m2.idmoneda
	WHERE
		i.idtran = @idtran
		AND i.importe != 0
		AND m1.idtran IS NOT NULL
		AND m2.idtran IS NOT NULL
		AND m1.idmoneda != m2.idmoneda
		AND m1.idconcepto != 999
		AND m2.idconcepto != 999
		AND m3.idtran IS NULL

	IF (@@error != 0) OR (@@ROWCOUNT = 0)
	BEGIN
		SELECT @error_mensaje = 'Error 5: EW_cxc_MOVIMIENTOS, 
Error al registrar el ajuste para la moneda 1.'
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


--------------------------------------------------------------------------------
-- EW_CXC_TRANSACCIONES.SALDO_REFERENCIA
--------------------------------------------------------------------------------
DECLARE 
	@idtran2 AS INT
	,@total AS DECIMAL(15,2)

SELECT 
	@idtran2 = ISNULL(idtran2,0)
	, @total = ISNULL(total,0) 
FROM 
	ew_cxc_transacciones 
WHERE 
	idtran = @idtran 
	AND idtran2 > 0 
	AND total > 0

IF @idtran2 > 0 AND @total > 0
BEGIN
	DECLARE 
		@idmov2 AS DECIMAL(15,4)

	SELECT TOP 1
		@idmov2 = ISNULL(idmov, (@idtran2 + 0.0001))
	FROM
		ew_sys_movimientos AS m
		LEFT JOIN evoluware_tablas AS t 
			ON t.tabla = m.tabla
	WHERE
		m.idmov BETWEEN (@idtran2 + 0.0001) AND (@idtran + 0.9999)
	ORDER BY
		(CASE WHEN UPPER(t.nombre) = 'EW_CXC_TRANSACCIONES' THEN 0 ELSE 1 END)

	INSERT INTO ew_sys_movimientos_acumula (
		idmov1
		, idmov2
		, campo
		, valor
	)
	SELECT 
		(idtran+0.0001)
		, @idmov2
		, 'saldo_referencia'
		, total 
	FROM
		ew_cxc_transacciones
	WHERE
		idtran = @idtran
END
GO
