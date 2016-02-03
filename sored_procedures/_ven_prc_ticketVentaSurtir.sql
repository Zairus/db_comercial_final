USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150624
-- Description:	Surtir ticket de venta
ALTER PROCEDURE [dbo].[_ven_prc_ticketVentaSurtir]
	@idtran AS INT
	,@cancelacion AS BIT = 0
AS

SET NOCOUNT ON

DECLARE
	@idconcepto AS SMALLINT = 46
	,@idsucursal AS SMALLINT
	,@serie AS VARCHAR(3) = 'A'
	,@usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)
	,@transaccion AS VARCHAR(5)
	,@sql AS VARCHAR(4000) = ''
	,@foliolen AS TINYINT = 6
	,@inventario_idtran AS INT

SELECT
	@usuario = u.usuario
	,@password = u.[password]
	,@idsucursal = vt.idsucursal
FROM
	ew_ven_transacciones AS vt
	LEFT JOIN evoluware_usuarios AS u
		ON u.idu = vt.idu
WHERE
	vt.idtran = @idtran

SELECT
	@transaccion = (
		CASE
			WHEN @cancelacion = 0 THEN 'GDA1'
			ELSE 'GDC1'
		END
	)

EXEC _sys_prc_insertarTransaccion
	@usuario
	,@password
	,@transaccion
	,@idsucursal
	,@serie
	,@sql
	,@foliolen
	,@inventario_idtran OUTPUT

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
	[idtran] = @inventario_idtran
	,[idtran2] = vt.idtran
	,[idconcepto] = @idconcepto
	,[idsucursal] = vt.idsucursal
	,[idalmacen] = vt.idalmacen
	,[fecha] = vt.fecha
	,[folio] = (SELECT st.folio FROM ew_sys_transacciones AS st WHERE st.idtran = @inventario_idtran)
	,[transaccion] = @transaccion
	,[referencia] = vt.transaccion + ' - ' + vt.folio
	,[idu] = vt.idu
	,[total] = 0
	,[comentario] = vt.comentario
FROM
	ew_ven_transacciones AS vt
WHERE
	vt.idtran = @idtran

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
	[idtran] = @inventario_idtran
	,[idtran2] = vtm.idtran
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY vtm.consecutivo)
	,[idmov2] = vtm.idmov
	,[tipo] = (CASE WHEN @cancelacion = 0 THEN 2 ELSE 1 END)
	,[idalmacen] = vt.idalmacen
	,[idarticulo] = vtm.idarticulo
	,[series] = vtm.series
	,[idum] = a.idum_venta
	,[cantidad] = vtm.cantidad_facturada
	,[existencia] = aa.existencia
	,[costo] = (CASE WHEN @cancelacion = 0 THEN 0 ELSE vtm.costo END)
	,[afectainv] = 1
	,[comentario] = vtm.comentario
FROM
	ew_ven_transacciones_mov AS vtm
	LEFT JOIN ew_ven_transacciones AS vt
		ON vt.idtran = vtm.idtran
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vtm.idarticulo
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idarticulo = vtm.idarticulo
		AND aa.idalmacen = vt.idalmacen
WHERE
	a.inventariable = 1
	AND vtm.idtran = @idtran

UPDATE it SEt
	it.total = ISNULL((
		SELECT
			SUM(itm.costo)
		FROM
			ew_inv_transacciones_mov AS itm
		WHERE
			itm.idtran = it.idtran
	), 0)
FROM
	ew_inv_transacciones AS it
WHERE
	it.idtran = @inventario_idtran

IF @cancelacion = 0
BEGIN
	UPDATE vtm SET
		vtm.costo = itm.costo
	FROM
		ew_ven_transacciones_mov As vtm
		LEFT JOIN ew_inv_transacciones_mov As itm
			ON itm.tipo = 2
			ANd itm.idmov2 = vtm.idmov
	WHERE
		vtm.idtran = @idtran
END
GO
