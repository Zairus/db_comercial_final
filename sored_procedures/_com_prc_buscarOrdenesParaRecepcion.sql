USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20161210
-- Description:	Busqueda de ordenes de compra para recepcion
-- =============================================
ALTER PROCEDURE _com_prc_buscarOrdenesParaRecepcion
	@idsucursal AS INT
	,@idalmacen AS INT
	,@busqueda AS VARCHAR(500) = ''
AS

SET NOCOUNT ON

SELECT @busqueda = '%' + @busqueda + '%'

SELECT
	[referencia] = co.folio
	, [orden_fecha] = co.fecha
	, [proveedor] = p.nombre
	, [codproveedor] = p.codigo
	, [orden_total] = co.total 
FROM 
	ew_com_ordenes AS co 
	LEFT JOIN ew_proveedores AS p 
		ON p.idproveedor = co.idproveedor 
	LEFT JOIN ew_sys_transacciones AS st 
		ON st.idtran = co.idtran 
WHERE 
	co.cancelado = 0 
	AND co.transaccion = 'COR1' 
	AND st.idestado IN (3,31,37,44,43) 
	AND co.idsucursal = @idsucursal
	AND co.idtran IN (
		SELECT DISTINCT com.idtran 
		FROM
			ew_com_ordenes_mov AS com 
		WHERE 
			com.cantidad_autorizada > (com.cantidad_surtida - com.cantidad_devuelta)
			AND com.idalmacen = @idalmacen
	)

	AND (
		co.folio LIKE @busqueda
		OR p.nombre LIKE @busqueda
		OR p.codigo LIKE @busqueda
	)
GO
