USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091016
-- Description:	Procesar traspaso entre almacenes
-- EXEC _inv_prc_traspasoProcesar 100013
-- =============================================
ALTER PROCEDURE [dbo].[_inv_prc_traspasoProcesar]
	@idtran AS INT
	,@idu AS INT = 0
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACION DE VARIABLES ####################################################

DECLARE
	@idsucursal_origen AS SMALLINT
	,@idsucursal_destino aS SMALLINT
	,@idalmacen_origen AS SMALLINT
	,@idalmacen_destino AS SMALLINT
	,@msg AS VARCHAR(100)

DECLARE
	@sql AS VARCHAR(max)
	,@entrada_idtran AS INT
	,@salida_idtran AS INT
	,@usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)
	,@idr AS INT
	,@idarticulo AS INT
	,@series AS VARCHAR(4000)
	,@lote AS VARCHAR(30)
	,@idcapa AS INT
	,@cantidad AS INT
	,@fecha_caducidad AS SMALLDATETIME

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
	@usuario = [usuario]
	,@password = [password]
FROM ew_usuarios
WHERE
	idu = @idu

IF @idalmacen_origen = @idalmacen_destino
BEGIN
	RAISERROR('Error: Los almacenes de origen y destino deben ser diferentes.', 16, 1)
	RETURN
END

--------------------------------------------------------------------------------
-- SALIDA DEL ALMACEN DE ORIGEN ################################################

SELECT @sql='INSERT INTO ew_inv_transacciones (
	idtran
	,idtran2
	,idsucursal
	,idalmacen
	,fecha
	,folio
	,transaccion
	,referencia
	,comentario
	,idconcepto
	,idu
)
SELECT
	{idtran}
	,idtran
	,idsucursal
	,idalmacen
	,fecha
	,[folio] = ''{folio}''
	,[transaccion] = ''GDA1''
	,referencia
	,comentario
	,idconcepto
	,' + CONVERT(VARCHAR(10),@idu) + '
FROM 
	ew_inv_documentos
WHERE
	idtran = ' + CONVERT(VARCHAR(20), @idtran)
	
--------------------------------------------------------------------------------
-- DECLARAR UNA TABLA TEMPORAL CON LAS CAMPOS NECESARIOS #######################
DECLARE @tmp_mov TABLE (
	idr INT
	,consecutivo SMALLINT IDENTITY 
	,idarticulo INT
	,serie VARCHAR(50)
	,idcapa INT
	,cantidad DECIMAL(15,4)
	,lote VARCHAR(30)
	,fecha_caducidad SMALLDATETIME
	,costo DECIMAL(15,4)
)

-- INSERTAR ARTICULOS QUE NO TIENEN NUMERO DE SERIE NI LOTE DE FABRICACION
INSERT INTO @tmp_mov (
	idr
	, idarticulo
	, serie
	, lote
	, idcapa
	, cantidad
	, costo
)
SELECT 
	idm.idr
	, idm.idarticulo
	, [serie] = ''
	, [lote] = ''
	, [idcapa] = 0
	, [cantidad] = idm.cantidad
	, [costo] = idm.costo
FROM
	ew_inv_documentos_mov AS idm
	LEFT JOIN ew_articulos AS a 
		ON idm.idarticulo = a.idarticulo
WHERE
	idm.idtran = @idtran 
	AND (
		a.series = 0 
		AND a.lotes = 0
	)

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

-- INSERTAR ARTICULOS IDENTIFICADOS CON NUMERO DE SERIE
DECLARE cur_mov CURSOR FOR
	SELECT 
		idr
		, idarticulo
		, series	
	FROM
		ew_inv_documentos_mov idm
	WHERE
		idm.idtran = @idtran
		AND LEN(idm.series) > 0

OPEN cur_mov

FETCH NEXT FROM cur_mov INTO 
	@idr
	, @idarticulo
	, @series

WHILE @@FETCH_STATUS = 0
BEGIN
	INSERT INTO @tmp_mov (
		idr
		, idarticulo
		, serie
		, idcapa
		, cantidad
		, costo
	)
	SELECT 
		@idr
		, @idarticulo
		, s.valor
		,  c.idcapa
		, [cantidad] = 1
		, ce.costo
	FROM 
		dbo.fn_sys_split(@series,CHAR(9)) AS s
		LEFT JOIN ew_inv_capas AS c 
			ON c.idarticulo = @idarticulo 
			AND c.serie = s.valor
		LEFT JOIN ew_inv_capas_existencia AS ce 
			ON ce.idcapa = c.idcapa 
			AND ce.idalmacen = @idalmacen_origen
	
	FETCH NEXT FROM cur_mov INTO 
		@idr
		, @idarticulo
		, @series
END

CLOSE cur_mov
DEALLOCATE cur_mov
----------------------------------------------------

-- INSERTAR ARTICULOS LOTE DE FABRICACION
DECLARE cur_mov CURSOR FOR
	SELECT 
		idm.idr
		, idm.idarticulo
		, idm.lote
		, [idcapa] = ISNULL((
			SELECT TOP 1
				ice.idcapa
			FROM
				ew_inv_capas_existencia AS ice
				LEFT JOIN ew_inv_capas As ic
					ON ic.idcapa = ice.idcapa
			WHERE
				ic.lote = idm.lote
				AND ic.idarticulo = idm.idarticulo
				AND ice.existencia >= idm.cantidad
				ANd ice.idalmacen = idm.idalmacen
		), 0)
		, idm.fecha_caducidad
		, idm.cantidad
	FROM
		ew_inv_documentos_mov AS idm
	WHERE
		idm.idtran = @idtran
		AND LEN(idm.lote) > 0
		
OPEN cur_mov

FETCH NEXT FROM cur_mov INTO 
	@idr
	, @idarticulo
	, @lote
	, @idcapa
	, @fecha_caducidad
	, @cantidad

WHILE @@FETCH_STATUS = 0
BEGIN
	INSERT INTO @tmp_mov (
		idr
		, idarticulo
		, serie
		, lote
		, idcapa
		, fecha_caducidad
		, cantidad
		, costo
	)
	SELECT 
		[idr] = @idr
		, [idarticulo] = @idarticulo
		, [serie] = ''
		, c.lote
		, c.idcapa
		, c.fecha_caducidad
		, [cantidad] = @cantidad
		, ce.costo
	FROM 
		ew_inv_capas AS c
		LEFT JOIN ew_inv_capas_existencia AS ce 
			ON ce.idcapa = c.idcapa 
			AND ce.idalmacen = @idalmacen_origen
	WHERE 
		c.idarticulo = @idarticulo 
		AND c.idcapa = @idcapa
		
	FETCH NEXT FROM cur_mov INTO 
		@idr
		, @idarticulo
		, @lote
		, @idcapa
		, @fecha_caducidad
		, @cantidad
END

CLOSE cur_mov
DEALLOCATE cur_mov

INSERT INTO ew_inv_transacciones_mov (
	idtran
	, idtran2
	, idmov2
	, consecutivo
	, tipo
	, idalmacen
	, idcapa
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
	[idtran] = @salida_idtran
	,[idtran2] = itm.idtran
	,[idmov2] = itm.idmov
	,[consecutivo] = t.consecutivo
	,[tipo] = 2
	,[idalmacen] = @idalmacen_origen
	,[idcapa]= t.idcapa
	,itm.idarticulo
	,t.serie
	,itm.lote
	,itm.fecha_caducidad
	,itm.idum
	,t.cantidad
	,[costo] = t.costo
	,[afectainv] = 1
	,itm.comentario
FROM
	@tmp_mov AS t
	LEFT JOIN ew_inv_documentos_mov AS itm 
		ON itm.idr = t.idr
WHERE
	itm.idtran = @idtran
	
--------------------------------------------------------------------------------
-- ENTRADA AL ALMACEN DE DESTINO ###############################################
SELECT @sql = ''

SELECT @sql='INSERT INTO ew_inv_transacciones (
	idtran
	,idtran2
	,idsucursal
	,idalmacen
	,fecha
	,folio
	,transaccion
	,referencia
	,comentario
	,idconcepto
	,idu
)
SELECT
	{idtran}
	,idtran
	,idsucursal_destino
	,idalmacen_destino
	,fecha
	,[folio] = ''{folio}''
	,[transaccion] = ''GDC1''
	,referencia
	,comentario
	,idconcepto
	,' + CONVERT(VARCHAR(10),@idu) + '
FROM
	ew_inv_documentos
WHERE
	idtran = ' + CONVERT(VARCHAR(20), @idtran)
	
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

INSERT INTO ew_inv_transacciones_mov (
	afectaref
	, idtran
	, idtran2
	, idmov2
	, consecutivo
	, tipo
	, idalmacen
	, idcapa
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
	[afectaref] = (CASE WHEN itm.idcapa>0 THEN 0 ELSE 1 END)
	,[idtran] = @entrada_idtran
	,[idtran2]= itm.idtran
	,[idmov2] = itm.idmov
	,[consecutivo] = itm.consecutivo
	,[tipo] = 1
	,[idalmacen] = @idalmacen_destino
	,[idcapa] = itm.idcapa
	,itm.idarticulo
	,itm.series
	,itm.lote
	,itm.fecha_caducidad
	,itm.idum
	,itm.cantidad
	,[costo] = itm.costo
	,[afectainv] = 1
	,itm.comentario
FROM
	ew_inv_transacciones_mov AS itm
WHERE
	itm.idtran = @salida_idtran	
	
--------------------------------------------------------------------------------
-- ACTUALIZAR COSTO EN EL TRASPASO #############################################

UPDATE trasd SET
	trasd.costo = (SELECT SUM(costo) FROM ew_inv_transacciones_mov WHERE idmov2 = trasd.idmov)
FROM 
	ew_inv_documentos_mov AS trasd
WHERE
	idtran = @idtran

UPDATE ew_inv_documentos SET
	total = (
		SELECT
			SUM(idm.costo)
		FROM ew_inv_documentos_mov AS idm
		WHERE
			idm.idtran = @idtran
	)
WHERE
	idtran = @idtran

-- Registrando el cambio de estado en la transaccion
INSERT INTO ew_sys_transacciones2 (
	idtran
	, idestado
	, comentario
	, idu
)
SELECT
	[idtran] = @idtran
	,[idestado] = 251
	,[comentario] = ''
	,[idu] = @idu

IF @@error != 0 OR @@rowcount = 0
BEGIN
	SELECT @msg = 'No se logró cambiar el estado de la transaccion ....'
	RAISERROR(@msg, 16, 1)
	RETURN
END
GO
