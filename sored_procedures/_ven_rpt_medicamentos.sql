USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20151207
-- Description:	Control de medicamentos
-- =============================================
ALTER PROCEDURE _ven_rpt_medicamentos
	@idclasificacion AS INT = 0
	,@fecha1 AS SMALLDATETIME = NULL
	,@fecha2 AS SMALLDATETIME = NULL
AS

SET NOCOUNT ON

SELECT @fecha1 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(20), ISNULL(@fecha1, DATEADD(DAY, -30, GETDATE())), 3) + ' 00:00')
SELECT @fecha2 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(20), ISNULL(@fecha2, GETDATE()), 3) + ' 23:59')

SELECT
	[descripcion] = a.codigo + ' ' + a.nombre
	,[fecha] = vt.fecha
	,[movimiento] = 'Venta'
	,[cantidad] = vtm.cantidad_facturada
	,[proveedor] = ISNULL((
		SELECT TOP 1 
			p.nombre
		FROM 
			ew_com_transacciones_mov AS ctm 
			LEFT JOIN ew_com_transacciones AS ct
				ON ct.idtran = ctm.idtran
			LEFT JOIN ew_proveedores AS p
				ON p.idproveedor = ct.idproveedor
		WHERE 
			ct.transaccion LIKE 'CFA%'
			AND ct.cancelado = 0
			AND ctm.idarticulo = vtm.idarticulo
		ORDER BY
			ct.fecha DESC
	), '-Sin Especificar-')
	,[medico] = ISNULL((
		SELECT vtmd.valor 
		FROM 
			ew_ven_transacciones_mov_datos AS vtmd
		WHERE
			vtmd.idtran = vtm.idtran
			AND vtmd.idarticulo = vtm.idarticulo
			AND vtmd.iddato = 2
	), '')
	,[cedula] = ISNULL((
		SELECT vtmd.valor 
		FROM 
			ew_ven_transacciones_mov_datos AS vtmd
		WHERE
			vtmd.idtran = vtm.idtran
			AND vtmd.idarticulo = vtm.idarticulo
			AND vtmd.iddato = 1
	), '')
	,[registro] = ISNULL((
		SELECT vtmd.valor 
		FROM 
			ew_ven_transacciones_mov_datos AS vtmd
		WHERE
			vtmd.idtran = vtm.idtran
			AND vtmd.idarticulo = vtm.idarticulo
			AND vtmd.iddato = 4
	), '')
	,[receta_folio] = ISNULL((
		SELECT vtmd.valor 
		FROM 
			ew_ven_transacciones_mov_datos AS vtmd
		WHERE
			vtmd.idtran = vtm.idtran
			AND vtmd.idarticulo = vtm.idarticulo
			AND vtmd.iddato = 6
	), '')
	,[existencia] = ISNULL(itm.existencia, 0)
FROM
	ew_ven_transacciones_mov AS vtm
	LEFT JOIN ew_ven_transacciones AS vt
		ON vt.idtran = vtm.idtran
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vtm.idarticulo
	LEFT JOIN ew_inv_transacciones_mov AS itm
		ON itm.tipo = 2
		AND itm.idmov2 = vtm.idmov
	LEFT JOIN ew_articulos_clasificacion AS ac
		ON ac.idarticulo = vtm.idarticulo
WHERE
	vt.transaccion LIKE 'EFA%'
	AND vt.cancelado = 0
	AND (
		SELECT COUNT(*)
		FROM
			ew_articulos_datos AS ad
		WHERE
			ad.idarticulo = vtm.idarticulo
	) > 0
	AND ac.idclasificacion = (CASE WHEN @idclasificacion = 0 THEN ac.idclasificacion ELSE @idclasificacion END)
	AND vt.fecha BETWEEN @fecha1 AND @fecha2
ORDER BY
	(a.codigo + ' ' + a.nombre) ASC
	,vt.fecha ASC
GO
