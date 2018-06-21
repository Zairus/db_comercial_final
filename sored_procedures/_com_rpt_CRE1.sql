USE [db_comercial_final]
GO
-- ===========================================================
-- Author:		Fernanda Corona
-- Create date: FEBRERO 2010
-- Description:	Reporte Transaccion Recepción y Devolución de 
--              Suministros CRE1 Y CDE1 del modulo de compras.
-- Ejemplo : EXEC _com_rpt_CRE1 100001
-- ============================================================
ALTER PROCEDURE [dbo].[_com_rpt_CRE1] 
	@idtran INT
AS

SET NOCOUNT ON

SELECT 
	[idtran] = doc.idtran
	,[Almacen] = alm.nombre
	,[Sucural] = s.nombre
	,[fecha] = doc.fecha
	,[folio] = doc.folio
	,[transaccion] = doc.transaccion
	,[cancelado] = doc.cancelado
	,[cancelado_fecha] = doc.cancelado_fecha
	,[ordenCompra] = co.folio
	,[codarticulo] = a.codigo
	,[um] = um.codigo
	,[descripcion] = (
		a.nombre
		+ (
			CASE
				WHEN LEN(mov.lote) > 0 THEN 
					CHAR(13)
					+ CHAR(10)
					+ 'Lote: '
					+ mov.lote
					+ ', Cad.: '
					+ CONVERT(VARCHAR(8), [dbo].[fn_inv_fechaCadLote](mov.lote), 3)
				ELSE ''
			END
		)
	)
	,[almmov] = alm.nombre
	,[series] = mov.series
	,[cantidad_ordenada] = mov.cantidad_ordenada
	,[cantidad] = (
		CASE 
			WHEN doc.transaccion = 'CRE1' THEN mov.cantidad_recibida 
			ELSE mov.cantidad_devuelta 
		END
	)
	,[costo_unitario] = mov.costo_unitario
	,[cu] = (mov.importe / mov.cantidad_recibida)
	,[totalMov] = mov.total
	,[d_comentario] = mov.comentario
	,[totaldoc] = doc.total
	,[usuario] = u.nombre
	,[comentario] = doc.comentario
	,[empresa_rpt] = dbo.fn_sys_empresa()
	,[lote] = mov.lote
	,[fecha_caducidad] = mov.fecha_caducidad
	,[estatus_doc] = dbo.fn_sys_estadoActualNombre(doc.idtran)
FROM 
	ew_com_transacciones_mov AS mov
	LEFT JOIN ew_com_transacciones AS doc 
		ON doc.idtran=mov.idtran
	LEFT JOIN ew_com_ordenes AS co 
		ON co.idtran = mov.idtran2
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = mov.idarticulo
	LEFT JOIN ew_cat_unidadesMedida AS um 
		ON um.idum = mov.idum
	LEFT JOIN sucursales AS s 
		ON s.idsucursal=doc.idsucursal
	LEFT JOIN usuarios AS u 
		ON u.idu=doc.idu
	LEFT JOIN almacen As alm 
		ON alm.codalm=doc.idalmacen		
WHERE 
	mov.idtran = @idtran
ORDER BY 
	mov.idtran
	, mov.consecutivo
GO
