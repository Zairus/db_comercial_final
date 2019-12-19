USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150624
-- Description:	Procesa ticket de venta
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_ticketVentaProcesar]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@credito AS BIT
	, @pago_total AS DECIMAL(18,6)
	, @total AS DECIMAL(18,6)
	, @idu AS INT
	, @idturno AS INT
	, @pago_en_caja AS BIT
	, @error_mensaje AS VARCHAR(1000)
	, @idtran2 AS INT

SELECT
	@credito = ct.credito
	, @total = ct.total
	, @idu = idu
FROM
	ew_cxc_transacciones AS ct
WHERE
	ct.idtran = @idtran

SELECT
	@pago_total = (vtp.total + vtp.total2)
FROM
	ew_ven_transacciones_pagos AS vtp
WHERE
	vtp.idtran = @idtran

SELECT @idturno = dbo.fn_sys_turnoActual(@idu)
SELECT @pago_en_caja = CONVERT(BIT, valor) FROM objetos_datos WHERE grupo = 'GLOBAL' AND codigo = 'PAGO_EN_CAJA'

IF @idturno IS NULL AND @pago_en_caja = 0
bEGIN
	RAISERROR('Error: El usuario no ha iniciado turno.', 16, 1)
	RETURN
END

IF @credito = 0 AND @pago_total < @total AND @pago_en_caja = 0
BEGIN
	RAISERROR('Error: Ticket de contado debe ser pagado totalmente.', 16, 1)
	RETURN
END

IF @credito = 1 AND @pago_total >= @total
BEGIN
	UPDATE ew_cxc_transacciones SET
		credito = 0
	WHERE
		idtran = @idtran
END

IF EXISTS (
	SELECT * 
	FROM 
		ew_ven_transacciones_mov_datos AS vtmd
		LEFT JOIN ew_articulos_datos AS ad
			ON ad.idarticulo = vtmd.idarticulo
			AND ad.iddato = vtmd.iddato
	WHERE
		ad.obligatorio = 1
		AND LEN(vtmd.valor) = 0
		AND vtmd.idtran = @idtran
)
BEGIN
	SELECT TOP 1
		@error_mensaje = (
			'Debe indicar valor para el campo: ['
			+sd.nombre
			+'], del producto: '
			+a.nombre
		)
	FROM 
		ew_ven_transacciones_mov_datos AS vtmd
		LEFT JOIN ew_articulos_datos AS ad
			ON ad.idarticulo = vtmd.idarticulo
			AND ad.iddato = vtmd.iddato
		LEFT JOIN ew_sys_datos AS sd
			ON sd.iddato = ad.iddato
		LEFT JOIN ew_articulos AS a
			ON a.idarticulo = vtmd.idarticulo
	WHERE
		ad.obligatorio = 1
		AND LEN(vtmd.valor) = 0
		AND vtmd.idtran = @idtran

	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

--Surtir
IF EXISTS(
	SELECT *
	FROM
		ew_ven_transacciones_mov AS vtm
		LEFT JOIN ew_articulos AS a
			ON a.idarticulo = vtm.idarticulo
	WHERE
		a.inventariable = 1
		AND vtm.idtran = @idtran
)
BEGIN
	EXEC [dbo].[_ven_prc_ticketVentaSurtir] @idtran
END

--Pagar
IF (
	@pago_total > 0 
	AND EXISTS(
		SELECT * 
		FROM 
			ew_ven_transacciones_pagos 
		WHERE 
			consecutivo = 0 
			AND (
				total > 0
				OR total2 > 0
			)
			AND idtran = @idtran
	)
)
BEGIN
	EXEC [dbo].[_ven_prc_ticketVentaPagos] @idtran, @idu
END

EXEC _ven_prc_facturaPagos @idtran

EXEC [dbo].[_ct_prc_polizaAplicarDeConfiguracion] @idtran, 'EFA6', @idtran

IF EXISTS(
	SELECT * 
	FROM 
		ew_ven_comprobacion_ventas 
	WHERE 
		ABS(total_documento - total_detalle) > 0.01 
		AND idtran = @idtran
)
BEGIN
	SELECT
		@error_mensaje = (
			ISNULL(@error_mensaje, '')
			+ CHAR(13)
			+ 'Error: El total de la venta no coincide con la suma de sus partidas.'
		)

	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

SELECT [costo] = ISNULL(SUM(costo),0) FROM ew_ven_transacciones_mov WHERE idtran = @idtran

INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	, idmov2
	, campo
	, valor
)
SELECT 
	[idmov] = m.idmov
	, [idmov2] = m.idmov2
	, [campo] = 'cantidad_surtida'
	, [valor] = m.cantidad_surtida
FROM	
	ew_ven_transacciones_mov AS m
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = m.idarticulo
WHERE 
	m.cantidad_surtida > 0
	AND a.inventariable = 1
	AND idtran = @idtran

INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	, idmov2
	, campo
	, valor
)
SELECT 
	[idmov] = idmov
	, [idmov2] = idmov2
	, [campo] = 'cantidad_facturada'
	, [valor] = cantidad_facturada 
FROM	
	ew_ven_transacciones_mov
WHERE 
	cantidad_facturada > 0
	AND idtran = @idtran

INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	, idmov2
	, campo
	, valor
)
SELECT 
	[idmov] = idmov
	, [idmov2] = idmov2
	, [campo] = 'cantidad_surtida'
	, [valor] = cantidad_facturada 
FROM	
	ew_ven_transacciones_mov
WHERE 
	cantidad_facturada > 0
	AND idtran = @idtran

DECLARE cur_detalle CURSOR FOR
	SELECT DISTINCT 
		[idtran] = FLOOR(vtm.idmov2)
	FROM
		ew_ven_transacciones_mov AS vtm
	WHERE
		vtm.idtran = @idtran
		AND vtm.cantidad_facturada > 0

OPEN cur_detalle

FETCH NEXT FROM cur_detalle INTO
	@idtran2

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC _ven_prc_ordenEstado @idtran2, @idu
	
	FETCH NEXT FROM cur_detalle INTO 
		@idtran2
END

CLOSE cur_detalle
DEALLOCATE cur_detalle
GO
