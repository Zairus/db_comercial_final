USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- modificado: Arvin Valenzuela 2010 MAR
-- Create date: 20091102
-- Description:	Procesar devolución de compras.
-- =============================================
ALTER PROCEDURE [dbo].[_com_prc_devolucionProcesar]
	@idtran AS BIGINT
	,@debug AS BIT = 0
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACION DE VARIABLES ####################################################

DECLARE
	@idsucursal AS SMALLINT
	,@idu AS SMALLINT

DECLARE
	@sql AS VARCHAR(2000)
	,@salida_idtran AS BIGINT
	,@usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)
	,@fecha AS SMALLDATETIME

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

SELECT
	@idsucursal = idsucursal
	,@idu = idu
	,@fecha = fecha
FROM 
	ew_com_transacciones
WHERE
	idtran = @idtran

SELECT
	@usuario = usuario
	,@password = password
FROM ew_usuarios
WHERE
	idu = @idu

--------------------------------------------------------------------------------
-- CREAR SALIDA DE ALMACEN #####################################################

SELECT
	@sql = 'INSERT INTO ew_inv_transacciones
	(idtran, idtran2, idsucursal, idalmacen, fecha, folio, transaccion,
	referencia, comentario, idconcepto)
SELECT
	{idtran}, idtran, idsucursal, idalmacen, fecha, ''{folio}'', ''GDA1'',
	''CDE1 - '' + folio, comentario, 17
FROM ew_com_transacciones
WHERE
	idtran = ' + CONVERT(VARCHAR(20), @idtran) + '

INSERT INTO ew_inv_transacciones_mov
	(idtran, idmov2, consecutivo, tipo, idalmacen,
	idarticulo, series, lote, fecha_caducidad, idum,
	cantidad, afectainv, comentario)
SELECT
	[idtran] = {idtran}
	,[idmov2] = idr
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY idr)
	,[tipo] = 2
	,[idlamacen] = idalmacen
	,[idarticulo] = idarticulo
	,[series] = series
	,[lote] = ''''
	,[fecha_caducidad] = ''''
	,[idum] = idum
	,[cantidad] = cantidad_devuelta
	,[afectainv] = 1
	,[comentario] = comentario
FROM ew_com_transacciones_mov
WHERE
	cantidad_devuelta > 0
	AND idtran = ' + CONVERT(VARCHAR(20), @idtran)

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
-- ACTUALIZAR CANTIDADES DEVUELTAS DE OC #######################################

INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	,idmov2
	,campo
	,valor
)
SELECT 
	idmov
	,idmov2
	,[campo] = 'cantidad_devuelta'
	,cantidad_devuelta
FROM 
	ew_com_transacciones_mov
WHERE 
	idtran = @idtran
	
EXEC _cxp_prc_aplicarTransaccion @idtran, @fecha, @idu

EXEC _ct_prc_contabilizarCDE1 @idtran, @debug
GO
