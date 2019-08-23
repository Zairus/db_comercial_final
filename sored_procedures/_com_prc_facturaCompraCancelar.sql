USE db_comercial_final
GO
IF OBJECT_ID('_com_prc_facturaCompraCancelar') IS NOT NULL
BEGIN
	DROP PROCEDURE _com_prc_facturaCompraCancelar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110429
-- Description:	Cancelar factura de compra
-- =============================================
CREATE PROCEDURE [dbo].[_com_prc_facturaCompraCancelar]
	@idtran AS INT
	, @fecha AS SMALLDATETIME
	, @idu AS SMALLINT
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACION DE VARIABLES ####################################################

DECLARE
	@idsucursal AS SMALLINT

DECLARE
	@sql AS VARCHAR(2000)
	, @salida_idtran AS BIGINT
	, @usuario AS VARCHAR(20)
	, @password AS VARCHAR(20)
	, @total AS DECIMAL(18,6)
	, @saldo AS DECIMAL(18,6)

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

SELECT
	@idsucursal = idsucursal
	, @idu = idu
	, @total = total
	, @saldo = saldo
FROM 
	ew_cxp_transacciones
WHERE
	idtran = @idtran

SELECT
	@usuario = usuario
	, @password = password
FROM 
	ew_usuarios
WHERE
	idu = @idu

IF ABS(@saldo - @total) > 0.01
BEGIN
	RAISERROR('Error: La factura tiene pagos, cancelar primero los pagos.', 16, 1)
	RETURN
END

--------------------------------------------------------------------------------
-- CREAR SALIDA DE ALMACEN #####################################################

SELECT
	@sql = 'INSERT INTO ew_inv_transacciones (
	idtran
	, idtran2
	, idsucursal
	, idalmacen
	, fecha
	, folio
	, transaccion
	, idconcepto
	, referencia
	, comentario
)
SELECT
	[idtran] = {idtran}
	, [idtran2] = idtran
	, [idsucursal] = idsucursal
	, [idalmacen] = idalmacen
	, [fecha] = fecha
	, [folio] = ''{folio}''
	, [transaccion] = ''GDA1''
	, [idconcepto] = 16 + 1000
	, [referencia] = ''CCRE1 - '' + folio
	,[comentario] = comentario
FROM 
	ew_com_transacciones
WHERE
	idtran = ' + CONVERT(VARCHAR(20), @idtran) + '

INSERT INTO ew_inv_transacciones_mov (
	idtran
	, idmov2
	, consecutivo
	, tipo
	, idalmacen
	, idarticulo
	, series
	, lote
	, fecha_caducidad
	, idum
	, cantidad
	, afectainv
	, comentario
)
SELECT
	[idtran] = {idtran}
	, [idmov2] = ctm.idmov
	, [consecutivo] = ROW_NUMBER() OVER (ORDER BY ctm.idr)
	, [tipo] = 2
	, [idlamacen] = ISNULL(NULLIF(ctm.idalmacen, 0), ct.idalmacen)
	, [idarticulo] = ctm.idarticulo
	, [series] = ctm.series
	, [lote] = ''''
	, [fecha_caducidad] = ''''
	, [idum] = a.idum_almacen
	, [cantidad] = (ctm.cantidad_facturada * ISNULL(auf.factor, 1))
	, [afectainv] = 1
	, [comentario] = ctm.comentario
FROM 
	ew_com_transacciones_mov AS ctm
	LEFT JOIN ew_com_transacciones AS ct
		ON ct.idtran = ctm.idtran
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = ctm.idarticulo
	LEFT JOIN ew_articulos_unidades_factores AS auf
		ON auf.idum_base = a.idum_compra
		AND auf.idum_producto = a.idum_almacen
WHERE
	ctm.cantidad_facturada > 0
	AND ctm.idtran = ' + CONVERT(VARCHAR(20), @idtran)

IF @sql IS NULL OR @sql = ''
BEGIN
	RAISERROR('No se pudo obtener información para registrar salida.', 16, 1)
	RETURN
END

EXEC _sys_prc_insertarTransaccion
	 @usuario
	,@password
	,'GDA1' --Transacción
	,@idsucursal
	,'A' --Serie
	,@sql
	,6 --Longitod del folio
	,@salida_idtran OUTPUT
	,'' --Afolio
	,'' --Afecha

IF @salida_idtran IS NULL OR @salida_idtran = 0
BEGIN
	RAISERROR('No se pudo crear salida de almacén.', 16, 1)
	RETURN
END

--------------------------------------------------------------------------------
-- ACTUALIZAR COSTO DE LA DEVOLUCIÓN POR LA CANCELACIÓN ########################

UPDATE ctm SET
	ctm.costo_devolucion = itm.costo
FROM
	ew_com_transacciones_mov AS ctm
	LEFT JOIN ew_inv_transacciones_mov AS itm
		ON itm.idmov2 = ctm.idmov
WHERE
	itm.tipo = 2
	AND ctm.idtran = @idtran

UPDATE ct SET
	ct.costo_devolucion = (
		SELECT
			SUM(ctm.costo_devolucion)
		FROM
			ew_com_transacciones_mov AS ctm
		WHERE
			ctm.idtran = ct.idtran
	)
FROM
	ew_com_transacciones AS ct
WHERE
	ct.idtran = @idtran

--------------------------------------------------------------------------------
-- CANCELAR DOCUMENTO ##########################################################

UPDATE ew_com_transacciones SET 
	 cancelado = 1
	,cancelado_fecha = @fecha
WHERE
	idtran = @idtran

UPDATE ew_cxp_transacciones SET 
	 cancelado = 1
	,cancelado_fecha = @fecha
WHERE
	idtran = @idtran
GO
