USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170124
-- Description:	Aplicar toma de inventario
-- =============================================
ALTER PROCEDURE [dbo].[_inv_prc_invFisicoAplicar]
	@idtran AS INT
	,@idu AS SMALLINT
AS

SET NOCOUNT ON

DECLARE
	@usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)
	,@transaccion AS VARCHAR(4)
	,@idsucursal AS INT
	,@serie AS VARCHAR(1) = 'A'
	,@sql AS VARCHAR(MAX) = ''
	,@foliolen AS INT = 6
	,@afolio AS VARCHAR(15) = ''
	,@afecha AS VARCHAR(15) = ''

DECLARE
	@entrada_idtran AS INT
	,@entrada_folio AS VARCHAR(15)
	,@salida_idtran AS INT
	,@salida_folio AS VARCHAR(15)

--Validar todo congelado
IF EXISTS(
	SELECT *
	FROM
		ew_inv_documentos_mov
	WHERE
		congelar = 0
		AND idtran = @idtran
)
BEGIN
	RAISERROR('Error: Todos los elementos de la toma de inventario deben estar congelados.', 16, 1)
	RETURN
END

SELECT
	@usuario = u.usuario
	,@password = u.[password]
	,@idsucursal = id.idsucursal
FROM
	ew_inv_documentos AS id
	LEFT JOIN evoluware_usuarios AS u
		ON u.idu = @idu
WHERE
	id.idtran = @idtran

UPDATE aa SET 
	aa.congelar = 0
FROM 
	ew_inv_documentos_mov AS idm
	LEFT JOIN ew_inv_documentos AS id
		ON id.idtran = idm.idtran
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idalmacen = id.idalmacen 
		AND aa.idarticulo = idm.idarticulo
WHERE 
	idm.idtran = @idtran

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
	,@afolio
	,@afecha

SELECT
	@entrada_folio = folio
FROM
	ew_sys_transacciones
WHERE
	idtran = @entrada_idtran

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
	[idtran] = @entrada_idtran
	,[idtran2] = id.idtran
	,[idconcepto] = 33
	,[idsucursal] = id.idsucursal
	,[idalmacen] = id.idalmacen
	,[fecha] = id.fecha
	,[folio] = @entrada_folio
	,[transaccion] = @transaccion
	,[referencia] = id.folio
	,[idu] = @idu
	,[total] = 0
	,[comentario] = id.comentario
FROM
	ew_inv_documentos AS id
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
	,lote
	,fecha_caducidad
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
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY idm.idr)
	,[idmov2] = idm.idmov
	,[tipo] = 1
	,[idalmacen] = id.idalmacen
	,[idarticulo] = idm.idarticulo
	,[series] = idm.series
	,[lote] = idm.lote
	,[fecha_caducidad] = idm.fecha_caducidad
	,[idum] = idm.idum
	,[cantidad] = ABS(idm.cantidad - idm.solicitado)
	,[existencia] = ISNULL(aa.existencia, 0)
	,[costo] = ISNULL(aa.costo_ultimo, 0) * ABS(idm.cantidad - idm.solicitado)
	,[afectainv] = 1
	,[comentario] = idm.comentario
FROM
	ew_inv_documentos_mov AS idm
	LEFT JOIN ew_inv_documentos AS id
		ON id.idtran = idm.idtran
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idarticulo = idm.idarticulo
		AND aa.idalmacen = id.idalmacen
WHERE
	(idm.cantidad - idm.solicitado) > 0
	AND idm.idtran = @idtran

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
	,@afolio
	,@afecha

SELECT
	@salida_folio = folio
FROM
	ew_sys_transacciones
WHERE
	idtran = @salida_idtran

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
	[idtran] = @salida_idtran
	,[idtran2] = id.idtran
	,[idconcepto] = 33
	,[idsucursal] = id.idsucursal
	,[idalmacen] = id.idalmacen
	,[fecha] = id.fecha
	,[folio] = @salida_folio
	,[transaccion] = @transaccion
	,[referencia] = id.folio
	,[idu] = @idu
	,[total] = 0
	,[comentario] = id.comentario
FROM
	ew_inv_documentos AS id
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
	,lote
	,fecha_caducidad
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
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY idm.idr)
	,[idmov2] = idm.idmov
	,[tipo] = 2
	,[idalmacen] = id.idalmacen
	,[idarticulo] = idm.idarticulo
	,[series] = idm.series
	,[lote] = idm.lote
	,[fecha_caducidad] = idm.fecha_caducidad
	,[idum] = idm.idum
	,[cantidad] = ABS(idm.cantidad - idm.solicitado)
	,[existencia] = ISNULL(aa.existencia, 0)
	,[costo] = ISNULL(aa.costo_ultimo, 0)
	,[afectainv] = 1
	,[comentario] = idm.comentario
FROM
	ew_inv_documentos_mov AS idm
	LEFT JOIN ew_inv_documentos AS id
		ON id.idtran = idm.idtran
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idarticulo = idm.idarticulo
		AND aa.idalmacen = id.idalmacen
WHERE
	(idm.cantidad - idm.solicitado) < 0
	AND idm.idtran = @idtran

UPDATE it SET
	it.total = ISNULL(
		(
			SELECT SUM(itm.costo) 
			FROM 
				ew_inv_transacciones_mov AS itm 
			WHERE 
				itm.idtran = it.idtran
		)
	, 0)
FROM
	ew_inv_transacciones AS it
WHERE
	it.idtran = @entrada_idtran

UPDATE it SET
	it.total = ISNULL(
		(
			SELECT SUM(itm.costo) 
			FROM 
				ew_inv_transacciones_mov AS itm 
			WHERE 
				itm.idtran = it.idtran
		)
	, 0)
FROM
	ew_inv_transacciones AS it
WHERE
	it.idtran = @salida_idtran

EXEC [dbo].[_sys_prc_trnAplicarEstado] @idtran, 'APL', @idu, 0

EXEC [dbo].[_ct_prc_polizaAplicarDeConfiguracion] @idtran
GO