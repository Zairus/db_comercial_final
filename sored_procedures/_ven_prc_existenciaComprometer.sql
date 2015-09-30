USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150924
-- Description:	Actualizar existencia comprometida
-- =============================================
CREATE PROCEDURE _ven_prc_existenciaComprometer
AS

SET NOCOUNT ON

UPDATE aa SET
	aa.comprometida = (vom.cantidad_autorizada - vom.cantidad_facturada)
FROM
	ew_ven_ordenes_mov AS vom
	LEFT JOIN ew_ven_ordenes AS vo
		ON vo.idtran = vom.idtran
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idalmacen = vo.idalmacen
		AND aa.idarticulo = vom.idarticulo
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = vo.idtran
WHERE
	vo.transaccion = 'EOR1'
	AND vo.cancelado = 0
	AND st.idestado < 45
GO
