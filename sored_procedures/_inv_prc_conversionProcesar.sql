USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160114
-- Description:	Procesar conversion
-- =============================================
ALTER PROCEDURE [dbo].[_inv_prc_conversionProcesar]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@idconcepto AS SMALLINT = 8
	,@idsucursal AS SMALLINT
	,@serie AS VARCHAR(3) = 'A'
	,@usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)
	,@transaccion AS VARCHAR(5)
	,@sql AS VARCHAR(4000) = ''
	,@foliolen AS TINYINT = 6
	,@salida_idtran AS INT
	,@entrada_idtran AS INT
	
DECLARE
	@costo_salida AS DECIMAL(18,6)
	,@costo_previo_entrada AS DECIMAL(18,6)
	,@cantidad_total_equivalente AS DECIMAL(18,6)

SELECT
	@usuario = u.usuario
	,@password = u.[password]
	,@idsucursal = id.idsucursal
FROM
	ew_inv_documentos AS id
	LEFT JOIN evoluware_usuarios AS u
		ON u.idu = id.idu
WHERE
	id.idtran = @idtran

SELECT @transaccion = 'GDA1'

EXEC _sys_prc_insertarTransaccion
	@usuario
	,@password
	,@transaccion
	,@idsucursal
	,@serie
	,@sql
	,@foliolen
	,@salida_idtran OUTPUT

INSERT INTO ew_inv_transacciones (
	idtran
	,idtran2
	,idconcepto
	,idsucursal
	,idalmacen
	,fecha
	,folio
	,transaccion
	,referencia
	,idu
	,total
	,comentario
)
SELECT
	[idtran] = st.idtran
	,[idtran2] = id.idtran
	,[idconcepto] = @idconcepto
	,[idsucursal] = id.idsucursal
	,[idalmacen] = id.idalmacen
	,[fecha] = id.fecha
	,[folio] = st.folio
	,[transaccion] = st.transaccion
	,[referencia] = id.referencia
	,[idu] = id.idu
	,[total] = id.total
	,[comentario] = id.comentario
FROM
	ew_inv_documentos AS id
	LEFT JOIN ew_sys_transacciones As st
		ON st.idtran = @salida_idtran
WHERE
	id.idtran = @idtran

INSERT INTO ew_inv_transacciones_mov (
	idtran
	,idtran2
	,consecutivo
	,idmov2
	,tipo
	,idalmacen
	,idarticulo
	,series
	,idum
	,cantidad
	,existencia
	,costo
	,afectainv
	,comentario
)
SELECT
	[idtran] = @salida_idtran
	,[idtran2] = idm.idtran
	,[consecutivo] = 1
	,[idmov2] = idm.idmov
	,[tipo] = 2
	,[idalmacen] = idm.idalmacen
	,[idarticulo] = idm.idarticulo
	,[series] = ''
	,[idum] = idm.idum
	,[cantidad] = idm.cantidad
	,[existencia] = ISNULL(aa.existencia, 0)
	,[costo] = 0
	,[afectainv] = 1
	,[comentario] = idm.comentario
FROM
	ew_inv_documentos_mov AS idm
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idalmacen = idm.idalmacen
		AND aa.idarticulo = idm.idarticulo
WHERE
	idm.consecutivo = 0
	AND idm.idtran = @idtran

SELECT
	@costo_salida = SUM(itm.costo)
FROM
	ew_inv_transacciones_mov AS itm
WHERE
	itm.tipo = 2
	AND itm.idtran2 = @idtran

SELECT
	@costo_previo_entrada = SUM(aa.costo_ultimo)
	,@cantidad_total_equivalente = SUM(idm.cantidad * idm.factor)
FROM
	ew_inv_documentos_mov AS idm
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idalmacen = idm.idalmacen
		AND aa.idarticulo = idm.idarticulo
WHERE
	idm.consecutivo > 0
	AND idm.idtran = @idtran

SELECT @costo_salida = ISNULL(@costo_salida, 0)
SELECT @costo_previo_entrada = ISNULL(@costo_previo_entrada, 0)
SELECT @cantidad_total_equivalente = ISNULL(@cantidad_total_equivalente, 0)

SELECT @transaccion = 'GDC1'

EXEC _sys_prc_insertarTransaccion
	@usuario
	,@password
	,@transaccion
	,@idsucursal
	,@serie
	,@sql
	,@foliolen
	,@entrada_idtran OUTPUT

INSERT INTO ew_inv_transacciones (
	idtran
	,idtran2
	,idconcepto
	,idsucursal
	,idalmacen
	,fecha
	,folio
	,transaccion
	,referencia
	,idu
	,total
	,comentario
)
SELECT
	[idtran] = st.idtran
	,[idtran2] = id.idtran
	,[idconcepto] = @idconcepto
	,[idsucursal] = id.idsucursal
	,[idalmacen] = id.idalmacen
	,[fecha] = id.fecha
	,[folio] = st.folio
	,[transaccion] = st.transaccion
	,[referencia] = id.referencia
	,[idu] = id.idu
	,[total] = id.total
	,[comentario] = id.comentario
FROM
	ew_inv_documentos AS id
	LEFT JOIN ew_sys_transacciones As st
		ON st.idtran = @entrada_idtran
WHERE
	id.idtran = @idtran

INSERT INTO ew_inv_transacciones_mov (
	idtran
	,idtran2
	,consecutivo
	,idmov2
	,tipo
	,idalmacen
	,idarticulo
	,series
	,idum
	,cantidad
	,existencia
	,costo
	,afectainv
	,comentario
)
SELECT
	[idtran] = @entrada_idtran
	,[idtran2] = idm.idtran
	,[consecutivo] = idm.consecutivo
	,[idmov2] = idm.idmov
	,[tipo] = 1
	,[idalmacen] = idm.idalmacen
	,[idarticulo] = idm.idarticulo
	,[series] = ''
	,[idum] = idm.idum
	,[cantidad] = idm.cantidad
	,[existencia] = ISNULL(aa.existencia, 0)
	,[costo] = (@costo_salida *  ((idm.cantidad * idm.factor) / @cantidad_total_equivalente))
	,[afectainv] = 1
	,[comentario] = idm.comentario
FROM
	ew_inv_documentos_mov AS idm
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idalmacen = idm.idalmacen
		AND aa.idarticulo = idm.idarticulo
WHERE
	idm.consecutivo > 0
	AND idm.idtran = @idtran

UPDATE idm SET
	idm.costo = itm.costo
FROM
	ew_inv_documentos_mov AS idm
	LEFT JOIN ew_inv_transacciones_mov AS itm
		ON itm.idmov2 = idm.idmov
WHERE
	idm.consecutivo > 0
	AND itm.tipo = 1
	AND idm.idtran = @idtran
GO
