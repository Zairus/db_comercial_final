USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110505
-- Description:	Recibir pedido de sucursal
-- =============================================
ALTER PROCEDURE [dbo].[_inv_prc_pedidoRecibir]
	 @idtran AS INT
	,@idu AS SMALLINT
	,@password AS VARCHAR(20)
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACION DE VARIABLES ####################################################

DECLARE
	 @idsucursal_origen AS SMALLINT
	,@idsucursal_destino aS SMALLINT
	,@idalmacen_origen AS SMALLINT
	,@idalmacen_destino AS SMALLINT

DECLARE
	@usuario AS VARCHAR(20)

DECLARE
	 @sql AS VARCHAR(2000)
	,@entrada_idtran AS BIGINT
	,@entrada_costo AS DECIMAL(18,6)
	,@salida_idtran AS BIGINT
	,@salida_costo AS DECIMAL(18,6)
	,@gastos AS DECIMAL(18,6)

	,@total_surtido AS DECIMAL(18,6)
	,@total_cantidad AS DECIMAL(18,6)

DECLARE
	 @registros AS INT
	,@error_mensaje AS VARCHAR(100)

--------------------------------------------------------------------------------
-- VALIDAR CONTRASEÑA ##########################################################

SELECT
	@registros = COUNT(*)
FROM
	evoluware_usuarios
WHERE
	idu = @idu
	AND [password] = @password
/*
IF @registros = 0
BEGIN
	SELECT @error_mensaje = 'Error: La contraseña es incorrecta.'
	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END
*/
--------------------------------------------------------------------------------
-- VALIDAR REGISTROS ###########################################################

SELECT
	@total_surtido = SUM(surtido)
	,@total_cantidad = SUM(cantidad)
FROM
	ew_inv_documentos_mov AS idm
WHERE
	idm.idtran = @idtran

SELECT
	@registros = COUNT(*)
FROM
	ew_inv_documentos_mov
WHERE
	cantidad <> solicitado
	AND idtran = @idtran

IF @registros > 0
BEGIN
	SELECT @error_mensaje = 'Error: No se esta recibiendo el total del pedido.'
	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

IF ABS(@total_surtido - @total_cantidad) > 0.01
BEGIN
	RAISERROR('Errir: Lo recibido no es igual a lo enviado.', 16, 1)
	RETURN
END

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

SELECT
	 @idsucursal_origen = idsucursal
	,@idsucursal_destino = idsucursal_destino
	,@idalmacen_origen = idalmacen
	,@idalmacen_destino = idalmacen_destino
FROM 
	ew_inv_documentos
WHERE
	idtran = @idtran

SELECT
	 @usuario = usuario
	,@password = [password]
FROM
	evoluware_usuarios
WHERE
	idu = @idu

IF @idalmacen_origen = @idalmacen_destino
BEGIN
	RAISERROR('Error: Los almacenes de origen y destino deben ser diferentes.', 16, 1)
	RETURN
END

--------------------------------------------------------------------------------
-- SALIDA DEL ALMACEN DE ORIGEN ################################################

SELECT
	@sql = 'INSERT INTO ew_inv_transacciones (
	 idtran
	,idtran2
	,idsucursal
	,idalmacen
	,fecha
	,folio
	,transaccion
	,idconcepto
	,referencia
	,comentario
)
SELECT
	 [idtran] = {idtran}
	,[idtran2] = idtran
	,idsucursal
	,idalmacen
	,fecha
	,[folio] = ''{folio}''
	,[transaccion] = ''GDA1''
	,[idconcepto] = 34
	,[referencia] = transaccion + '' - '' + folio
	,comentario
FROM 
	ew_inv_documentos
WHERE
	idtran = ' + CONVERT(VARCHAR(20), @idtran) + '

INSERT INTO ew_inv_transacciones_mov (
	 idtran
	,idmov2
	,consecutivo
	,tipo
	,idalmacen
	,idarticulo
	,idcapa
	,series
	,lote
	,fecha_caducidad
	,idum
	,cantidad
	,afectainv
	,comentario
)
SELECT
	 [idtran] = {idtran}
	,[idmov2] = idm.idmov
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY idm.idr)
	,[tipo] = 2
	,[idalmacen] = ' + CONVERT(VARCHAR(20), @idalmacen_origen) + '
	,idm.idarticulo
	,[idcapa] = (
		CASE idm.series
			WHEN '''' THEN 0
			ELSE (
				SELECT TOP 1
					ic.idcapa
				FROM 
					ew_inv_capas AS ic
				WHERE
					ic. serie = idm.series
			)
		END
	)
	,idm.series
	,idm.lote
	,idm.fecha_caducidad
	,idm.idum
	,idm.cantidad
	,[afectainv] = 1
	,idm.comentario
FROM 
	ew_inv_documentos_mov AS idm
WHERE
	idm.idtran = ' + CONVERT(VARCHAR(20), @idtran)

IF @sql IS NULL OR @sql = ''
BEGIN
	RAISERROR('No se pudo obtener información para registrar salida del origen.', 16, 1)
	RETURN
END

EXEC _sys_prc_insertarTransaccion
	 @usuario
	,@password
	,'GDA1' --Transacción
	,@idsucursal_origen
	,'A' --Serie
	,@sql
	,6 --Longitod del folio
	,@salida_idtran OUTPUT
	,'' --Afolio
	,'' --Afecha

IF @salida_idtran IS NULL OR @salida_idtran = 0
BEGIN
	RAISERROR('No se pudo crear salida del origen.', 16, 1)
	RETURN
END

SELECT @sql = ''

--------------------------------------------------------------------------------
-- ACTUALIZAR COSTO EN EL TRASPASO #############################################

SELECT
	@salida_costo = SUM(itm.costo)
FROM
	ew_inv_transacciones_mov AS itm
WHERE
	itm.idtran = @salida_idtran

UPDATE ew_inv_transacciones SET
	total = @salida_costo
WHERE
	idtran = @salida_idtran

UPDATE trasd SET
	trasd.costo = sald.costo
FROM 
	ew_inv_documentos_mov AS trasd
	LEFT JOIN ew_inv_transacciones_mov AS sald
		ON sald.idmov2 = trasd.idmov
		AND sald.tipo = 2
WHERE
	trasd.idtran = @idtran

UPDATE ew_inv_documentos SET
	 costo = @salida_costo
	,total = (gastos + @salida_costo)
WHERE
	idtran = @idtran

UPDATE idm SET
	idm.gastos = ((idm.costo / id.costo) * id.gastos)
FROM
	ew_inv_documentos_mov AS idm
	LEFT JOIN ew_inv_documentos AS id
		ON id.idtran = idm.idtran
WHERE
	id.costo > 0
	AND idm.idtran = @idtran

--------------------------------------------------------------------------------
-- ENTRADA AL ALMACEN DE DESTINO ###############################################

SELECT
	@sql = 'INSERT INTO ew_inv_transacciones (
	 idtran
	,idtran2
	,idsucursal
	,idalmacen
	,fecha
	,folio
	,transaccion
	,idconcepto
	,referencia
	,total
	,comentario
)
SELECT
	 [idtran] = {idtran}
	,[idtran2] = idtran
	,[idsucursal] = idsucursal_destino
	,[idalmacen] = idalmacen_destino
	,fecha
	,[folio] = ''{folio}''
	,[transaccion] = ''GDC1''
	,[idconcepto] = 34
	,[referencia] = transaccion + '' - '' + folio
	,total
	,comentario
FROM 
	ew_inv_documentos
WHERE
	idtran = ' + CONVERT(VARCHAR(20), @idtran) + '

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
	 [idtran] = {idtran}
	,[idmov2] = itm.idmov2
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY itm.idr)
	,[tipo] = 1
	,[idalmacen] = ' + CONVERT(VARCHAR(20), @idalmacen_destino) + '
	,itm.idarticulo
	,itm.series
	,itm.lote
	,itm.fecha_caducidad
	,itm.idum
	,itm.cantidad
	,[costo] = (itm.costo + itm.gastos)
	,[afectainv] = 1
	,itm.comentario
FROM 
	ew_inv_documentos_mov AS itm
WHERE
	itm.idtran = ' + CONVERT(VARCHAR(20), @idtran)

IF @sql IS NULL OR @sql = ''
BEGIN
	RAISERROR('No se pudo obtener información para registrar entrada al destino.', 16, 1)
	RETURN
END

EXEC _sys_prc_insertarTransaccion
	 @usuario
	,@password
	,'GDC1' --Transacción
	,@idsucursal_destino
	,'A' --Serie
	,@sql
	,6 --Longitod del folio
	,@entrada_idtran OUTPUT
	,'' --Afolio
	,'' --Afecha

IF @entrada_idtran IS NULL OR @entrada_idtran = 0
BEGIN
	RAISERROR('No se pudo crear entrada al destino.', 16, 1)
	RETURN
END

--------------------------------------------------------------------------------
-- VALIDAR COSTOS DE SALIDA Y ENTRADA ##########################################

SELECT
	@entrada_costo = SUM(itm.costo)
FROM
	ew_inv_transacciones_mov AS itm
WHERE
	itm.idtran = @entrada_idtran

SELECT
	@gastos = SUM(idm.gastos)
FROM
	ew_inv_documentos_mov AS idm
WHERE
	idm.idtran = @idtran

IF ABS((@salida_costo + @gastos) - @entrada_costo) > 1.00
BEGIN
	SELECT @error_mensaje = 'Error: El costo de salida [' + LTRIM(RTRIM(STR(@salida_costo + @gastos))) + '] y el costo de entrada [' + LTRIM(RTRIM(STR(@entrada_costo))) + '] no corresponden.'
	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

--------------------------------------------------------------------------------
-- ACTUALIZAR ESTADO ###########################################################

--EXEC _inv_prc_pedidoContabilizar @idtran

INSERT INTO ew_sys_transacciones2
	(idtran, idestado, idu)
VALUES
	(@idtran, 43, @idu)
GO
