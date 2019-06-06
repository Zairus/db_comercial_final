USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20100106
-- Description:	Cancelar remisión de venta
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_remisionCancelar]
	@idtran AS INT
	, @cancelado_fecha AS SMALLDATETIME
	, @idu AS SMALLINT
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACION DE VARIABLES ####################################################

DECLARE
	@idsucursal AS SMALLINT

DECLARE
	@sql AS VARCHAR(2000)
	, @entrada_idtran AS BIGINT
	, @usuario AS VARCHAR(20)
	, @password AS VARCHAR(20)

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

SELECT
	@idsucursal = idsucursal
FROM 
	ew_inv_transacciones
WHERE
	idtran = @idtran

SELECT
	@usuario = usuario
	, @password = password
FROM 
	ew_usuarios
WHERE
	idu = @idu

--------------------------------------------------------------------------------
-- CREAR ENTRADA A ALMACEN #####################################################

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
	, total
	, comentario
	, idconcepto
)
SELECT
	[idtran] = {idtran}
	, [idtran2] = idtran
	, [idsucursal] = idsucursal
	, [idalmacen] = idalmacen
	, [fecha] = fecha
	, [folio] = ''{folio}''
	, [transaccion] = ''GDC1''
	, [referencia] = ''ERE1 - '' + folio
	, [total] = total
	, [comentario] = ''CANCELAR SURTIDO DE MERCANCIA A CLIENTE''
	, [idconcepto] = 1021
FROM 
	ew_inv_transacciones
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
	, costo
	, afectainv
	, comentario
)
SELECT
	[idtran] = {idtran}
	, [idmov2] = idmov2
	, [consecutivo] = ROW_NUMBER() OVER (ORDER BY idr)
	, [tipo] = 1
	, [idlamacen] = idalmacen
	, [idarticulo] = idarticulo
	, [series] = series
	, [lote] = ''''
	, [fecha_caducidad] = ''''
	, [idum] = idum
	, [cantidad] = cantidad
	, [costo] = costo
	, [afectainv] = 1
	, [comentario] = comentario
FROM 
	ew_inv_transacciones_mov
WHERE
	cantidad > 0
	AND idtran = ' + CONVERT(VARCHAR(20), @idtran)

IF @sql IS NULL OR @sql = ''
BEGIN
	RAISERROR('No se pudo obtener información para registrar entrada.', 16, 1)
	RETURN
END

EXEC _sys_prc_insertarTransaccion
	@usuario
	, @password
	, 'GDC1' --Transacción
	, @idsucursal
	, 'A' --Serie
	, @sql
	, 6 --Longitod del folio
	, @entrada_idtran OUTPUT
	, '' --Afolio
	, '' --Afecha

IF @entrada_idtran IS NULL OR @entrada_idtran = 0
BEGIN
	RAISERROR('No se pudo crear entrada a almacén.', 16, 1)
	RETURN
END

--------------------------------------------------------------------------------
-- ACTUALIZAR CANTIDADES SURTIDAS EN ORDEN #####################################

INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	, idmov2
	, campo
	, valor
)
SELECT
	[idmov1] = idmov
	, [idmov2] = idmov2
	, [campo] = 'cantidad_surtida'
	, [valor] = (cantidad * (-1))
FROM
	ew_inv_transacciones_mov
WHERE 
	idtran = @idtran

--------------------------------------------------------------------------------
-- REACTIVAR ORDEN DE VENTA Y CAMBIAR SU ESTATUS A AUTORIZADA###################

DECLARE @idtran2 INT

DECLARE cur_detalle1 CURSOR FOR
	SELECT DISTINCT 
		[idtran] = FLOOR(fm.idmov2)
	FROM
		ew_inv_transacciones_mov AS fm 
	WHERE
		fm.idtran = @idtran
		AND fm.cantidad > 0

OPEN cur_detalle1

FETCH NEXT FROM cur_detalle1 INTO 
	@idtran2

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC _ven_prc_ordenEstado @idtran2, @idu

	FETCH NEXT FROM cur_detalle1 INTO 
		@idtran2
END

CLOSE cur_detalle1
DEALLOCATE cur_detalle1

--------------------------------------------------------------------------------
-- CANCELAR DOCUMENTO ##########################################################
UPDATE ew_inv_transacciones SET 
	cancelado = 1
	, fechacancelado = GETDATE() 
WHERE 
	idtran = @idtran
GO
