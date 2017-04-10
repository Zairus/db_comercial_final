USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091017
-- Description:	Movimientos de inventario
-- Ejemplo: SET DATEFORMAT DMY EXEC _inv_rpt_movimientos 1, 1, -1, '20/12/09', '01/08/11'
-- =============================================
ALTER PROCEDURE [dbo].[_inv_rpt_movimientos]
	@idsucursal AS SMALLINT
	,@idalmacen AS SMALLINT
	,@objeto AS SMALLINT
	,@fecha1 AS VARCHAR(8)
	,@fecha2 AS VARCHAR(8)
AS

SET NOCOUNT ON

DECLARE 
	@f1 SMALLDATETIME
	,@f2 SMALLDATETIME
	
SELECT @f1 = CONVERT(VARCHAR(8), @fecha1, 3) + ' 00:00:00'
SELECT @f2 = CONVERT(VARCHAR(8), @fecha2, 3) + ' 23:59:59'	

SELECT
	[sucursal] = s.nombre
	,[almacen] = a.nombre
	,it.transaccion
	,[movimiento] = o.nombre
	,[fecha] = it.fecha
	,[folio] = it.folio
	,[concepto] = ISNULL(c.nombre, 'Sin Clasificar')
	,[total] = it.total
	,[referencia] = it.referencia
	,[comentario] = it.comentario
   	,[idtran] = it.idtran
	,[empresa] = dbo.fn_sys_empresa()	
	,[estatus] = dbo.fn_sys_estadoActualNombre(it.idtran)
FROM 
	ew_inv_transacciones AS it
	LEFT JOIN ew_sys_sucursales AS s 
		ON s.idsucursal = it.idsucursal
	LEFT JOIN ew_inv_almacenes AS a
		ON a.idalmacen = it.idalmacen 
		AND a.idsucursal = s.idsucursal
	LEFT JOIN conceptos AS c
		ON c.idconcepto = it.idconcepto
	LEFT JOIN objetos AS o ON 
		o.codigo = it.transaccion
WHERE
	it.idsucursal = (CASE @idsucursal WHEN 0 THEN it.idsucursal ELSE @idsucursal END)
	AND it.idalmacen = (CASE @idalmacen WHEN 0 THEN it.idalmacen ELSE @idalmacen END)
	AND o.objeto = (CASE @objeto WHEN -1 THEN o.objeto ELSE @objeto END)
	AND it.fecha BETWEEN @f1 AND @f2

UNION ALL

SELECT
	[sucursal] = s.nombre
	,[almacen] = a.nombre
	,it.transaccion
	,[movimiento] = o.nombre
	,[fecha] = it.fecha
	,[folio] = it.folio
	,[concepto] = ISNULL(c.nombre, 'Sin Clasificar')
	,[total] = it.total
	,[referencia] = it.referencia
	,[comentario] = it.comentario
   	,[idtran] = it.idtran
	,[empresa] = dbo.fn_sys_empresa()	
	,[estatus] = dbo.fn_sys_estadoActualNombre(it.idtran)
FROM ew_inv_documentos AS it
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = it.idsucursal
	LEFT JOIN ew_inv_almacenes AS a
		ON a.idalmacen = it.idalmacen 
		AND a.idsucursal=s.idsucursal
	LEFT JOIN conceptos AS c
		ON c.idconcepto = it.idconcepto
	LEFT JOIN objetos AS o
		ON o.codigo = it.transaccion
WHERE
	it.idsucursal = (CASE @idsucursal WHEN 0 THEN it.idsucursal ELSE @idsucursal END)
	AND it.idalmacen = (CASE @idalmacen WHEN 0 THEN it.idalmacen ELSE @idalmacen END)
	AND o.objeto = (CASE @objeto WHEN -1 THEN o.objeto ELSE @objeto END)
	AND it.fecha BETWEEN @f1 AND @f2

UNION ALL

SELECT
	[sucursal] = s.nombre
	,[almacen] = a.nombre
	,it.transaccion
	,[movimiento] = o.nombre
	,[fecha] = it.fecha
	,[folio] = it.folio
	,[concepto] = ISNULL(c.nombre, 'Sin Clasificar')
	,[total] = it.total
	,[referencia] = it.folio
	,[comentario] = it.comentario
   	,[idtran] = it.idtran
	,[empresa] = dbo.fn_sys_empresa()	
	,[estatus] = dbo.fn_sys_estadoActualNombre(it.idtran)
FROM 
	ew_com_transacciones AS it
	LEFT JOIN ew_sys_sucursales AS s 
		ON s.idsucursal = it.idsucursal
	LEFT JOIN ew_inv_almacenes AS a
		ON a.idalmacen = it.idalmacen 
		AND a.idsucursal=s.idsucursal
	LEFT JOIN conceptos AS c
		ON c.idconcepto = it.idconcepto
	LEFT JOIN objetos AS o
		ON o.codigo = it.transaccion
WHERE
	it.idsucursal = (CASE @idsucursal WHEN 0 THEN it.idsucursal ELSE @idsucursal END)
	AND it.idalmacen = (CASE @idalmacen WHEN 0 THEN it.idalmacen ELSE @idalmacen END)
	AND o.objeto = (CASE @objeto WHEN -1 THEN o.objeto ELSE @objeto END)
	AND it.fecha BETWEEN @f1 AND @f2
ORDER BY
	almacen, it.transaccion
GO
