USE db_comercial_final
GO
-- =============================================
-- Author:		Fernanda Corona
-- Create date: FEBRERO 2010
-- Description:	Reporte Transaccion de Traspaso entre almacenes.
-- Ejemplo : EXEC _inv_rpt_GDT1 873
-- =============================================
ALTER PROCEDURE [dbo].[_inv_rpt_GDT1]
	@idtran INT
AS

SET NOCOUNT ON

SELECT 
	[concepto] = (CASE WHEN dbo.fn_sys_nombreConcepto(doc.idconcepto) = '[no definido]' THEN o.nombre ELSE dbo.fn_sys_nombreConcepto(doc.idconcepto) END)
	,[sucursal] = s.nombre
	,[almacen] = alm.nombre
	,[suc_destino] = (SELECT sd.nombre FROM sucursales AS sd WHERE sd.idsucursal = doc.idsucursal_destino)
	,[alm_destino] = (SELECT ad.nombre FROM almacen AS ad WHERE ad.codalm = doc.idalmacen_destino)
	,[fecha] = doc.fecha
	,[folio] = doc.folio
	,[transaccion] = doc.transaccion
	,[referencia] = doc.referencia
	,[usuario] = u.nombre
	,[total] = doc.total
	,[doctocom]=doc.comentario
	,[consecutivo] = mov.consecutivo
	,[idarticulo] = mov.idarticulo
	,[codarticulo] = a.codigo
	,[descripcion] = a.nombre
	,[serie] = a.series
	,[series] = mov.series
	,[unidad] = um.nombre
	,[cantidad] = (CASE WHEN mov.cantidad = 0 THEN mov.solicitado ELSE mov.cantidad END)
	,[ultimo_costo] = aa.costo_ultimo
	,[costo_promedio] = aa.costo_promedio
	,[costo_unitario] = CONVERT(DECIMAL(18,6), (mov.costo / (CASE WHEN mov.cantidad = 0 THEN mov.solicitado ELSE mov.cantidad END)))
	,[costo] = mov.costo
	,[comentario] = doc.comentario
FROM 
	ew_inv_documentos_mov AS mov
	LEFT JOIN ew_inv_documentos AS doc 
		ON doc.idtran = mov.idtran
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = mov.idarticulo 
	LEFT JOIN ew_articulos_almacenes AS aa 	
		ON aa.idarticulo = mov.idarticulo AND aa.idalmacen = mov.idalmacen
	LEFT JOIN ew_cat_unidadesMedida AS um 
		ON um.idum = mov.idum
	LEFT JOIN usuarios AS u 
		ON u.idu = doc.idu
	LEFT JOIN sucursales AS s 
		ON s.idsucursal = doc.idsucursal
	LEFT JOIN ew_inv_almacenes AS alm 
		ON alm.idalmacen = doc.idalmacen
	LEFT JOIN ew_inv_almacenes AS almmov 
		ON almmov.idalmacen = mov.idalmacen
	LEFT JOIN objetos AS o
		ON o.codigo = doc.transaccion
WHERE 
	doc.idtran=@idtran
ORDER BY 
	mov.idtran, mov.consecutivo
GO
