USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge 
-- Create date: 20170113
-- Description:	Procesar ficha de deposito por pago de cliente
-- =============================================
ALTER PROCEDURE [dbo].[_ban_prc_depositoProcesar]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@usuario AS VARCHAR(50)
	,@password AS VARCHAR(50)
	,@transaccion AS VARCHAR(5) = 'BDC2'
	,@idsucursal AS INT
	,@serie AS VARCHAR(1) = 'A'
	,@sql AS VARCHAR(MAX) = ''
	,@foliolen AS INT = 6
	,@pago_idtran AS INT
	,@afolio AS VARCHAR(50) = ''
	,@afecha AS VARCHAR(50) = ''
	,@pago_folio AS VARCHAR(15)
	,@fecha AS SMALLDATETIME
	,@idu AS INT

DECLARE
	@idr AS INT

DECLARE
	 @error AS BIT
	,@error_mensaje AS VARCHAR(500)

SELECT
	@usuario = u.usuario
	,@password = u.[password]
	,@idsucursal = bt.idsucursal
	,@fecha = bt.fecha
	,@idu = bt.idu
	,@afecha = CONVERT(VARCHAR(8), bt.fecha, 3)
FROM
	ew_ban_transacciones AS bt
	LEFT JOIN evoluware_usuarios AS u
		ON u.idu = bt.idu
WHERE
	bt.idtran = @idtran

DECLARE cur_depositoPagos CURSOR FOR
	SELECT idr
	FROM
		ew_ban_transacciones_mov
	WHERE
		idtran = @idtran

OPEN cur_depositoPagos

FETCH NEXT FROM cur_depositoPagos INTO
	@idr

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @pago_idtran = NULL

	EXEC [dbo].[_sys_prc_insertarTransaccion]
		@usuario
		,@password
		,@transaccion
		,@idsucursal
		,@serie
		,@sql
		,@foliolen
		,@pago_idtran OUTPUT
		,@afolio
		,@afecha

	IF @pago_idtran IS NULL OR @pago_idtran = 0
	BEGIN
		CLOSE cur_depositoPagos
		DEALLOCATE cur_depositoPagos

		SELECT @error = 1
		SELECT @error_mensaje = 'Error: No se pudo crear pago de cliente.'
		BREAK
	END

	SELECT
		@pago_folio = folio
	FROM
		ew_sys_transacciones
	WHERE
		idtran = @pago_idtran

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
		,importe
		,idu
		,comentario
	)
	SELECT
		[idtran] = @pago_idtran
		,[idtran2] = @idtran
		,[idcuenta] = bt.idcuenta
		,[tipo] = 0
		,[idsucursal] = @idsucursal
		,[transaccion] = @transaccion
		,[folio] = @pago_folio
		,[fecha] = bt.fecha
		,[idforma] = bt.idforma
		,[automatico] = 0
		,[importe] = btm.importe
		,[idu] = bt.idu
		,[comentario] = 'De Deposito: ' + bt.folio + ', ' + CONVERT(VARCHAR(MAX), btm.comentario)
	FROM
		ew_ban_transacciones_mov AS btm
		LEFT JOIN ew_ban_transacciones AS bt
			ON bt.idtran = btm.idtran
	WHERE
		btm.idr = @idr
		
	INSERT INTO ew_ban_transacciones_mov (
		 idtran
		,consecutivo
		,idmov2
		,idconcepto
		,importe
		,comentario
	)
	SELECT
		[idtran] = @pago_idtran
		,[consecutivo] = 1
		,[idmov2] = btm.idmov
		,[idconcepto] = (SELECT a.idarticulo FROM ew_articulos AS a WHERE a.codigo = [dbo].[_sys_fnc_parametroTexto]('CXC_CONCEPTOPAGO'))
		,[importe] = btm.importe
		,[comentario] = btm.comentario
	FROM
		ew_ban_transacciones_mov AS btm
	WHERE
		btm.idr = @idr

	INSERT INTO ew_cxc_transacciones (
		 idtran
		,idtran2
		,fecha
		,folio
		,transaccion
		,idcliente
		,tipo
		,idsucursal
		,idu
		,idcuenta
		,idforma
		,subtotal
		,impuesto1
		,comentario
	)
	SELECT
		[idtran] = @pago_idtran
		,[idtran2] = @idtran
		,[fecha] = bt.fecha
		,[folio] = @pago_folio
		,[transaccion] = @transaccion
		,[idcliente] = btm.idconcepto
		,[tipo] = 2
		,[idsucursal] = @idsucursal
		,[idu] = bt.idu
		,[idcuenta] = bt.idcuenta
		,[idforma] = bt.idforma
		,[subtotal] = btm.importe / (1 + (CASE WHEN btm.idtran2 = 0 THEN ci.valor ELSE (f.impuesto1 / f.subtotal) END))
		,[impuesto1] = btm.importe - (btm.importe / (1 + (CASE WHEN btm.idtran2 = 0 THEN ci.valor ELSE (f.impuesto1 / f.subtotal) END)))
		,[comentario] = 'De Deposito: ' + bt.folio + ', ' + CONVERT(VARCHAR(MAX), btm.comentario)
	FROM
		ew_ban_transacciones_mov AS btm
		LEFT JOIN ew_ban_transacciones AS bt
			ON bt.idtran = btm.idtran
		LEFT JOIN ew_sys_sucursales AS s
			ON s.idsucursal = bt.idsucursal
		LEFT JOIN ew_cat_impuestos AS ci
			ON ci.idimpuesto = s.idimpuesto
		LEFT JOIN ew_cxc_transacciones As f
			ON f.idtran = btm.idtran2
	WHERE
		btm.idr = @idr
		
	IF EXISTS (
		SELECT * 
		FROM 
			ew_ban_transacciones_mov AS btm 
			LEFT JOIN ew_cxc_transacciones AS f 
				ON f.idtran = btm.idtran2 
		WHERE 
			f.saldo < btm.importe
			AND btm.idr = @idr
	)
	BEGIN
		SELECT
			@error_mensaje = (
				'Error: '
				+ 'Se intenta aplicar pago de mas al documento ['
				+ f.folio
				+ '], con saldo '
				+ CONVERT(VARCHAR(20), f.saldo)
				+ ', pago a aplicar: '
				+ CONVERT(VARCHAR(20), btm.importe)
			)
		FROM 
			ew_ban_transacciones_mov AS btm 
			LEFT JOIN ew_cxc_transacciones AS f 
				ON f.idtran = btm.idtran2 
		WHERE 
			f.saldo < btm.importe
			AND btm.idr = @idr

		CLOSE cur_depositoPagos
		DEALLOCATE cur_depositoPagos

		RAISERROR(@error_mensaje, 16, 1)
		RETURN
	END

	INSERT INTO ew_cxc_transacciones_mov (
		idtran
		,consecutivo
		,idtran2
		,importe
		,importe2
		,impuesto1
		,idu
		,comentario
	)
	SELECT
		[idtran] = @pago_idtran
		,[consecutivo] = 1
		,[idtran2] = btm.idtran2
		,[importe] = btm.importe
		,[importe2] = btm.importe
		,[impuesto1] = btm.importe - (btm.importe / (1 + (f.impuesto1 / f.subtotal)))
		,[idu] = bt.idu
		,[comentario] = 'De Deposito: ' + bt.folio + ', ' + CONVERT(VARCHAR(MAX), btm.comentario)
	FROM
		ew_ban_transacciones_mov AS btm
		LEFT JOIN ew_ban_transacciones AS bt
			ON bt.idtran = btm.idtran
		LEFT JOIN ew_cxc_transacciones As f
			ON f.idtran = btm.idtran2
	WHERE
		btm.idtran2 > 0
		AND btm.idr = @idr

	EXEC [dbo].[_cxc_prc_aplicarTransaccion] @pago_idtran, @fecha, @idu
	EXEC [dbo].[_ct_prc_polizaAplicarDeConfiguracion] @pago_idtran

	UPDATE ew_ban_transacciones_mov SET
		idmov2 = (
			SELECT ct.idmov 
			FROM ew_cxc_transacciones AS ct 
			WHERE ct.idtran = @pago_idtran
		)
	WHERE
		idr = @idr

	FETCH NEXT FROM cur_depositoPagos INTO
		@idr
END

CLOSE cur_depositoPagos
DEALLOCATE cur_depositoPagos

IF @error = 1
BEGIN
	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END
GO
