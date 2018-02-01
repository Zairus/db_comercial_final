USE db_comercial_final
GO
-- =============================================
-- Author:		Fernanda Corona
-- Create date: ENERO 2010
-- Description:	Auxiliar de movimientos de ventas detallada
-- Ejemplo:  EXEC _ven_rpt_movtosDetallado -1,1,1,-1,-1,'01/12/2009','01/04/2011',0,0
-- =============================================
ALTER PROCEDURE [dbo].[_ven_rpt_movtosDetallado]
	@idmoneda AS SMALLINT = -1
	,@idsucursal AS SMALLINT = 0
	,@idalmacen AS SMALLINT = 0
	,@objeto AS INT = 0
	,@idestado AS INT = -1
	,@fecha1 AS VARCHAR(50)
	,@fecha2 AS VARCHAR(50)
	,@idcliente AS SMALLINT = 0
	,@idarticulo AS INT = 0
AS

SET DATEFORMAT DMY
SET NOCOUNT ON

SELECT @fecha2 = @fecha2 + ' 23:59'

SELECT 
	[moneda] = m.nombre
	,[sucursal] = s.nombre
	,[almacen] = s.nombre + ' - ' + a.nombre
	,[cod_tran] = o.nombre
	,[movimiento] = o.nombre
	,[concepto] = ISNULL(cc.nombre, 'Sin Especificar')
	,[estado] = ISNULL(oe.nombre, '')
	,[codigo] = '[' + ec.codigo + '] ' + ec.nombre
	,[idtran] = vt.idtran
	,[fecha] = vt.fecha
	,[folio] = vt.folio
	,[cancelado] = vt.cancelado
	,[articulo] = '[' + ea.codigo + '] ' + ea.nombre + ' ' + CONVERT(VARCHAR(MAX),vm.comentario)
	,[cantidad_solicitada] = vm.cantidad_solicitada
	,[cantidad_autorizada] = vm.cantidad_autorizada
	,[cantidad_surtida] = vm.cantidad_surtida
	,[pendiente] = vm.pendiente
	,[precio_unitario] = vm.precio_unitario
	,[impuesto1] = vm.impuesto1
	,[importe] = vm.importe
	,[total] = vm.total
	,[marca]= mr.nombre
	,[empresa] = dbo.fn_sys_empresa()
FROM
	ven_movtosDetallado AS vm
	LEFT JOIN  ven_transacciones AS vt 
		ON vt.idtran = vm.idtran
	LEFT JOIN ew_sys_sucursales AS s 
		ON s.idsucursal = vt.idsucursal
	LEFT JOIN ew_inv_almacenes AS a 
		ON a.idalmacen = vt.idalmacen
	LEFT JOIN objetos AS o 
		ON o.codigo = vt.transaccion
	LEFT JOIN ew_clientes AS ec 
		ON ec.idcliente = vt.idcliente
	LEFT JOIN ew_articulos AS ea 
		ON ea.idarticulo = vm.idarticulo
	LEFT JOIN c_transacciones AS t 
		ON t.idtran=vt.idtran 
	LEFT JOIN objetos_estados AS oe 
		ON oe.idestado = t.idestado 
		AND oe.objeto = o.objeto
	LEFT JOIN ew_ban_monedas AS m
		ON m.idmoneda = vt.idmoneda
	LEFT JOIN conceptos AS cc 
		ON cc.idconcepto = vt.idconcepto
	LEFT JOIN ew_cat_marcas AS mr 
		ON ea.idmarca = mr.idmarca
WHERE
	vt.cancelado = 0
	AND o.menu = 4
	AND (
		(
			ea.inventariable = 1
			AND vm.objlevel = 0
		)
		OR (
			ea.inventariable = 0
			AND vm.objlevel = 1
		)
	)
	--AND vm.objlevel IN (0, 1)
	AND vt.idmoneda = (CASE @idmoneda WHEN -1 THEN vt.idmoneda ELSE @idmoneda END)
	AND vt.idsucursal = (CASE @idsucursal WHEN 0 THEN vt.idsucursal ELSE @idsucursal END)
	AND vt.idalmacen = (CASE @idalmacen WHEN 0 THEN vt.idalmacen ELSE @idalmacen END)
	AND o.objeto = (CASE @objeto WHEN -1 THEN o.objeto ELSE @objeto END)
	AND t.idestado = (CASE @idestado WHEN -1 THEN t.idestado ELSE @idestado END)		
	AND vt.idcliente =(CASE @idcliente WHEN 0 THEN vt.idcliente ELSE @idcliente END)	
	AND vm.idarticulo =(CASE @idarticulo WHEN '' THEN vm.idarticulo ELSE @idarticulo END)		
	AND vt.fecha BETWEEN @fecha1 AND @fecha2
ORDER BY
	vt.idsucursal
	,vt.idalmacen
	,vt.idmoneda
	,vt.transaccion
	,vt.folio
GO
