USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180620
-- Description:	Freporte entrada y salida de almacen
-- =============================================
ALTER PROCEDURE [dbo].[_inv_rpt_GDC1]
	@idtran INT
AS

SET NOCOUNT ON

SELECT 
	[concepto] = dbo.fn_sys_nombreConcepto(doc.idconcepto)
	,[sucursal] = s.nombre
	,[almacen] = alm.nombre
	,[fecha] = doc.fecha
	,[folio] = doc.folio
	,[transaccion] = doc.transaccion
	,[referencia] = doc.referencia
	,[usuario]=u.nombre
	,[total] = doc.total
	,[doctocom]=doc.comentario
	,[consecutivo] = mov.consecutivo
	,[tipo] = mov.tipo
	,[almacenmov] = almmov.nombre
	,[idarticulo] = mov.idarticulo
	,[codarticulo] = a.codigo
	,[descripcion] = (
		a.nombre
		+ (
			CASE
				WHEN LEN(mov.lote) > 0 THEN
					'Lote: ' 
					+ mov.lote
					+ ', Cad.: '
					+ CONVERT(VARCHAR(8), [dbo].[fn_inv_fechaCadLote](mov.lote), 3)
				ELSE ''
			END
		)
	)
	,[serie] = a.series
	,[series] = mov.series
	,[unidad] = um.nombre
	,[cantidad] = mov.cantidad
	,[existencia] = mov.existencia
	,[ultimo_costo] = aa.costo_ultimo
	,[costo_promedio] = aa.costo_promedio
	,[costo_unitario] = CONVERT(DECIMAL(18,6), (mov.costo / mov.cantidad))
	,[costo] = mov.costo
	,[afectainv] = mov.afectainv
	,[comentario] = mov.comentario
FROM 
	ew_inv_transacciones_mov AS mov
	LEFT JOIN ew_inv_transacciones AS doc 
		ON doc.idtran = mov.idtran
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = mov.idarticulo 
	LEFT JOIN ew_articulos_almacenes AS aa 	
		ON aa.idarticulo = mov.idarticulo 
		AND aa.idalmacen = mov.idalmacen
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
WHERE 
	doc.idtran = @idtran
ORDER BY 
	mov.idtran
	, mov.consecutivo
GO
