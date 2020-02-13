USE db_comercial_final
GO
IF OBJECT_ID('_com_prc_programacionComprasGenerar') IS NOT NULL
BEGIN
	DROP PROCEDURE _com_prc_programacionComprasGenerar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091008
-- Description:	Generación de ordenes de compras de programación
-- =============================================
CREATE PROCEDURE [dbo].[_com_prc_programacionComprasGenerar]
	@idtran AS BIGINT
	,@idu AS SMALLINT = 1
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACION DE VARIABLES ####################################################

DECLARE	
	@idproveedor AS INT
	, @fecha AS SMALLDATETIME
	, @subtotal AS DECIMAL(12,2)

DECLARE	
	@usuario AS VARCHAR(20)
	, @password AS VARCHAR(20)
	, @sql AS VARCHAR(8000)
	, @orden_idtran AS INT
	, @transaccion AS VARCHAR(4)
	, @idsucursal AS SMALLINT
	, @serie AS VARCHAR(25) = 'A'
	, @foliolen AS TINYINT = 6
	, @afolio AS VARCHAR(10) = ''
	, @afecha AS VARCHAR(20) = ''

SELECT 
	@fecha = GETDATE()

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

IF EXISTS (
	SELECT * 
	FROM 
		ew_com_programacion_det 
	WHERE 
		cantidad_ordenada = 0 
		AND idtran = @idtran
)
BEGIN
	RAISERROR('Error: Se debe indicar cantidad a ordenar en todos los registros.', 16, 1)
	RETURN
END

IF EXISTS (
	SELECT * 
	FROM 
		ew_com_programacion_det 
	WHERE 
		idproveedor = 0 
		AND idtran = @idtran
)
BEGIN
	RAISERROR('Error: Se debe indicar proveedor en todos los registros.', 16, 1)
	RETURN
END

SELECT
	@transaccion = 'COR1'
	, @idsucursal = idsucursal
FROM
	ew_com_programacion
WHERE
	idtran = @idtran

SELECT
	@usuario = usuario
	, @password = [password]
FROM 
	ew_usuarios
WHERE
	idu = @idu
	
--------------------------------------------------------------------------------
-- GENERAR ORDENES DE COMPRA ###################################################

--Generar Órdenes de Compra
DECLARE cur_proveedores CURSOR FOR
	SELECT DISTINCT 
		idproveedor
	FROM
		ew_com_programacion_det
	WHERE
		idproveedor > 0
		AND cantidad_ordenada > 0
		AND idtran = @idtran

OPEN cur_proveedores

FETCH NEXT FROM cur_proveedores INTO
	@idproveedor

WHILE @@fetch_status = 0
BEGIN
	SELECT 
		@subtotal = SUM(costo_total) 
	FROM
		ew_com_programacion_det 
	WHERE 
		idtran = @idtran 
		AND idproveedor = @idproveedor
	
	SELECT @subtotal = ISNULL(@subtotal, 0)
	
	SELECT @sql = '
INSERT INTO ew_com_ordenes (
	idtran
	,idmov
	,idtran2
	,idconcepto
	,idsucursal
	,idalmacen
	,fecha
	,folio
	,transaccion
	,idproveedor
	,idcontacto
	,dias_entrega
	,dias_credito
	,pedimento
	,idpedimento
	,idu
	,idimpuesto1
	,idmoneda
	,tipocambio
	,subtotal
	,gastos
	,impuesto1
	,impuesto2
	,impuesto3
	,impuesto4
	,total
	,comentario
	,cancelado
	,cancelado_fecha
)

SELECT
	[idtran] = {idtran}
	,[idmov] = NULL
	,[idtran2] = cprg.idtran
	,[idconcepto] = 16
	,[idsucursal] = cprg.idsucursal
	,[idalmacen] = (SELECT TOP 1 cprgd.idalmacen FROM ew_com_programacion_det AS cprgd WHERE cprgd.idtran = cprg.idtran)
	,[fecha] = cprg.fecha
	,[folio] = ''{folio}''
	,[transaccion] = ''' + @transaccion + '''
	,[idproveedor] = ' + LTRIM(RTRIM(STR(@idproveedor))) + '
	,[idcontacto] = 0
	,[dias_entrega] = 0
	,[dias_credito] = 0
	,[pedimento] = ''''
	,[idpedimento] = 0
	,[idu] = cprg.idu
	,[idimpuesto1] = ci.idimpuesto
	,[idmoneda] = 0
	,[tipocambio] = 1
	,[subtotal] = ' + CONVERT(VARCHAR(20), @subtotal) + '
	,[gastos] = 0
	,[impuesto1] = (' + CONVERT(VARCHAR(20), @subtotal) + ' * ci.valor)
	,[impuesto2] = 0
	,[impuesto3] = 0
	,[impuesto4] = 0
	,[total] = (' + CONVERT(VARCHAR(20), @subtotal) + ' + (' + CONVERT(VARCHAR(20), @subtotal) + ' * ci.valor))
	,[comentario] = cprg.comentario
	,[cancelado] = 0
	,[cancelado_fecha] = NULL
FROM
	ew_com_programacion AS cprg
	LEFT JOIN ew_cat_impuestos AS ci
		ON ci.idimpuesto = 1
WHERE
	cprg.idtran = ' + LTRIM(RTRIM(STR(@idtran))) + '

INSERT INTO ew_com_ordenes_mov (
	idtran
	,consecutivo
	--,idmov
	,idmov2
	,idarticulo
	,codigo_proveedor
	,idum
	,idalmacen
	,existencia
	,cantidad_cotizada
	,cantidad_ordenada
	,cantidad_autorizada
	,cantidad_surtida
	,cantidad_devuelta
	,cantidad_facturada
	,costo_unitario
	,descuento1
	,descuento2
	,descuento3
	,importe
	,gastos
	,impuesto1
	,impuesto2
	,impuesto3
	,impuesto4
	,total
	,comentario
)

SELECT
	[idtran] = {idtran}
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY cprgd.idr)
	--,[idmov] = NULL
	,[idmov2] = cprgd.idmov
	,[idarticulo] = cprgd.idarticulo
	,[codigo_proveedor] = '''' --p.codigo
	,[idum] = a.idum_compra
	,[idalmacen] = cprgd.idalmacen
	,[existencia] = aa.existencia
	,[cantidad_cotizada] = 0
	,[cantidad_ordenada] = cprgd.cantidad_ordenada
	,[cantidad_autorizada] = cprgd.cantidad_ordenada
	,[cantidad_surtida] = 0
	,[cantidad_devuelta] = 0
	,[cantidad_facturada] = 0
	,[costo_unitario] = cprgd.costo_unitario
	,[descuento1] = 0
	,[descuento2] = 0
	,[descuento3] = 0
	,[importe] = cprgd.costo_total
	,[gastos] = 0
	,[impuesto1] = (cprgd.costo_total * ci.valor)
	,[impuesto2] = 0
	,[impuesto3] = 0
	,[impuesto4] = 0
	,[total] = (cprgd.costo_total + (cprgd.costo_total * ci.valor))
	,[comentario] = cprgd.comentario
FROM
	ew_com_programacion_det AS cprgd
	LEFT JOIN ew_cat_impuestos AS ci
		ON ci.idimpuesto = 1
	LEFT JOIN ew_proveedores AS p
		ON p.idproveedor = cprgd.idproveedor
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = cprgd.idarticulo
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idarticulo = cprgd.idarticulo
		AND aa.idalmacen = cprgd.idalmacen
WHERE
	cprgd.idtran = ' + LTRIM(RTRIM(STR(@idtran))) + '
	AND cprgd.idproveedor = ' + LTRIM(RTRIM(STR(@idproveedor))) + '
'
	
	IF @sql IS NULL OR @sql = ''
	BEGIN
		RAISERROR('No se pudo obtener información para generar orden de compra.', 16, 1)
		RETURN
	END
	
	EXEC _sys_prc_insertarTransaccion
		@usuario
		, @password
		, @transaccion
		, @idsucursal
		, @serie
		, @sql
		, @foliolen
		, @orden_idtran OUTPUT
		, @afolio
		, @afecha

	IF @orden_idtran IS NULL OR @orden_idtran = 0
	BEGIN
		RAISERROR('No se pudo generar orden de compra.', 16, 1)
		RETURN
	END
	
	FETCH NEXT FROM cur_proveedores INTO
		@idproveedor
END

CLOSE cur_proveedores
DEALLOCATE cur_proveedores

--------------------------------------------------------------------------------
-- CAMBIAR ESTADO DE LA PROGRAMACIÓN ###########################################

INSERT INTO ew_sys_transacciones2
	(idtran, idestado, idu)
VALUES
	(@idtran, 13, @idu)
GO
