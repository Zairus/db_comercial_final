USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20151207
-- Description:	Control de medicamentos
-- =============================================
ALTER PROCEDURE [dbo].[_ven_rpt_medicamentos]
	@idclasificacion AS INT = 0
	,@fecha1 AS SMALLDATETIME = NULL
	,@fecha2 AS SMALLDATETIME = NULL
AS

SET NOCOUNT ON
SET DATEFORMAT DMY

SELECT @fecha1 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(20), ISNULL(@fecha1, DATEADD(DAY, -30, GETDATE())), 3) + ' 00:00')
SELECT @fecha2 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(20), ISNULL(@fecha2, GETDATE()), 3) + ' 23:59')

SELECT * 
FROM
	(
		SELECT
			[descripcion] = a.codigo + ' ' + a.nombre
			,[fecha] = vt.fecha
			,[movimiento] = 'Venta'
			,[cantidad] = vtm.cantidad_facturada
			,[proveedor] = ''
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

		UNION ALL

		SELECT
			[descripcion] = a.codigo + ' ' + a.nombre
			,[fecha] = ct.fecha
			,[movimiento] = 'Compra'
			,[cantidad] = ctm.cantidad_facturada
			,[proveedor] = p.nombre

			,[medico] = ''
			,[cedula] = ''
			,[registro] = ''
			,[receta_folio] = ''
			,[existencia] = ISNULL((
				SELECT TOP 1
					itm.existencia
				FROM
					ew_com_ordenes_mov AS corm
					LEFT JOIN ew_com_transacciones_mov AS crem
						ON crem.idmov2 = corm.idmov
					LEFT JOIN ew_inv_transacciones_mov AS itm
						ON itm.idmov2 = crem.idmov
				WHERE
					corm.idmov = ctm.idmov2
			), 800)
		FROM
			ew_com_transacciones AS ct
			LEFT JOIN ew_com_transacciones_mov AS ctm
				ON ctm.idtran = ct.idtran
			LEFT JOIN ew_proveedores AS p
				ON p.idproveedor = ct.idproveedor
			LEFT JOIN ew_articulos AS a
				ON a.idarticulo = ctm.idarticulo
			LEFT JOIN ew_articulos_clasificacion AS ac
				ON ac.idarticulo = ctm.idarticulo
		WHERE
			ct.cancelado = 0
			AND ct.transaccion = 'CFA1'
			AND (
				SELECT COUNT(*)
				FROM
					ew_articulos_datos AS ad
				WHERE
					ad.idarticulo = ctm.idarticulo
			) > 0
			AND ac.idclasificacion = (CASE WHEN @idclasificacion = 0 THEN ac.idclasificacion ELSE @idclasificacion END)
			AND ct.fecha BETWEEN @fecha1 AND @fecha2
	) AS vmed
ORDER BY
	[descripcion] ASC
	,[fecha] ASC
GO
