USE db_comercial_final
GO

-- =============================================
-- Author:		Fernanda Corona
-- Create date: 201003
-- Description:	Reporte de Inventario Físico
-- =============================================
ALTER PROCEDURE [dbo].[_inv_rpt_GDT2]
	@idtran AS INT
	
AS

SET NOCOUNT ON

SELECT
	[idtran] = doc.idtran
	, [almacen] = a.nombre
	, [folio] = doc.folio
	, [fecha] = doc.fecha
	, [filtrado] = doc.filtrar
	, [referencia] = doc.referencia
	, [codigo] = ar.codigo
	, [descripcion] = ar.nombre
	, [serie] = ar.series
	, [series] = m.series
	, [existencia] = m.solicitado
	, [empresa] = dbo.fn_sys_empresa()
FROM 
	ew_inv_documentos_mov AS m
	LEFT JOIN ew_inv_documentos AS doc 
		ON doc.idtran = m.idtran
	LEFT JOIN ew_articulos AS ar 
		ON ar.idarticulo = m.idarticulo
	LEFT JOIN ew_articulos_almacenes AS al 
		ON al.idalmacen = doc.idalmacen 
		AND m.idarticulo = al.idarticulo
	LEFT JOIN almacen AS a 
		ON a.codalm = doc.idalmacen
WHERE
	doc.idtran = @idtran
ORDER BY
	ar.codigo
GO
