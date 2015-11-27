USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20151116
-- Description:	Obtener existencia comprometida por articulo por almacen
-- =============================================
ALTER FUNCTION [dbo].[fn_inv_existenciaComprometida]
(
	@idarticulo AS INT
	,@idalmacen AS INT
)
RETURNS DECIMAL(18,6)
AS
BEGIN
	DECLARE
		@comprometida AS DECIMAL(18,6)

	SELECT
		@comprometida = SUM(vom.cantidad_autorizada - vom.cantidad_facturada + vom.cantidad_devuelta)
	FROM
		ew_ven_ordenes_mov AS vom
		LEFT JOIN ew_ven_ordenes AS vo
			ON vo.idtran = vom.idtran
		LEFT JOIN ew_sys_transacciones AS st
			ON st.idtran = vo.idtran
	WHERE
		vo.cancelado = 0
		AND st.idestado <> 251
		AND (
			SELECT
				COUNT(vt.idtran)
			FROM
				ew_ven_transacciones AS vt
			WHERE
				vt.idtran2 = vo.idtran
				AND vt.cancelado = 0
		) = 0
		AND vom.idarticulo = @idarticulo
		AND vo.idalmacen = @idalmacen

	SELECT @comprometida = ISNULL(@comprometida, 0)

	RETURN @comprometida
END
GO
