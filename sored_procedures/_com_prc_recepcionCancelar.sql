USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091102
-- Description:	Cancelar recepción de mercancía.
-- =============================================
ALTER PROCEDURE [dbo].[_com_prc_recepcionCancelar]
	@idtran AS BIGINT
	,@cancelado_fecha AS SMALLDATETIME
	,@idu AS SMALLINT

	,@cancelado AS BIT = 1
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
FROM ew_com_transacciones
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
	@sql = 'INSERT INTO ew_inv_transacciones (
	idtran
	, idtran2
	, idsucursal
	, idalmacen
	, fecha
	, folio
	, transaccion
	, referencia
	, idconcepto
	, comentario
)
SELECT
	{idtran}
	, idtran
	, idsucursal
	, idalmacen
	, fecha
	, ''{folio}''
	, ''GDA1''
	, ''CCRE1 - '' + folio
	, 1016
	, comentario
FROM 
	ew_com_transacciones
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
	, idum
	, cantidad
	, afectainv
	, comentario
)
SELECT
	[idtran] = {idtran}
	,[idtran2] = idtran
	,[idmov2] = idmov
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY ew_com_transacciones_mov.idr)
	,[tipo] = 2
	,[idlamacen] = idalmacen
	,[idarticulo] = ew_com_transacciones_mov.idarticulo
	,[series] = ew_com_transacciones_mov.series
	,[lote] = ''''
	,[fecha_caducidad] = ''''
	,[idum] = ew_com_transacciones_mov.idum
	,[cantidad] = cantidad_recibida*um.factor
	,[afectainv] = 1
	,[comentario] = ew_com_transacciones_mov.comentario
FROM 
	ew_com_transacciones_mov
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = ew_com_transacciones_mov.idarticulo
	LEFT JOIN ew_cat_unidadesmedida AS um 
		ON a.idum_compra = um.idum
WHERE
	cantidad_recibida > 0
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
-- ACTUALIZAR CANTIDADES RECIBIDAS DE OC #######################################

INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	,idmov2
	,campo
	,valor
)
SELECT 
	idmov
	,idmov2
	,[campo] = 'cantidad_surtida'
	,[valor] = ISNULL(cantidad_recibida, 0) * (-1)
FROM 
	ew_com_transacciones_mov
WHERE 
	idtran = @idtran

--------------------------------------------------------------------------------
-- CANCELAR DOCUMENTO ##########################################################

UPDATE ew_com_transacciones SET 
	cancelado = @cancelado
	,cancelado_fecha = (CASE WHEN @cancelado = 1 THEN @cancelado_fecha ELSE NULL END)
WHERE
	idtran = @idtran

IF @cancelado = 1
BEGIN
	UPDATE ew_sys_transacciones SET idestado = 255 WHERE idtran = @idtran
END

--------------------------------------------------------------------------------
-- CAMBIAR ESTATUS A AUTORIZADA DE LA ORDEN DE COMPRA #######################################

IF @cancelado = 1
BEGIN
	INSERT INTO ew_sys_transacciones2 (
		idtran
		,idestado
		,fechahora
		,idu
		,host
		,comentario
	)
	SELECT DISTINCT
		[idtran] = ctm.idtran2
		,[idestado] = 3
		,[fechahora] = GETDATE()
		,[idu] = @idu
		,[host] = dbo.fnHost()
		,[comentario] = 'SE CANCELÓ LA RECEPCION DE SUMINISTROS. PONER EN AUTORIZADO LA ORDEN DE COMPRA.'
	FROM 
		ew_com_transacciones_mov AS ctm
	WHERE 
		ctm.idtran = @idtran

	EXEC _ct_prc_transaccionCancelarContabilidad @idtran, 3, @cancelado_fecha, @idu
END
GO
