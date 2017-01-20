USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110224
-- Description:	Cancelar factura de venta
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_facturaVentaCancelar]
	 @idtran AS INT
	,@fecha AS DATETIME
	,@idu AS SMALLINT
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACION DE VARIABLES ####################################################

DECLARE
	 @tipo AS TINYINT
	,@idalmacen AS SMALLINT
	,@idconcepto AS INT
	,@inv_idtran AS INT
	,@fecha_factura AS DATETIME

DECLARE
	 @idcliente AS INT
	,@inventario_partes AS BIT

DECLARE
	 @idmoneda AS TINYINT
	,@importe AS DECIMAL(18,6)
	,@saldo AS DECIMAL(18,6)
	,@total AS DECIMAL(18,6)
	,@credito AS BIT

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

SELECT
	 @tipo = 1
	,@idalmacen = vt.idalmacen
	,@idconcepto = 1012
	,@idu = vt.idu
	,@idcliente = vt.idcliente
	,@inventario_partes = c.inventario_partes
	,@fecha_factura = vt.fecha

	,@total = ct.total
	,@saldo = ct.saldo

	,@credito = ct.credito
FROM
	ew_ven_transacciones AS vt
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = vt.idtran
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = vt.idcliente
WHERE
	vt.idtran = @idtran

SELECT
	 @idmoneda = idmoneda
	,@importe = (total * -1)
FROM
	ew_cxc_transacciones 
WHERE
	idtran = @idtran

IF (@saldo <> @total)
BEGIN
	RAISERROR('Error: No se puede cancelar documento con aplicaciones de saldo.', 16, 1)
	RETURN
END

IF MONTH(@fecha) <> MONTH(@fecha_factura)
BEGIN
	RAISERROR('Error: No se puede cancelar factura de periodos anteriores.', 16, 1)
	RETURN
END

IF @credito = 0 AND @fecha_factura < CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), GETDATE(), 3))
BEGIN
	RAISERROR('Error: No se pueden cancelar facturas de contado de dias anteriores.', 16, 1)
	RETURN
END

--------------------------------------------------------------------------------
-- AFECTAR CARTERA #############################################################

EXEC _cxc_prc_afectarCartera 
	 @idtran
	,@idtran
	,1
	,@idconcepto
	,@idcliente
	,@fecha
	,@idmoneda
	,@importe
	,@idu

--------------------------------------------------------------------------------
-- EFECTUAR ENTRADA A ALMACEN ##################################################

EXEC _inv_prc_transaccionCrear
	 @idtran
	,@fecha
	,@tipo
	,@idalmacen
	,@idconcepto
	,@idu
	,@inv_idtran OUTPUT

INSERT INTO ew_inv_transacciones_mov (
	 idtran
	,idmov2
	,consecutivo
	,tipo
	,idalmacen
	,idarticulo
	,series
	,lote
	,fecha_caducidad
	,idum
	,cantidad
	,costo
	,afectainv
	,comentario
)
SELECT
	 [idtran] = @inv_idtran
	,[idmov2] = vtm.idmov
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY vtm.idr)
	,[tipo] = @tipo
	,[idalmacen] = @idalmacen
	,vtm.idarticulo
	,vtm.series
	,[lote] = ''
	,[fecha_caducidad] = NULL
	,vtm.idum
	,[cantidad] = vtm.cantidad_facturada
	,vtm.costo
	,[afectainv] = 1
	,vtm.comentario
FROM
	ew_ven_transacciones_mov AS vtm
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vtm.idarticulo
WHERE
	a.inventariable = 1
	AND vtm.idtran = @idtran

--------------------------------------------------------------------------------
-- ACTUALIZAR INVENTARIO DE CLIENTE ############################################

IF @inventario_partes = 1
BEGIN
	UPDATE ci SET
		ci.cantidad = (ci.cantidad - vtm.cantidad_facturada)
	FROM
		ew_ven_transacciones_mov AS vtm
		LEFT JOIN ew_ven_transacciones AS vt
			ON vt.idtran = vtm.idtran
		LEFT JOIN ew_clientes_inventario AS ci
			ON ci.idcliente = vt.idcliente
			AND ci.idarticulo = vtm.idarticulo
	WHERE
		vtm.idtran = @idtran
END

--------------------------------------------------------------------------------
-- CANCELAR PAGOS ##############################################################

--EXEC _ven_prc_facturaPagosCancelar @idtran, @fecha, @idu

--------------------------------------------------------------------------------
-- CONTABILIZAR CANCELACIÓN DE VENTA ###########################################

EXEC _ct_prc_transaccionCancelarContabilidad @idtran, 3, @fecha, @idu

--------------------------------------------------------------------------------
-- CANCELAR DOCUMENTO ##########################################################

UPDATE ew_ven_transacciones SET
	 cancelado = 1
	,cancelado_fecha = @fecha
WHERE
	idtran = @idtran

UPDATE ew_cxc_transacciones SET
	 cancelado = 1
	,cancelado_fecha = @fecha
WHERE
	idtran = @idtran
GO
