USE db_comercial_final
GO
IF OBJECT_ID('_ven_prc_facturaCancelar') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_prc_facturaCancelar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110224
-- Description:	Cancelar factura de venta
-- =============================================
CREATE PROCEDURE [dbo].[_ven_prc_facturaCancelar]
	@idtran AS BIGINT
	, @fecha AS SMALLDATETIME
	, @idu AS SMALLINT
	, @password AS VARCHAR(20)
	, @confirmacion AS BIT = 0
AS

SET NOCOUNT ON

DECLARE
	@idtran2 AS BIGINT
	, @idtran_inv AS BIGINT
	, @usuario AS VARCHAR(20)
	, @sql AS VARCHAR(4000)
	, @msg AS VARCHAR(250)
	, @transaccion AS VARCHAR(5)
	, @folio AS VARCHAR(15)
	, @comentario2 AS VARCHAR(250)
	, @codalm AS SMALLINT
	, @surtir AS SMALLINT

	, @total AS DECIMAL(18,6)
	, @saldo AS DECIMAL(18,6)
	, @tipocambio AS DECIMAL(18,6)
	, @fecha_factura AS DATETIME
	, @credito AS BIT

DECLARE
	@error_mensaje AS VARCHAR(1000)

SELECT 
	@usuario = usuario 
FROM 
	ew_usuarios 
WHERE 
	idu = @idu

SELECT 
	@transaccion = transaccion
	, @folio = folio
	, @codalm = idalmacen 
	, @fecha_factura = fecha
	, @credito = credito
FROM 
	ew_ven_transacciones 
WHERE 
	idtran = @idtran

SELECT
	@total = total
	, @tipocambio = tipocambio
	, @saldo = saldo
FROM
	ew_cxc_transacciones
WHERE
	idtran = @idtran

EXEC [dbo].[_sys_prc_usuarioPuedeCancelar] @idu, @transaccion

IF @confirmacion = 0
BEGIN
	IF (DATEDIFF (hour,@fecha_factura,GETDATE()) > 72 AND (@total*@tipocambio) > 5000)
	BEGIN
		SELECT
			@error_mensaje = 'Error: No se pueden cancelar facturas cuya fecha de emisión sea mayor a 72 horas con respecto al dia de cancelación y el importe no debe ser mayor a $5000.00 MXN.'

		RAISERROR(@error_mensaje, 16, 1)
		RETURN
	END
END

IF @credito = 0 AND MONTH(@fecha) <> MONTH(@fecha_factura)
BEGIN
	RAISERROR('Error: No se puede cancelar factura de periodos anteriores.', 16, 1)
	RETURN
END

IF @credito = 0 AND @fecha_factura < CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), GETDATE(), 3))
BEGIN
	RAISERROR('Error: No se pueden cancelar facturas de contado de dias anteriores.', 16, 1)
	RETURN
END

IF ABS(@total - @saldo) > 0.01
BEGIN
	RAISERROR('Error: No se pueden cancelar facturas con aplicaciones de saldo.', 16, 1)
	RETURN
END

SELECT @surtir = [dbo].[fn_sys_parametro]('VEN_SURFAC')

-- cancelamos el cargo en CXC
EXEC [dbo].[_cxc_prc_cancelarTransaccion] @idtran, @fecha, @idu

--------------------------------------------------------------------
-- Afectamos el inventario
--------------------------------------------------------------------
IF @surtir = 1
BEGIN
	EXEC [dbo].[_ven_prc_facturaSurtir] @idtran, 1
END

--------------------------------------------------------------------
-- Reactivar Ordenes
--------------------------------------------------------------------
EXEC [dbo].[_ven_prc_facturaOrdenesReactivar] @idtran, @idu

UPDATE ew_cxc_transacciones SET 
	cancelado = 1
	, cancelado_fecha = @fecha
	, saldo = 0 
WHERE
	idtran = @idtran

UPDATE ew_ven_transacciones SET
	cancelado = 1
	, cancelado_fecha = @fecha
WHERE
	idtran = @idtran

IF @confirmacion = 1
BEGIN
	EXEC [dbo].[_sys_prc_transaccionCancelacionEstado] @idtran, @idu, @fecha
END

EXEC [dbo].[_ct_prc_transaccionCancelarContabilidad] @idtran, 3, @fecha, @idu
GO
