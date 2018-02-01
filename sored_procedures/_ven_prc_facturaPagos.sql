USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20100206
-- Description:	Afectar pagos en facturas.
-- Modificacion: Arvin 2010 JUL adaptado a la nueva estructura.
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_facturaPagos]
	@idtran INT
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACION DE VARIABLES ####################################################

DECLARE
	@idmov AS MONEY
	,@idtran2 AS INT
	,@idforma AS SMALLINT
	,@subtotal AS DECIMAL(18,6)
	,@impuesto1 AS DECIMAL(18,6)
	,@total AS DECIMAL(18,6)
	,@comentario AS VARCHAR(MAX)
	,@error AS BIT
	,@error_mensaje AS VARCHAR(500)
	,@fecha AS SMALLDATETIME
	,@idsucursal AS SMALLINT
	,@idcliente AS INT
	,@idmoneda AS SMALLINT
	,@tipocambio AS DECIMAL(18,6)
	,@idimpuesto1 AS SMALLINT
	,@idimpuesto1_valor AS DECIMAL(18,6)
	,@saldo_referencia AS DECIMAL(18,6)
	,@saldo_aplicacion AS DECIMAL(18,6)
	,@idu AS SMALLINT
	,@idcuenta AS SMALLINT
	,@consecutivo AS SMALLINT
	,@referencia AS VARCHAR(20)
	,@sql AS VARCHAR(MAX)
	,@usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)
	,@pago_idtran AS INT
	,@pago_referencia AS VARCHAR(200)
	,@idr AS INT
--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

SELECT @error = 0

SELECT
	@fecha = vt.fecha
	,@idcliente = vt.idcliente
	,@saldo_referencia = ct.saldo
	,@idu = vt.idu
	,@idsucursal = vt.idsucursal
	,@idimpuesto1= ct.idimpuesto1
	,@idimpuesto1_valor = ct.idimpuesto1_valor
	,@idmoneda = ct.idmoneda
	,@tipocambio = ct.tipocambio
	,@referencia = vt.transaccion +'-'+ vt.folio
FROM 
	ew_ven_transacciones vt
	LEFT JOIN ew_cxc_transacciones ct 
		ON ct.idtran = vt.idtran
WHERE
	vt.idtran = @idtran

SELECT
	@idcuenta = idcuenta_ventas
	,@usuario = usuario
	,@password = [password]
FROM 
	evoluware_usuarios
WHERE
	idu = @idu

--------------------------------------------------------------------------------
-- EFECTUAR PAGOS Y APLICACIONES ###############################################

DECLARE cur_pagos CURSOR FOR
	SELECT
		vtp.idr
		,vtp.idmov
		,vtp.idtran2
		,vtp.idforma
		,vtp.subtotal
		,[impuesto1]=ROUND((vtp.total * v.impuesto1) / v.total,2) --vtp.impuesto1
		,vtp.total
		,vtp.comentario
		,vtp.forma_referencia
	FROM 
		ew_ven_transacciones_pagos vtp
		LEFT JOIN ew_ven_transacciones v ON v.idtran=vtp.idtran		
	WHERE
		vtp.idtran = @idtran
		AND vtp.aplicado = 0
		AND vtp.consecutivo > 0

OPEN cur_pagos

FETCH NEXT FROM cur_pagos INTO
	@idr
	, @idmov
	, @idtran2
	, @idforma
	, @subtotal
	, @impuesto1
	, @total
	, @comentario
	, @pago_referencia

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @subtotal = @total - @impuesto1

	IF @idforma = -1
	BEGIN
		IF @idtran2 = 0
		BEGIN
			CLOSE cur_pagos
			DEALLOCATE cur_pagos
			
			SELECT @error = 1
			SELECT @error_mensaje = 'Error: No se indicó transacción a aplicar.'
			BREAK
		END
		
		SELECT 
			@consecutivo = MAX(consecutivo)
		FROM 
			ew_cxc_transacciones_mov
		WHERE
			idtran = @idtran2
		
		SELECT @consecutivo = (ISNULL(@consecutivo, 0) + 1)
		
		INSERT INTO ew_cxc_transacciones_mov (
			idtran
			, consecutivo
			, idtran2
			, fecha
			, importe
			, importe2
			, impuesto1
			, idu
			, comentario
		)
		VALUES (
			@idtran2
			, @consecutivo
			, @idtran
			, @fecha
			, @total
			, @total
			, @impuesto1
			, @idu
			, @comentario
		)
		
		EXEC _cxc_prc_aplicarTransaccion @idtran2, @fecha, @idu
		
		IF @@ERROR <> 0
		BEGIN
			CLOSE cur_pagos
			DEALLOCATE cur_pagos
			
			SELECT @error = 1
			SELECT @error_mensaje = 'Error: Ocurrió un error al aplicar saldo.'
			BREAK
		END
	END
		ELSE
	BEGIN
		SELECT @pago_idtran = 0
		
		IF @fecha IS NULL
		BEGIN
			CLOSE cur_pagos
			DEALLOCATE cur_pagos
			
			SELECT @error = 1
			SELECT @error_mensaje = 'Error: Hay un error con las fechas.'
			BREAK
		END
		
		SELECT @sql = '	
		INSERT INTO ew_cxc_transacciones (
			idtran
			,fecha
			,folio
			,transaccion
			,idcliente
			,tipo
			,idsucursal
			,idu
			,subtotal
			,impuesto1
			,comentario
			,idconcepto
			,vencimiento
			,idforma
			,idmoneda
			,tipocambio
			,idimpuesto1
			,idimpuesto1_valor
			,programado
			,programado_fecha
			,saldo
			,referencia
			,idcuenta
		)
		VALUES (
			{idtran}
			,''' + CONVERT(VARCHAR(8), @fecha, 3) + '''
			,''{folio}''
			,''BDC2''
			,' + CONVERT(VARCHAR(20), @idcliente) + '
			,2
			,' + CONVERT(VARCHAR(20), @idsucursal) + '
			,' + CONVERT(VARCHAR(20), @idu) + '
			,' + CONVERT(VARCHAR(20), @subtotal) + '
			,' + CONVERT(VARCHAR(20), @impuesto1) + '
			,''' + @comentario + '''
			,10
			,''' + CONVERT(VARCHAR(8), @fecha, 3) + '''
			,' + CONVERT(VARCHAR(20), @idforma) + '
			,' + CONVERT(VARCHAR(2), @idmoneda) + '
			,' + CONVERT(VARCHAR(8), @tipocambio) + '
			,' + CONVERT(VARCHAR(2), @idimpuesto1) + '
			,' + CONVERT(VARCHAR(8), @idimpuesto1_valor) + '
			,0
			,''' + CONVERT(VARCHAR(8), @fecha, 3) + '''
			,' + CONVERT(VARCHAR(20), @total) + '
			,''' + @referencia + '''
			,' + CONVERT(VARCHAR(20), @idcuenta) + '
		)

		INSERT INTO ew_cxc_transacciones_mov (
			idtran
			,consecutivo
			,idtran2
			,fecha
			,importe
			,importe2
			,impuesto1
			,idu
			,comentario
		)
		VALUES (
			{idtran}
			,1
			,' + CONVERT(VARCHAR(20), @idtran) + '
			,''' + CONVERT(VARCHAR(8), @fecha, 3) + '''
			,' + CONVERT(VARCHAR(20), @total) + '
			,' + CONVERT(VARCHAR(20), @total) + '
			,' + CONVERT(VARCHAR(20), @impuesto1) + '
			,' + CONVERT(VARCHAR(20), @idu) + '
			,''' + @comentario + '''
		)
	
		INSERT INTO ew_ban_transacciones (
			idtran
			,idtran2
			,idcuenta
			,tipo
			,idsucursal
			,transaccion
			,folio
			,fecha
			,idforma
			,automatico
			,idu
			,comentario
			,idconcepto
			,referencia
			,idrelacion
			,identidad
			,tipocambio
			,programado
			,programado_fecha
			,subtotal
			,impuesto
			,importe
		
		)
		VALUES 
		(
			{idtran}
			,' + CONVERT(VARCHAR(20), @idtran) + '
			,' + CONVERT(VARCHAR(20), @idcuenta) + '
			,1
			,' + CONVERT(VARCHAR(20), @idsucursal) + '
			,''BDC2''
			,''{folio}''
			,''' + CONVERT(VARCHAR(8), @fecha, 3) + '''
			,' + CONVERT(VARCHAR(20), @idforma) + '
			,1
			,' + CONVERT(VARCHAR(20), @idu) + '
			,''' + @comentario + '''
			,10
			,''' + @referencia + '''
			,4
			,' + CONVERT(VARCHAR(20), @idcliente) + '
			,' + CONVERT(VARCHAR(8), @tipocambio) + '
			,0
			,''' + CONVERT(VARCHAR(8), @fecha, 3) + '''
			,' + CONVERT(VARCHAR(20), @subtotal) + '
			,' + CONVERT(VARCHAR(20), @impuesto1) + '
			,' + CONVERT(VARCHAR(20), @subtotal+ @impuesto1) + '		
		)
		INSERT INTO ew_ban_transacciones_mov (
			idtran
			,consecutivo
			,idmov2
			,importe
			,comentario
		)
		VALUES (
			{idtran}
			,1
			,' + CONVERT(VARCHAR(20), @idmov) + '
			,' + CONVERT(VARCHAR(20), @total) + '
			,''' + @comentario + '''
		)'

		IF @sql IS NULL OR @sql = ''
		BEGIN
			CLOSE cur_pagos
			DEALLOCATE cur_pagos

			SELECT @error = 1
			SELECT @error_mensaje = 'Error: No se pudo crear pago de cliente.'

			BREAK
		END
		
		EXEC _sys_prc_insertarTransaccion 
			@usuario
			,@password
			,'BDC2' --transaccion
			,@idsucursal
			,'A' --serie
			,@sql
			,5 --foliolen
			,@pago_idtran OUTPUT
			,'' --afolio
			,@fecha --afecha
		
		IF @pago_idtran IS NULL OR @pago_idtran = 0
		BEGIN
			CLOSE cur_pagos
			DEALLOCATE cur_pagos
			
			SELECT @error = 1
			SELECT @error_mensaje = 'Error: No se pudo crear pago de cliente.'
			BREAK
		END
		
		EXEC _ct_prc_contabilizarBDC2 @pago_idtran
	END
	
	-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	-- EVITAMOS LA DUPLICIDAD DEL PAGO
	-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	UPDATE ew_ven_transacciones_pagos SET aplicado=1 WHERE idr=@idr

	FETCH NEXT FROM cur_pagos INTO
		@idr
		, @idmov
		, @idtran2
		, @idforma
		, @subtotal
		, @impuesto1
		, @total
		, @comentario
		, @pago_referencia
END
--------------------------------------------------------------------------------
-- PRESENTAR MENSAJES ##########################################################

IF @error = 1
BEGIN
	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

CLOSE cur_pagos
DEALLOCATE cur_pagos
GO
