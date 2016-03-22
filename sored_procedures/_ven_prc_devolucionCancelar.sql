USE [db_comercial_final]
GO
-- ======================================================
-- Author:		Tere Valdez
-- Create date: 20091210
-- Description:	Cancelar Devolución de Mercancía (Ventas)
-- Modificacion: Arvin 2011 quitar las tablas rel y cancelar CXC
-- ======================================================
ALTER PROCEDURE [dbo].[_ven_prc_devolucionCancelar]
	@idtran AS BIGINT
	,@cancelado_fecha AS SMALLDATETIME
	,@idu AS SMALLINT
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACION DE VARIABLES ####################################################

DECLARE
	@idsucursal AS SMALLINT

DECLARE
	@sql AS VARCHAR(2000)
	,@salida_idtran AS BIGINT
	,@usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

SELECT
	@idsucursal = idsucursal
	,@idu = idu
FROM 
	ew_ven_transacciones 
WHERE
	idtran = @idtran

SELECT
	@usuario = usuario
	,@password = [password]
FROM 
	ew_usuarios
WHERE
	idu = @idu

-- cancelamos el cargo en CXC
EXEC _cxc_prc_cancelarTransaccion @idtran, @cancelado_fecha, @idu

--------------------------------------------------------------------------------
-- CREAR SALIDA A ALMACEN #####################################################

SELECT
	@sql = '
INSERT INTO ew_inv_transacciones (
	idtran
	, idtran2
	, idsucursal
	, idalmacen
	, fecha
	, folio
	, transaccion
	, referencia
	, comentario
	, idconcepto
)
SELECT
	[idtran] = {idtran}
	, idtran
	, idsucursal
	, idalmacen
	, fecha
	, [folio] = ''{folio}''
	, [transaccion] = ''GDA1''
	, [referencia] = ''GDC2 - '' + folio
	, comentario
	, [idconcepto] = 19
FROM 
	ew_ven_transacciones
WHERE
	idtran = ' + CONVERT(VARCHAR(20), @idtran) + '

INSERT INTO ew_inv_transacciones_mov (
	idtran
	, idtran2
	, idmov2
	, consecutivo
	, tipo
	, idalmacen
	, idarticulo
	, series
	, lote
	, fecha_caducidad
	, idcapa
	, idum
	, cantidad
	, afectainv
	, comentario
)
SELECT
	[idtran] = {idtran}
	,[idtran2] = m.idtran
	,[idmov2] = m.idmov
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY m.idr)
	,[tipo] = 2
	,[idalmacen] = m.idalmacen
	,[idarticulo] = m.idarticulo
	,[series] = m.series
	,[lote] = ic.lote
	,[fecha_caducidad] = ic.fecha_caducidad
	,[idcapa] = m.idcapa
	,[idum] = m.idum
	,[cantidad] = m.cantidad
	,[afectainv] = 1
	,[comentario] = m.comentario
FROM 
	ew_ven_transacciones_mov m
	LEFT JOIN ew_articulos a ON a.idarticulo=m.idarticulo
	LEFT JOIN ew_inv_capas ic ON m.idcapa = ic.idcapa AND m.idarticulo = ic.idarticulo
	LEFT JOIN ew_cat_unidadesmedida um ON m.idum = um.idum
WHERE
	m.cantidad > 0
	AND m.idtran = ' + CONVERT(VARCHAR(20), @idtran) 

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
-- ACTUALIZAR CANTIDADES RECIBIDAS DE OV #######################################

INSERT INTO ew_sys_movimientos_acumula 
	(idmov1,idmov2,campo,valor)
SELECT 
	m.idmov,m.idmov2,'cantidad_devuelta',m.cantidad * (-1)
FROM	
	ew_ven_transacciones_mov m
	LEFT JOIN ew_articulos a ON a.idarticulo=m.idarticulo
WHERE 
	idtran = @idtran

--------------------------------------------------------------------------------
-- CANCELAR DOCUMENTO ##########################################################

UPDATE ew_ven_transacciones SET 
	cancelado = 1
	,cancelado_fecha = @cancelado_fecha
WHERE
	idtran = @idtran

UPDATE ew_cxc_transacciones SET 
	cancelado = '1'
	,cancelado_fecha = @cancelado_fecha
	,saldo = 0 
WHERE 
	idtran = @idtran

UPDATE ew_ven_transacciones SET 
	cancelado = '1'
	,cancelado_fecha = @cancelado_fecha 
WHERE 
	idtran = @idtran
GO
