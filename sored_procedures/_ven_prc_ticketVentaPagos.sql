USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150624
-- Description:	Pagos en ticket de venta
ALTER PROCEDURE [dbo].[_ven_prc_ticketVentaPagos]
	@idtran AS INT
	,@idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@total1 AS DECIMAL(18,6)
	,@total2 AS DECIMAL(18,6)

DECLARE
	@usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)
	,@transaccion AS VARCHAR(5) = 'BDC2'
	,@idsucursal AS SMALLINT
	,@serie AS VARCHAR(3) = 'A'
	,@sql AS VARCHAR(4000) = ''
	,@foliolen AS TINYINT = 6
	,@pago1_idtran AS INT
	,@pago2_idtran AS INT
	,@ticket_total AS DECIMAL(18,6)
	,@pago_importe AS DECIMAL(18,6)
	,@idforma AS INT
	,@referencia AS VARCHAR(50)
	,@idturno AS INT
	,@idcuenta AS INT
	
SELECT
	@total1 = vtp.total
	,@total2 = vtp.total2
FROM
	ew_ven_transacciones_pagos AS vtp
WHERE
	vtp.idtran = @idtran

SELECT
	@usuario = u.usuario
	,@password = u.[password]
	,@idsucursal = ct.idsucursal
	,@ticket_total = ct.total
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN evoluware_usuarios AS u
		ON u.idu = ct.idu
WHERE
	ct.idtran = @idtran

SELECT @idturno = dbo.fn_sys_turnoActual(@idu)

IF @idturno IS NULL
BEGIN
	RAISERROR('Error: No se cuenta con turno iniciado.', 16, 1)
	RETURN
END

SELECT
	@idcuenta = idcuenta
FROM
	ew_sys_turnos
WHERE
	idturno = @idturno

IF @total1 <> 0
BEGIN
	SELECT @pago_importe = (CASE WHEN @total1 > @ticket_total THEN @ticket_total ELSE @total1 END)

	SELECT
		@idforma = idforma
		,@referencia = forma_referencia
	FROM
		ew_ven_transacciones_pagos
	WHERE
		idtran = @idtran

	IF @idforma > 1 AND @referencia = ''
	BEGIN
		RAISERROR('Error: Debe indicar referencia para forma de pago 1', 16, 1)
		RETURN
	END

	EXEC _sys_prc_insertarTransaccion
		@usuario
		,@password
		,@transaccion
		,@idsucursal
		,@serie
		,@sql
		,@foliolen
		,@pago1_idtran OUTPUT
	
	INSERT INTO ew_cxc_transacciones (
		idtran
		,idtran2
		,idconcepto
		,idsucursal
		,fecha
		,transaccion
		,folio
		,referencia
		,tipo
		,idcliente
		,idfacturacion
		,idforma
		,idmoneda
		,tipocambio
		,idimpuesto1
		,idimpuesto1_valor
		,subtotal
		,impuesto1
		,idu
		,comentario
	)
	SELECT
		[idtran] = @pago1_idtran
		,[idtran2] = ct.idtran
		,[idconcepto] = 10
		,[idsucursal] = ct.idsucursal
		,[fecha] = ct.fecha
		,[transaccion] = @transaccion
		,[folio] = (SELECT st.folio FROM ew_sys_transacciones AS st WHERE st.idtran = @pago1_idtran)
		,[referencia] = vtp.forma_referencia
		,[tipo] = 2
		,[idcliente] = ct.idcliente
		,[idfacturacion] = ct.idfacturacion
		,[idforma] = vtp.idforma
		,[idmoneda] = ct.idmoneda
		,[tipocambio] = ct.tipocambio
		,[idimpuesto1] = ct.idimpuesto1
		,[idimpuesto1_valor] = ct.idimpuesto1_valor
		,[subtotal] = (@pago_importe / (1 + (ct.impuesto1 / ct.subtotal)))
		,[impuesto1] = @pago_importe - (@pago_importe / (1 + (ct.impuesto1 / ct.subtotal)))
		,[idu] = ct.idu
		,[comentario] = ct.comentario
	FROM
		ew_ven_transacciones_pagos AS vtp
		LEFT JOIN ew_cxc_transacciones AS ct
			ON ct.idtran = vtp.idtran
	WHERE
		vtp.total <> 0
		AND vtp.idforma <> 0
		AND vtp.idtran = @idtran
		
	INSERT INTO ew_cxc_transacciones_mov (
		idtran
		,consecutivo
		,idtran2
		,fecha
		,tipocambio
		,importe
		,importe2
		,impuesto1
		,idu
		,comentario
	)
	SELECT
		[idtran] = @pago1_idtran
		,[consecutivo] = ROW_NUMBER() OVER (ORDER BY vtp.idr)
		,[idtran2] = vtp.idtran
		,[fecha] = ct.fecha
		,[tipocambio] = 1
		,[importe] = @pago_importe
		,[importe2] = @pago_importe
		,[impuesto1] = @pago_importe - (@pago_importe / (1 + (ct.impuesto1 / ct.subtotal)))
		,[idu] = ct.idu
		,[comentario] = ct.comentario
	FROM
		ew_ven_transacciones_pagos AS vtp
		LEFT JOIN ew_cxc_transacciones AS ct
			ON ct.idtran = vtp.idtran
	WHERE
		vtp.idtran = @idtran

	INSERT INTO ew_ban_transacciones (
		idtran
		,idtran2
		,idmov2
		,transaccion
		,fecha
		,folio
		,idconcepto
		,idcuenta
		,idsucursal
		,referencia
		,tipo
		,importe
		,iva
		,subtotal
		,impuesto
		,tipocambio
		,idforma
		,forma_referencia
		,forma_moneda
		,forma_fecha
		,automatico
		,idu
		,comentario
		,idmoneda
	)
	SELECT
		[idtran] = @pago1_idtran
		,[idtran2] = ct.idtran
		,[idmov2] = vtp.idmov
		,[transaccion] = @transaccion
		,[fecha] = ct.fecha
		,[folio] = (SELECT st.folio FROM ew_sys_transacciones AS st WHERE st.idtran = @pago1_idtran)
		,[idconcepto] = 0
		,[idcuenta] = @idcuenta
		,[idsucursal] = ct.idsucursal
		,[referencia] = vtp.forma_referencia
		,[tipo] = 1
		,[importe] = @pago_importe
		,[iva] = 16
		,[subtotal] = (@pago_importe / (1 + (ct.impuesto1 / ct.subtotal)))
		,[impuesto] = @pago_importe - (@pago_importe / (1 + (ct.impuesto1 / ct.subtotal)))
		,[tipocambio] = 1
		,[idforma] = vtp.idforma
		,[forma_referencia] = vtp.forma_referencia
		,[forma_moneda] = vtp.forma_moneda
		,[forma_fecha] = vtp.forma_fecha
		,[automatico] = 1
		,[idu] = ct.idu
		,[comentario] = vtp.comentario
		,[idmoneda] = 0
	FROM
		ew_ven_transacciones_pagos AS vtp
		LEFT JOIN ew_cxc_transacciones AS ct
			ON ct.idtran = vtp.idtran
	WHERE
		vtp.idtran = @idtran
		
	EXEC _ct_prc_contabilizarBDC2 @pago1_idtran

	UPDATE ew_ven_transacciones_pagos SEt
		idtran2 = @pago1_idtran
	WHERE
		idtran = @idtran
END

IF @total2 <> 0 AND @total1 < @ticket_total
BEGIN
	SELECT @pago_importe = (CASE WHEN @total2 > (@ticket_total - @total1) THEN (@ticket_total - @total1) ELSE @total2 END)

	SELECT
		@idforma = idforma2
		,@referencia = forma_referencia2
	FROM
		ew_ven_transacciones_pagos
	WHERE
		idtran = @idtran

	IF @idforma > 1 AND @referencia = ''
	BEGIN
		RAISERROR('Error: Debe indicar referencia para forma de pago 2', 16, 1)
		RETURN
	END

	EXEC _sys_prc_insertarTransaccion
		@usuario
		,@password
		,@transaccion
		,@idsucursal
		,@serie
		,@sql
		,@foliolen
		,@pago2_idtran OUTPUT

	INSERT INTO ew_cxc_transacciones (
		idtran
		,idtran2
		,idconcepto
		,idsucursal
		,fecha
		,transaccion
		,folio
		,referencia
		,tipo
		,idcliente
		,idfacturacion
		,idforma
		,idmoneda
		,tipocambio
		,idimpuesto1
		,idimpuesto1_valor
		,subtotal
		,impuesto1
		,idu
		,comentario
	)
	SELECT
		[idtran] = @pago2_idtran
		,[idtran2] = ct.idtran
		,[idconcepto] = 10
		,[idsucursal] = ct.idsucursal
		,[fecha] = ct.fecha
		,[transaccion] = @transaccion
		,[folio] = (SELECT st.folio FROM ew_sys_transacciones AS st WHERE st.idtran = @pago2_idtran)
		,[referencia] = vtp.forma_referencia2
		,[tipo] = 2
		,[idcliente] = ct.idcliente
		,[idfacturacion] = ct.idfacturacion
		,[idforma] = vtp.idforma
		,[idmoneda] = ct.idmoneda
		,[tipocambio] = ct.tipocambio
		,[idimpuesto1] = ct.idimpuesto1
		,[idimpuesto1_valor] = ct.idimpuesto1_valor
		,[subtotal] = (@pago_importe / (1 + (ct.impuesto1 / ct.subtotal)))
		,[impuesto1] = @pago_importe - (@pago_importe / (1 + (ct.impuesto1 / ct.subtotal)))
		,[idu] = ct.idu
		,[comentario] = ct.comentario
	FROM
		ew_ven_transacciones_pagos AS vtp
		LEFT JOIN ew_cxc_transacciones AS ct
			ON ct.idtran = vtp.idtran
	WHERE
		vtp.total <> 0
		AND vtp.idforma <> 0
		AND vtp.idtran = @idtran

	INSERT INTO ew_cxc_transacciones_mov (
		idtran
		,consecutivo
		,idtran2
		,fecha
		,tipocambio
		,importe
		,importe2
		,impuesto1
		,idu
		,comentario
	)
	SELECT
		[idtran] = @pago2_idtran
		,[consecutivo] = ROW_NUMBER() OVER (ORDER BY vtp.idr)
		,[idtran2] = vtp.idtran
		,[fecha] = ct.fecha
		,[tipocambio] = 1
		,[importe] = @pago_importe
		,[importe2] = @pago_importe
		,[impuesto1] = @pago_importe - (@pago_importe / (1 + (ct.impuesto1 / ct.subtotal)))
		,[idu] = ct.idu
		,[comentario] = ct.comentario
	FROM
		ew_ven_transacciones_pagos AS vtp
		LEFT JOIN ew_cxc_transacciones AS ct
			ON ct.idtran = vtp.idtran
	WHERE
		vtp.idtran = @idtran

	INSERT INTO ew_ban_transacciones (
		idtran
		,idtran2
		,idmov2
		,transaccion
		,fecha
		,folio
		,idconcepto
		,idcuenta
		,idsucursal
		,referencia
		,tipo
		,importe
		,iva
		,subtotal
		,impuesto
		,tipocambio
		,idforma
		,forma_referencia
		,forma_moneda
		,forma_fecha
		,automatico
		,idu
		,comentario
		,idmoneda
	)
	SELECT
		[idtran] = @pago2_idtran
		,[idtran2] = ct.idtran
		,[idmov2] = vtp.idmov
		,[transaccion] = @transaccion
		,[fecha] = ct.fecha
		,[folio] = (SELECT st.folio FROM ew_sys_transacciones AS st WHERE st.idtran = @pago2_idtran)
		,[idconcepto] = 0
		,[idcuenta] = @idcuenta
		,[idsucursal] = ct.idsucursal
		,[referencia] = vtp.forma_referencia2
		,[tipo] = 1
		,[importe] = @pago_importe
		,[iva] = 16
		,[subtotal] = (@pago_importe / (1 + (ct.impuesto1 / ct.subtotal)))
		,[impuesto] = @pago_importe - (@pago_importe / (1 + (ct.impuesto1 / ct.subtotal)))
		,[tipocambio] = 1
		,[idforma] = vtp.idforma2
		,[forma_referencia] = vtp.forma_referencia2
		,[forma_moneda] = vtp.forma_moneda
		,[forma_fecha] = vtp.forma_fecha
		,[automatico] = 1
		,[idu] = ct.idu
		,[comentario] = vtp.comentario
		,[idmoneda] = 0
	FROM
		ew_ven_transacciones_pagos AS vtp
		LEFT JOIN ew_cxc_transacciones AS ct
			ON ct.idtran = vtp.idtran
	WHERE
		vtp.idtran = @idtran

	EXEC _ct_prc_contabilizarBDC2 @pago2_idtran

	UPDATE ew_ven_transacciones_pagos SEt
		idtran_pago2 = @pago2_idtran
	WHERE
		idtran = @idtran
END
GO
