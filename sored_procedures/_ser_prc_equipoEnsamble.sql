USE db_comercial_final
GO
IF OBJECT_ID('_ser_prc_equipoEnsamble') IS NOT NULL
BEGIN
	DROP PROCEDURE _ser_prc_equipoEnsamble
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190820
-- Description:	Realizar ensamble de equipo
-- =============================================
CREATE PROCEDURE [dbo].[_ser_prc_equipoEnsamble]
	@idtran AS INT
	, @idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@usuario AS VARCHAR(20)
	, @password AS VARCHAR(20)
	, @transaccion AS VARCHAR(5)
	, @idsucursal AS INT
	, @serie AS VARCHAR(25) = ''
	, @sql AS VARCHAR(MAX) = ''
	, @foliolen AS TINYINT = 6
	, @afolio AS VARCHAR(10) = ''
	, @afecha AS VARCHAR(20) = ''

DECLARE
	@idtran_salida AS INT
	, @idtran_entrada AS INT

SELECT
	@idsucursal = id.idsucursal
FROM
	ew_inv_documentos AS id
WHERE
	id.idtran = @idtran

SELECT
	@usuario = u.usuario
	, @password = u.[password]
FROM
	evoluware_usuarios AS u
WHERE
	u.idu = @idu

SELECT @transaccion = 'GDA1'

EXEC _sys_prc_insertarTransaccion
	@usuario
	, @password
	, @transaccion
	, @idsucursal
	, @serie
	, @sql
	, @foliolen
	, @idtran_salida OUTPUT
	, @afolio
	, @afecha

INSERT INTO ew_inv_transacciones (
	idtran
	, idtran2
	, idconcepto
	, idsucursal
	, idalmacen
	, fecha
	, folio
	, transaccion
	, referencia
	, moneda
	, tipocambio
	, idu
	, comentario
)
SELECT
	[idtran] = st.idtran
	, [idtran2] = id.idtran
	, [idconcepto] = id.idconcepto
	, [idsucursal] = id.idsucursal
	, [idalmacen] = id.idalmacen
	, [fecha] = st.fecha
	, [folio] = st.folio
	, [transaccion] = st.transaccion
	, [referencia] = id.transaccion + '-' + id.folio
	, [moneda] = 0
	, [tipocambio] = 1
	, [idu] = @idu
	, [comentario] = ''
FROM
	ew_sys_transacciones AS st
	LEFT JOIN ew_inv_documentos AS id
		ON id.idtran = @idtran
WHERE
	st.idtran = @idtran_salida

INSERT INTO ew_inv_transacciones_mov (
	idtran
	, idtran2
	, consecutivo
	, idmov2
	, tipo
	, idalmacen
	, idarticulo
	, idum
	, series
	, lote
	, cantidad
	, existencia
	, afectainv
	, comentario
)
SELECT
	[idtran] = st.idtran
	, [idtran2] = id.idtran
	, [consecutivo] = ROW_NUMBER() OVER (ORDER BY idm.consecutivo)
	, [idmov2] = idm.idmov
	, [tipo] = 2
	, [idalmacen] = id.idalmacen
	, [idarticulo] = idm.idarticulo
	, [idum] = a.idum_almacen
	, [series] = idm.series
	, [lote] = idm.lote
	, [cantidad] = idm.cantidad
	, [existencia] = ISNULL(aa.existencia, 0)
	, [afectainv] = a.inventariable
	, [comentario] = ''
FROM
	ew_sys_transacciones AS st
		LEFT JOIN ew_inv_documentos AS id
			ON id.idtran = @idtran
		LEFT JOIN ew_inv_documentos_mov AS idm
			ON idm.idtran = id.idtran
		LEFT JOIN ew_articulos AS a
			ON a.idarticulo = idm.idarticulo
		LEFT JOIN ew_articulos_almacenes AS aa
			ON aa.idalmacen = id.idalmacen
			AND aa.idarticulo = idm.idarticulo
	WHERE
		st.idtran = @idtran_salida

UPDATE it SET
	it.total = ISNULL((
		SELECT
			SUM(itm.costo)
		FROM
			ew_inv_transacciones_mov AS itm
		WHERE
			itm.idtran = @idtran_salida
	), 0)
FROM
	ew_inv_transacciones AS it
WHERE
	it.idtran = @idtran_salida

SELECT @transaccion = 'GDC1'

EXEC _sys_prc_insertarTransaccion
	@usuario
	, @password
	, @transaccion
	, @idsucursal
	, @serie
	, @sql
	, @foliolen
	, @idtran_entrada OUTPUT
	, @afolio
	, @afecha

INSERT INTO ew_inv_transacciones (
	idtran
	, idtran2
	, idconcepto
	, idsucursal
	, idalmacen
	, fecha
	, folio
	, transaccion
	, referencia
	, moneda
	, tipocambio
	, idu
	, comentario
	, total
)
SELECT
	[idtran] = st.idtran
	, [idtran2] = id.idtran
	, [idconcepto] = id.idconcepto
	, [idsucursal] = id.idsucursal
	, [idalmacen] = id.idalmacen
	, [fecha] = st.fecha
	, [folio] = st.folio
	, [transaccion] = st.transaccion
	, [referencia] = id.transaccion + '-' + id.folio
	, [moneda] = 0
	, [tipocambio] = 1
	, [idu] = @idu
	, [comentario] = ''
	, [total] = sal.total
FROM
	ew_sys_transacciones AS st
	LEFT JOIN ew_inv_documentos AS id
		ON id.idtran = @idtran
	LEFT JOIN ew_inv_transacciones AS sal
		ON sal.idtran = @idtran_salida
WHERE
	st.idtran = @idtran_entrada

INSERT INTO ew_inv_transacciones_mov (
	idtran
	, idtran2
	, consecutivo
	, idmov2
	, tipo
	, idalmacen
	, idarticulo
	, idum
	, series
	, lote
	, cantidad
	, existencia
	, costo
	, afectainv
	, comentario
)
SELECT
	[idtran] = st.idtran
	, [idtran2] = id.idtran
	, [consecutivo] = 1
	, [idmov2] = id.idmov
	, [tipo] = 1
	, [idalmacen] = id.idalmacen
	, [idarticulo] = id.idarticulo
	, [idum] = a.idum_almacen
	, [series] = id.folio
	, [lote] = (CASE WHEN a.lotes = 1 THEN id.folio ELSE '' END)
	, [cantidad] = 1
	, [existencia] = ISNULL(aa.existencia, 0)
	, [costo] = sal.total
	, [afectainv] = a.inventariable
	, [comentario] = ''
FROM
	ew_sys_transacciones AS st
	LEFT JOIN ew_inv_documentos AS id
		ON id.idtran = @idtran
	LEFT JOIN ew_inv_transacciones AS sal
		ON sal.idtran = @idtran_salida
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = id.idarticulo
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idalmacen = id.idalmacen
		AND aa.idarticulo = id.idarticulo
WHERE
	st.idtran = @idtran_entrada

INSERT INTO ew_sys_transacciones2 (
	idtran
	, idestado
	, idu
)
SELECT
	[idtran] = @idtran
	, [idestado] = 5
	, [idu] = @idu
GO
