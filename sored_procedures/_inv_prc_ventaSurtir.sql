USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170610
-- Description:	Surtir movimiento de venta
-- =============================================
ALTER PROCEDURE [dbo].[_inv_prc_ventaSurtir]
	@idtran AS INT
	,@tipo AS INT
	,@idconcepto AS INT
AS

SET NOCOUNT ON

DECLARE
	@inv_idtran AS INT
	,@fecha AS SMALLDATETIME
	,@idalmacen AS INT
	,@idu AS INT

SELECT
	@fecha = vt.fecha
	,@idalmacen = vt.idalmacen
	,@idu =  idu
FROM
	ew_ven_transacciones AS vt
WHERE
	vt.idtran = @idtran

EXEC _inv_prc_transaccionCrear
	@idtran
	,@fecha
	,@tipo
	,@idalmacen
	,@idconcepto
	,@idu
	,@inv_idtran OUTPUT

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
	 [idtran] = @inv_idtran
	,[idmov2] = vtm.idmov
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY vtm.idr)
	,[tipo] = @tipo
	,[idalmacen] = @idalmacen
	,vtm.idarticulo
	,vtm.series
	,[lote] = ''
	,[fecha_caducidad] = NULL
	,vtm.idum
	,[cantidad] = (CASE WHEN vtm.cantidad_facturada = 0 THEN vtm.cantidad_devuelta ELSE vtm.cantidad_facturada END)
	,[costo] = (CASE WHEN @tipo = 2 THEN 0 ELSE vtm.costo END)
	,[afectainv] = 1
	,vtm.comentario
FROM
	ew_ven_transacciones_mov AS vtm
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vtm.idarticulo
WHERE
	a.inventariable = 1
	AND vtm.idtran = @idtran
	
IF @tipo = 2
BEGIN
	UPDATE vtm SET
		vtm.costo = itm.costo
	FROM
		ew_ven_transacciones_mov AS vtm
		LEFT JOIN ew_inv_transacciones_mov AS itm
			ON itm.idmov2 = vtm.idmov
		LEFT JOIN ew_articulos AS a
			ON a.idarticulo = vtm.idarticulo
	WHERE
		a.inventariable = 1
		AND vtm.idtran = @idtran

	UPDATE ew_ven_transacciones SET
		costo = (
			SELECT
				SUM(vtm.costo)
			FROM
				ew_ven_transacciones_mov AS vtm
			WHERE
				vtm.idtran = @idtran
		)
	WHERE
		idtran = @idtran
END
GO
