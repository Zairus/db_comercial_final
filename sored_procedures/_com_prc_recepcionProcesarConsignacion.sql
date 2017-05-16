USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20161220
-- Description:	Ajuste por compra de articulos de consignacion vendidos
-- =============================================
ALTER PROCEDURE [dbo].[_com_prc_recepcionProcesarConsignacion]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@idsucursal AS SMALLINT
	,@idu AS SMALLINT

DECLARE
	@sql AS VARCHAR(2000) = ''
	,@salida_idtran AS BIGINT
	,@usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)
	,@transaccion AS VARCHAR(4)
	,@folio AS VARCHAR(15)

	,@registros AS INT

SELECT
	@registros = COUNT(*)
FROM
	ew_com_transacciones_mov AS ctm
	LEFT JOIN ew_com_ordenes_mov AS com
		ON com.idmov = ctm.idmov2
WHERE
	com.consignacion = 1
	AND ctm.idtran = @idtran

IF @registros = 0
BEGIN
	RETURN
END

SELECT
	@idsucursal = ct.idsucursal
	,@idu = ct.idu
	,@transaccion = 'GDA1'
FROM 
	ew_com_transacciones AS ct
WHERE
	ct.idtran = @idtran

SELECT
	@usuario = usuario
	,@password = [password]
FROM
	ew_usuarios
WHERE
	idu = @idu

EXEC _sys_prc_insertarTransaccion
	@usuario
	,@password
	,@transaccion
	,@idsucursal
	,'A' --Serie
	,@sql
	,6 --Longitod del folio
	,@salida_idtran OUTPUT
	,'' --Afolio
	,'' --Afecha

IF @salida_idtran IS NULL OR @salida_idtran = 0
BEGIN
	RAISERROR('No se pudo crear entrada a almacén.', 16, 1)
	RETURN
END

SELECT
	@folio = st.folio
FROM
	ew_sys_transacciones AS st
WHERE
	st.idtran = @salida_idtran

INSERT INTO ew_inv_transacciones (
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
	[idtran] = @salida_idtran
	, [idtran2] = ct.idtran
	, idsucursal = @idsucursal
	, [idalmacen] = ct.idalmacen
	, [fecha] = ct.fecha
	, [folio] = @folio
	, [transaccion] = @transaccion
	, [referencia] = ct.transaccion + ' - ' + ct.folio
	, [idconcepto] = 50
	, [comentario] = ct.comentario
FROM
	ew_com_transacciones AS ct
WHERE
	ct.idtran = @idtran

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
	[idtran] = @salida_idtran
	,[idtran2] = ctm.idtran
	,[idmov2] = ctm.idmov
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY ctm.idr)
	,[tipo] = 2
	,[idlamacen] = ctm.idalmacen
	,[idarticulo] = ctm.idarticulo
	,[series] = ctm.series
	,[lote] = ctm.lote
	,[fecha_caducidad] = ctm.fecha_caducidad
	,[idum] = a.idum_almacen
	,[cantidad] = ctm.cantidad_recibida * (CASE WHEN um.factor = NULL THEN 1 ELSE um.factor END)
	,[afectainv] = 1
	,[comentario] = ctm.comentario
FROM
	ew_com_transacciones_mov AS ctm
	LEFT JOIN ew_com_ordenes_mov AS com
		ON com.idmov = ctm.idmov2
	LEFT JOIN ew_inv_transacciones_mov AS itm
		ON itm.idmov2 = ctm.idmov
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = ctm.idarticulo
	LEFT JOIN ew_cat_unidadesmedida AS um 
		ON a.idum_compra = um.idum
WHERE
	com.consignacion = 1
	AND ctm.idtran = @idtran
GO
