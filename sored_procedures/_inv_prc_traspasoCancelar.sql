USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091016
-- Description:	Cancelar traspaso entre almacenes
-- =============================================
ALTER PROCEDURE [dbo].[_inv_prc_traspasoCancelar]
	@idtran AS BIGINT
	,@fechacancelado AS SMALLDATETIME
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACION DE VARIABLES ####################################################

DECLARE
	@idsucursal_origen AS SMALLINT
	,@idsucursal_destino aS SMALLINT
	,@idalmacen_origen AS SMALLINT
	,@idalmacen_destino AS SMALLINT
	,@idu AS SMALLINT

DECLARE
	@sql AS VARCHAR(2000)
	,@entrada_idtran AS BIGINT
	,@salida_idtran AS BIGINT
	,@entrada_cancelacion_idtran AS BIGINT
	,@salida_cancelacion_idtran AS BIGINT
	,@usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

SELECT
	@idsucursal_origen = idsucursal
	,@idsucursal_destino = idsucursal_destino
	,@idalmacen_origen = idalmacen
	,@idalmacen_destino = idalmacen_destino
	,@idu = idu
FROM 
	ew_inv_documentos
WHERE
	idtran = @idtran

SELECT
	@salida_idtran = it.idtran
FROM 
	ew_inv_transacciones AS it
WHERE
	it.transaccion = 'GDA1'
	AND it.idtran2 = @idtran

SELECT
	@entrada_idtran = it.idtran
FROM ew_inv_transacciones AS it
WHERE
	it.transaccion = 'GDC1'
	AND it.idtran2 = @idtran

SELECT
	@usuario = usuario
	,@password = password
FROM ew_usuarios
WHERE
	idu = @idu

--------------------------------------------------------------------------------
-- SALIDA DEL ALMACEN DE DESITNO ###############################################

SELECT
	@sql = 'INSERT INTO ew_inv_transacciones (
	idtran
	, idtran2
	, idsucursal
	, idalmacen
	, fecha
	, folio
	, transaccion
	, referencia
	, comentario
)
SELECT
	{idtran}
	, [idtran2] = ' + CONVERT(VARCHAR(20), @idtran) + '
	, idsucursal
	, idalmacen
	, fecha
	, {folio}
	, ''GDA1''
	, referencia
	, comentario
FROM 
	ew_inv_transacciones
WHERE
	idtran = ' + CONVERT(VARCHAR(20), @entrada_idtran) + '

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
	{idtran}
	,[idmov2] = itm.idr
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY itm.idr)
	,[tipo] = 2
	,[idalmacen] = ' + CONVERT(VARCHAR(20), @idalmacen_destino) + '
	,itm.idarticulo
	,itm.series
	,itm.lote
	,itm.fecha_caducidad
	,itm.idum
	,itm.cantidad
	,[afectainv] = 1
	,itm.comentario
FROM 
	ew_inv_transacciones_mov AS itm
WHERE
	itm.idtran = ' + CONVERT(VARCHAR(20), @entrada_idtran)

IF @sql IS NULL OR @sql = ''
BEGIN
	RAISERROR('No se pudo obtener información para registrar salida del destino.', 16, 1)
	RETURN
END

EXEC _sys_prc_insertarTransaccion
	@usuario
	,@password
	,'GDA1' --Transacción
	,@idsucursal_destino
	,'A' --Serie
	,@sql
	,6 --Longitod del folio
	,@entrada_cancelacion_idtran OUTPUT
	,'' --Afolio
	,'' --Afecha

IF @entrada_cancelacion_idtran IS NULL OR @entrada_cancelacion_idtran = 0
BEGIN
	RAISERROR('No se pudo crear salida del destino.', 16, 1)
	RETURN
END

SELECT @sql = ''

--------------------------------------------------------------------------------
-- ENTRADA AL ALMACEN DE ORIGEN ################################################

SELECT
	@sql = 'INSERT INTO ew_inv_transacciones (
	idtran
	, idtran2
	, idsucursal
	, idalmacen
	, fecha
	, folio
	, transaccion
	, referencia
	, comentario
)
SELECT
	{idtran}
	, [idtran2] = ' + CONVERT(VARCHAR(20), @idtran) + '
	, idsucursal
	, idalmacen
	, fecha
	, {folio}
	, ''GDC1''
	, referencia
	, comentario
FROM 
	ew_inv_transacciones
WHERE
	idtran = ' + CONVERT(VARCHAR(20), @salida_idtran) + '

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
	, costo
	, afectainv
	, comentario
)
SELECT
	{idtran}
	,[idmov2] = itm.idr
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY itm.idr)
	,[tipo] = 1
	,[idalmacen] = ' + CONVERT(VARCHAR(20), @idalmacen_origen) + '
	,itm.idarticulo
	,itm.series
	,itm.lote
	,itm.fecha_caducidad
	,itm.idum
	,itm.cantidad
	,itm.costo
	,[afectainv] = 1
	,itm.comentario
FROM 
	ew_inv_transacciones_mov AS itm
WHERE
	itm.idtran = ' + CONVERT(VARCHAR(20), @salida_idtran)

IF @sql IS NULL OR @sql = ''
BEGIN
	RAISERROR('No se pudo obtener información para registrar entrada al origen.', 16, 1)
	RETURN
END

EXEC _sys_prc_insertarTransaccion
	@usuario
	,@password
	,'GDC1' --Transacción
	,@idsucursal_origen
	,'A' --Serie
	,@sql
	,6 --Longitod del folio
	,@salida_cancelacion_idtran OUTPUT
	,'' --Afolio
	,'' --Afecha

IF @salida_cancelacion_idtran IS NULL OR @salida_cancelacion_idtran = 0
BEGIN
	RAISERROR('No se pudo crear entrada al origen.', 16, 1)
	RETURN
END

--------------------------------------------------------------------------------
-- CANCELAR DOCUMENTO ##########################################################

UPDATE ew_inv_transacciones SET
	cancelado = 1
	,fechacancelado = @fechacancelado
WHERE
	idtran = @idtran
GO
