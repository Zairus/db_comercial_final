USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180310
-- Description:	Referencia de orden de venta a factura
-- =============================================
ALTER PROCEDURE _ven_prc_ordenReferenciaImpuestos
	@referencia AS VARCHAR(15)
	,@idsucursal AS INT
AS

SET NOCOUNT ON

SELECT
	[codigo] = a.codigo
	,[nombre] = a.nombre
	,[idtasa] = ew_ct_impuestos_transacciones.idtasa
	,[tasa] = cit.tasa
	,[base_proporcion] = cit.base_proporcion
	,[base] = ew_ct_impuestos_transacciones.base
	,[importe] = ew_ct_impuestos_transacciones.importe
	,[idr] = ew_ct_impuestos_transacciones.idr
	,[idtran] = ew_ct_impuestos_transacciones.idtran
	,[idmov] = ew_ct_impuestos_transacciones.idmov
FROM 
	ew_ct_impuestos_transacciones 
	LEFT JOIN ew_ven_ordenes_mov AS vom
		ON vom.idmov = ew_ct_impuestos_transacciones.idmov
	LEFT JOIN ew_ven_ordenes AS vo
		ON vo.idtran = vom.idtran
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vom.idarticulo
	LEFT JOIN ew_cat_impuestos_tasas AS cit
		ON cit.idtasa = ew_ct_impuestos_transacciones.idtasa
WHERE
	vo.cancelado = 0
	AND vo.transaccion = 'EOR1'
	AND vo.idsucursal = @idsucursal
	AND vo.folio IN (
		SELECT r.valor 
		FROM dbo._sys_fnc_separarMultilinea(@referencia, '	') AS r
	)
GO
