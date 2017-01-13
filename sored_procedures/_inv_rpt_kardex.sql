USE db_comercial_final
GO
/******************************************************************
-- Creado : Fernanda Corona
-- Fecha  : 2010 ENERO
-- Ejempl : SET DATEFORMAT DMY EXEC _inv_rpt_Kardex  1,'16/01/12','15/11/12','0173'
********************************************************************/
ALTER PROCEDURE [dbo].[_inv_rpt_kardex]
	@idalmacen AS SMALLINT = 0
	,@fecha1 AS VARCHAR(8)
	,@fecha2 AS VARCHAR(8)
	,@codigo AS VARCHAR(30) = ''
AS

SET NOCOUNT ON

DECLARE 
	@f1 SMALLDATETIME
	,@f2 SMALLDATETIME
	
SELECT @f1 = CONVERT(VARCHAR(8), @fecha1, 3) + ' 00:00:00'
SELECT @f2 = CONVERT(VARCHAR(8), @fecha2, 3) + ' 23:59:59'	

SELECT
	[idtran] = it.idtran
	,[idalmacen] = itm.idalmacen
	,[almacen] = a.nombre
	,[cancelado] = it.cancelado
	,[transaccion] = o.nombre
	,[folio] = it.folio
	,[idconcepto] = it.idconcepto
	,[concepto] = oc.nombre
	,[fecha] = it.fecha
	,[idarticulo] = itm.idarticulo
	,[codigo] = ea.codigo
	,[articulo] = ea.codigo + ' - ' + ea.nombre + ' ('+ ea.nombre_corto + ')' + ' - ' + m.nombre
	,[cantidad] = itm.cantidad
	,[tipo] = itm.tipo
	,[entrada] = (CASE WHEN itm.tipo = 1 THEN itm.cantidad ELSE 0 END)
	,[salida] = (CASE WHEN itm.tipo = 2 THEN itm.cantidad ELSE 0 END)
	,[existencia] = (case when itm.tipo=1 then itm.cantidad else 0 end)-(case when itm.tipo=2 then itm.cantidad else 0 end)
	,[cu] = (itm.costo / itm.cantidad)
	,[costo] = itm.costo
	,[costo] = (
			 (CASE WHEN itm.tipo = 1 THEN itm.cantidad ELSE 0 END) * (itm.costo/itm.cantidad)
	)
	,[empresa] = dbo.fn_sys_empresa()			
	,[unidad] = u.codigo
	,[comentario] = cap.serie + ' ' + cap.lote + (CASE WHEN st.idtran IS NOT NULL THEN '   ' + st.transaccion + '-' + st.folio + '  ' ELSE '' END) 
	,[existencia_actual] = aa.existencia
FROM 
	ew_inv_movimientos AS itm
	LEFT JOIN ew_inv_transacciones AS it 
		ON it.idtran = itm.idtran
	LEFT JOIN conceptos AS oc 
		ON oc.idconcepto = it.idconcepto
	LEFT JOIN ew_articulos AS ea 
		ON ea.idarticulo = itm.idarticulo
	LEFT JOIN ew_inv_almacenes AS a 
		ON a.idalmacen = itm.idalmacen
	LEFT JOIN ew_cat_unidadesMedida AS u 
		ON u.idum=ea.idum_almacen
	LEFT JOIN ew_inv_capas AS cap 
		ON cap.idcapa=itm.idcapa
	LEFT JOIN objetos AS o 
		ON o.codigo=itm.transaccion
	LEFT JOIN ew_sys_transacciones AS st 
		ON st.idtran=it.idtran2 
	LEFT JOIN ew_cat_marcas AS m 
		ON m.idmarca = ea.idmarca
	LEFT JOIN ew_articulos_almacenes AS aa 
		ON aa.idarticulo = ea.idarticulo 
		AND aa.idalmacen = itm.idalmacen
WHERE
	itm.tipo IN (1,2)
	AND itm.idalmacen = (CASE @idalmacen WHEN 0 THEN itm.idalmacen ELSE @idalmacen END)
	AND ea.codigo = (CASE @codigo WHEN '' THEN ea.codigo ELSE @codigo END)		
	AND it.fecha BETWEEN @f1 AND @f2
ORDER BY 
	it.idalmacen
	, m.nombre
	, ea.nombre
	, itm.idr
GO
