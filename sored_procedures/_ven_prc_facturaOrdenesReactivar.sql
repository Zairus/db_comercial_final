USE db_comercial_final
GO
IF OBJECT_ID('_ven_prc_facturaOrdenesReactivar') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_prc_facturaOrdenesReactivar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200318
-- Description:	Reactivar cantidades en orden por cancelacion factura
-- =============================================
CREATE PROCEDURE [dbo].[_ven_prc_facturaOrdenesReactivar]
	@idtran AS INT
	, @idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@idtran2 AS INT

--------------------------------------------------------------------
-- Reactivamos la mercancia surtida en la orden 
--------------------------------------------------------------------
INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	, idmov2
	, campo
	, valor
)
SELECT 
	[idmov1] = m.idmov
	, [idmov2] = m.idmov2
	, [campo] = 'cantidad_surtida'
	, [valor] = m.cantidad_surtida * (-1)
FROM
	ew_ven_transacciones_mov AS m
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = m.idarticulo
WHERE 
	idtran = @idtran
	AND m.cantidad_surtida != 0
	AND (
		SELECT COUNT(*) 
		FROM 
			ew_inv_transacciones_mov AS itm 
		WHERE 
			itm.idmov2 = m.idmov2
	) = 0

--------------------------------------------------------------------
-- Reactivamos la mercancia facturada en la orden 
--------------------------------------------------------------------
INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	, idmov2
	, campo
	, valor
)
SELECT 
	[idmov1] = idmov
	, [idmov2] = idmov2
	, [campo] = 'cantidad_facturada'
	, [valor] = cantidad_facturada  * (-1)
FROM
	ew_ven_transacciones_mov
WHERE 
	idtran = @idtran
	AND cantidad_facturada != 0

--------------------------------------------------------------------
-- Reabrimos los pedidos
--------------------------------------------------------------------
DECLARE cur_detalle1 CURSOR FOR
	SELECT DISTINCT 
		[idtran] = CONVERT(INT, FLOOR(fm.idmov2))
	FROM
		ew_ven_transacciones_mov fm 
	WHERE
		fm.cantidad_facturada > 0
		AND CONVERT(INT, FLOOR(fm.idmov2)) > 0
		AND fm.idtran = @idtran

OPEN cur_detalle1

FETCH NEXT FROM cur_detalle1 INTO 
	@idtran2

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC [dbo].[_ven_prc_ordenEstado] @idtran2, @idu

	FETCH NEXT FROM cur_detalle1 INTO 
		@idtran2
END

CLOSE cur_detalle1
DEALLOCATE cur_detalle1
GO
