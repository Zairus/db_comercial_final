USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110429
-- Description:	Procesar factura de compra
-- =============================================
ALTER PROCEDURE [dbo].[_com_prc_facturaCompraProcesar]
	@idtran AS INT
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACION DE VARIABLES ####################################################

DECLARE
	 @idsucursal AS SMALLINT
	,@idu AS SMALLINT

DECLARE
	 @sql AS VARCHAR(2000)
	,@entrada_idtran AS BIGINT
	,@usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

SELECT
	 @idsucursal = idsucursal
	,@idu = idu
FROM 
	ew_com_transacciones
WHERE
	idtran = @idtran

SELECT
	 @usuario = usuario
	,@password = password
FROM 
	ew_usuarios
WHERE
	idu = @idu

--------------------------------------------------------------------------------
-- CREAR ENTRADA A ALMACEN #####################################################

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
	 {idtran}
	,idtran
	,idsucursal
	,idalmacen
	,fecha
	,[folio] = ''{folio}''
	,[transaccion] = ''GDC1''
	,[idconcepto] = 11
	,[referencia] = ''CRE1 - '' + folio
	,comentario
FROM 
	ew_com_transacciones
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
	,[idmov2] = ctm.idmov
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY ctm.idr)
	,[tipo] = 1
	,[idlamacen] = ctm.idalmacen
	,[idarticulo] = ctm.idarticulo
	,[series] = ctm.series
	,[lote] = ''''
	,[fecha_caducidad] = ''''
	,[idum] = a.idum_almacen
	,[cantidad] = (ctm.cantidad_facturada * ISNULL(auf.factor, 1))
	,[costo] = (
		CASE
			WHEN ct.idmoneda = 0 THEN ctm.importe 
			ELSE (ctm.importe * ct.tipocambio)
		END
		+ctm.gastos
	)
	,[afectainv] = 1
	,[comentario] = ctm.comentario
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
	RAISERROR('No se pudo obtener información para registrar entrada.', 16, 1)
	RETURN
END

EXEC _sys_prc_insertarTransaccion
	 @usuario
	,@password
	,'GDC1' --Transacción
	,@idsucursal
	,'A' --Serie
	,@sql
	,6 --Longitod del folio
	,@entrada_idtran OUTPUT
	,'' --Afolio
	,'' --Afecha

IF @entrada_idtran IS NULL OR @entrada_idtran = 0
BEGIN
	RAISERROR('No se pudo crear entrada a almacén.', 16, 1)
	RETURN
END

--------------------------------------------------------------------------------
-- ACTUALIZAR COSTO BASE #######################################################

UPDATE [as] SET
	[as].costo_base = ctm.costo_unitario
FROM
	ew_com_transacciones_mov AS ctm
	LEFT JOIN ew_com_transacciones AS ct
		ON ct.idtran = ctm.idtran
	LEFT JOIN ew_articulos_sucursales AS [as]
		ON [as].idarticulo = ctm.idarticulo
		AND [as].idsucursal = ct.idsucursal
WHERE
	ctm.idtran = @idtran

--------------------------------------------------------------------------------
-- CONTABILIZAR ################################################################

--EXEC _com_prc_facturaContabilizar @idtran, 0
GO
