USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170127
-- Description:	Cancelar toma de inventario fisico
-- =============================================
ALTER PROCEDURE [dbo].[_inv_prc_invFisicoCancelar]
	@idtran AS INT
	,@idu AS SMALLINT
	,@cancelado_fecha AS VARCHAR(20)
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

DECLARE
	@idestado AS INT

SELECT
	@usuario = u.usuario
	,@password = u.[password]
	,@idsucursal = id.idsucursal
	,@idestado = st.idestado
FROM
	ew_inv_documentos AS id
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = id.idtran
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

IF EXISTS(
	SELECT * 
	FROM ew_inv_transacciones_mov
	WHERE 
		tipo = 1
		AND idtran2 = @idtran
)
BEGIN
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
		,[idconcepto] = 33 + 1000
		,[idsucursal] = id.idsucursal
		,[idalmacen] = id.idalmacen
		,[fecha] = @cancelado_fecha
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
		[idtran] = itm.idtran
		,[idtran2] = itm.idtran2
		,[consecutivo] = ROW_NUMBER() OVER (ORDER BY itm.idtran, itm.consecutivo)
		,[idmov2] = itm.idmov2
		,[tipo] = 2
		,[idalmacen] = itm.idalmacen
		,[idarticulo] = itm.idarticulo
		,[series] = itm.series
		,[lote] = itm.lote
		,[fecha_caducidad] = itm.fecha_caducidad
		,[idum] = itm.idum
		,[cantidad] = itm.cantidad
		,[existencia] = ISNULL(aa.existencia, 0)
		,[costo] = itm.costo
		,[afectainv] = 1
		,[comentario] = itm.comentario
	FROM
		ew_inv_transacciones_mov AS itm
		LEFT JOIN ew_articulos_almacenes AS aa
			ON aa.idalmacen = itm.idalmacen
			AND aa.idarticulo = itm.idarticulo
	WHERE
		itm.tipo = 1
		AND itm.idtran2 = @idtran

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
END

IF EXISTS(
	SELECT * 
	FROM ew_inv_transacciones_mov
	WHERE 
		tipo = 2
		AND idtran2 = @idtran
)
BEGIN
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
		,[idconcepto] = 33 + 1000
		,[idsucursal] = id.idsucursal
		,[idalmacen] = id.idalmacen
		,[fecha] = @cancelado_fecha
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
		[idtran] = itm.idtran
		,[idtran2] = itm.idtran2
		,[consecutivo] = ROW_NUMBER() OVER (ORDER BY itm.idtran, itm.consecutivo)
		,[idmov2] = itm.idmov2
		,[tipo] = 1
		,[idalmacen] = itm.idalmacen
		,[idarticulo] = itm.idarticulo
		,[series] = itm.series
		,[lote] = itm.lote
		,[fecha_caducidad] = itm.fecha_caducidad
		,[idum] = itm.idum
		,[cantidad] = itm.cantidad
		,[existencia] = ISNULL(aa.existencia, 0)
		,[costo] = itm.costo
		,[afectainv] = 1
		,[comentario] = itm.comentario
	FROM
		ew_inv_transacciones_mov AS itm
		LEFT JOIN ew_articulos_almacenes AS aa
			ON aa.idalmacen = itm.idalmacen
			AND aa.idarticulo = itm.idarticulo
	WHERE
		itm.tipo = 2
		AND itm.idtran2 = @idtran

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
END

EXEC [dbo].[_ct_prc_transaccionCancelarContabilidad] @idtran, 3, @cancelado_fecha, @idu

UPDATE ew_inv_documentos SET
	cancelado = 1
	,cancelado_fecha = @cancelado_fecha
WHERE
	idtran = @idtran
GO
