USE [db_comercial_final]
GO
ALTER PROCEDURE [dbo].[_ven_prc_facturaCancelar]
	@idtran AS BIGINT
	,@fecha AS SMALLDATETIME
	,@idu AS SMALLINT
	,@password AS VARCHAR(20)
AS

SET NOCOUNT ON

DECLARE
	@idtran2 AS BIGINT
	,@idtran_inv AS BIGINT
	,@usuario AS VARCHAR(20)
	,@sql AS VARCHAR(4000)
	,@msg AS VARCHAR(250)
	,@transaccion AS VARCHAR(5)
	,@folio AS VARCHAR(15)
	,@comentario2 AS VARCHAR(250)
	,@codalm AS SMALLINT
	,@surtir AS SMALLINT

	,@total AS DECIMAL(18,6)
	,@saldo AS DECIMAL(18,6)
	
SELECT 
	@usuario = usuario 
FROM 
	ew_usuarios 
WHERE idu = @idu

SELECT 
	@transaccion = transaccion
	, @folio = folio
	, @codalm = idalmacen 
FROM 
	ew_ven_transacciones 
WHERE 
	idtran = @idtran

SELECT
	@total = total
	,@saldo = saldo
FROM
	ew_cxc_transacciones
WHERE
	idtran = @idtran

IF ABS(@total - @saldo) > 0.01
BEGIN
	RAISERROR('Error: No se pueden cancelar facturas con aplicaciones de saldo.', 16, 1)
	RETURN
END

SELECT @surtir = dbo.fn_sys_parametro('VEN_SURFAC')

-- cancelamos el cargo en CXC
EXEC _cxc_prc_cancelarTransaccion @idtran, @fecha, @idu

--------------------------------------------------------------------
-- Afectamos el inventario
--------------------------------------------------------------------
IF @surtir = 1
BEGIN
	EXEC [dbo].[_ven_prc_facturaSurtir] @idtran, 1
END

--------------------------------------------------------------------
-- Reactivamos la mercancia surtida en la orden 
--------------------------------------------------------------------
INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	,idmov2
	,campo
	,valor
)
SELECT 
	m.idmov
	,m.idmov2
	,'cantidad_surtida'
	,m.cantidad_surtida * (-1)
FROM
	ew_ven_transacciones_mov m
	LEFT JOIN ew_articulos a 
		ON a.idarticulo = m.idarticulo
WHERE 
	idtran = @idtran
	AND m.cantidad_surtida != 0

--------------------------------------------------------------------
-- Reactivamos la mercancia facturada en la orden 
--------------------------------------------------------------------
INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	,idmov2
	,campo
	,valor
)
SELECT 
	idmov
	,idmov2
	,'cantidad_facturada'
	,cantidad_facturada  * (-1)
FROM
	ew_ven_transacciones_mov
WHERE 
	idtran = @idtran
	AND cantidad_facturada!=0

--------------------------------------------------------------------
-- Reabrimos los pedidos
--------------------------------------------------------------------
DECLARE cur_detalle1 CURSOR FOR
	SELECT DISTINCT 
		[idtran] = CONVERT(INT, FLOOR(fm.idmov2))
	FROM
		ew_ven_transacciones_mov fm 
	WHERE
		fm.cantidad_facturada > 0
		AND CONVERT(INT, FLOOR(fm.idmov2)) > 0
		AND fm.idtran = @idtran

OPEN cur_detalle1

FETCH NEXT FROM cur_detalle1 INTO @idtran2

WHILE @@fetch_status = 0
BEGIN
	EXEC _ven_prc_ordenEstado @idtran2, @idu

	FETCH NEXT FROM cur_detalle1 INTO @idtran2
END

CLOSE cur_detalle1
DEALLOCATE cur_detalle1

UPDATE ew_cxc_transacciones SET 
	cancelado = '1'
	, cancelado_fecha = @fecha
	, saldo = 0 
WHERE
	idtran = @idtran

UPDATE ew_ven_transacciones SET
	cancelado = '1'
	, cancelado_fecha = @fecha
WHERE
	idtran = @idtran
GO
