USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160215
-- Description:	Auxiliar de existencias
-- =============================================
ALTER PROCEDURE [dbo].[_inv_rpt_articulosExistencias]
	@idalmacen AS SMALLINT = 0
	,@codarticulo1 AS VARCHAR(30) = ''
	,@codarticulo2 AS VARCHAR(30) = ''
	
	,@codfamilia AS VARCHAR(10) = ''
	,@codlinea AS VARCHAR(10) = ''
	,@codsublinea AS VARCHAR(10) = ''

	,@codproveedor AS VARCHAR(30) = ''
	,@fecha1 AS SMALLDATETIME = NULL
	,@fecha2 AS SMALLDATETIME = NULL
AS

SET NOCOUNT ON

SELECT @fecha1 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha1, DATEADD(DAY, -30, GETDATE())), 3) + ' 00:00')
SELECT @fecha2 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha2, GETDATE()), 3) + ' 23:59')

IF @codarticulo2 = ''
	SELECT @codarticulo2 = MAX(codigo) FROM ew_articulos

SELECT
	[almacen] = alm.nombre
	,[codarticulo] = a.codigo
	,[nombre] = a.nombre
	,[familia] = ISNULL(an1.nombre, '')
	,[linea] = ISNULL(an2.nombre, '')
	,[sublinea] = ISNULL(an3.nombre, '')
	,[existencia] = ISNULL(aa.existencia, 0)
	,[venta_ordenados] = [dbo].[fn_inv_existenciaComprometida](a.idarticulo, alm.idalmacen)
	,[disponible] = ISNULL(aa.existencia, 0) - [dbo].[fn_inv_existenciaComprometida](a.idarticulo, alm.idalmacen)
	,[vendidos] = ISNULL((
		SELECT
			SUM(vtm.cantidad_facturada)
		FROM
			ew_ven_transacciones_mov AS vtm
			LEFT JOIN ew_ven_transacciones AS vt
				ON vt.idtran = vtm.idtran
		WHERE
			vt.cancelado = 0
			AND vt.transaccion LIKE 'EFA%'
			AND vt.fecha BETWEEN @fecha1 AND @fecha2
			AND vt.idalmacen = alm.idalmacen
			AND vtm.idarticulo = a.idarticulo
	), 0)
	,[compra_ordenados] = ISNULL((
		SELECT
			SUM(com.cantidad_ordenada - com.cantidad_surtida)
		FROM
			ew_com_ordenes_mov AS com
			LEFT JOIN ew_com_ordenes AS co
				ON co.idtran = com.idtran
			LEFT JOIN ew_sys_transacciones AS st
				ON st.idtran = co.idtran
		WHERE
			co.cancelado = 0
			AND co.transaccion LIKE 'COR%'
			AND st.idestado IN (0, 3, 31, 37, 43, 44)
			AND co.fecha BETWEEN @fecha1 AND @fecha2
			AND co.idalmacen = alm.idalmacen
			AND com.idarticulo = a.idarticulo
	), 0)
	,[fecha_ult_compra] = (
		SELECT TOP 1 
			ct.fecha
		FROM 
			ew_com_transacciones_mov AS ctm
			LEFT JOIN ew_com_transacciones AS ct
				ON ct.idtran = ctm.idtran
		WHERE
			ct.cancelado = 0
			AND ct.transaccion LIKE 'CFA%'
			AND ct.idalmacen = alm.idalmacen
			AND ctm.idarticulo = a.idarticulo
		ORDER BY
			ct.fecha DESC
	)
FROM
	ew_articulos AS a
	LEFT JOIN ew_inv_almacenes AS alm
		ON alm.tipo = 1
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idalmacen = alm.idalmacen
		AND aa.idarticulo = a.idarticulo
	LEFT JOIN ew_articulos_sucursales AS [as]
		ON [as].idsucursal = alm.idsucursal
		AND [as].idarticulo = a.idarticulo
	LEFT JOIN ew_proveedores AS p
		ON p.idproveedor = [as].idproveedor
	LEFT JOIN ew_articulos_niveles AS an1
		ON an1.nivel = 1
		AND an1.codigo = a.nivel1
	LEFT JOIN ew_articulos_niveles AS an2
		ON an2.nivel = 2
		AND an2.codigo = a.nivel2
	LEFT JOIN ew_articulos_niveles AS an3
		ON an3.nivel = 3
		AND an3.codigo = a.nivel3
WHERE
	a.activo = 1
	AND a.idtipo = 0
	AND alm.idalmacen= (CASE WHEN @idalmacen = 0 THEN alm.idalmacen ELSE @idalmacen END)
	AND a.codigo BETWEEN @codarticulo1 AND @codarticulo2
	AND ISNULL(an1.codigo, '') = (CASE WHEN @codfamilia = '' THEN ISNULL(an1.codigo, '') ELSE @codfamilia END)
	AND ISNULL(an2.codigo, '') = (CASE WHEN @codlinea = '' THEN ISNULL(an2.codigo, '') ELSE @codlinea END)
	AND ISNULL(an3.codigo, '') = (CASE WHEN @codsublinea = '' THEN ISNULL(an3.codigo, '') ELSE @codsublinea END)
	AND ISNULL(p.codigo, '') = (CASE WHEN @codproveedor = '' THEN ISNULL(p.codigo, '') ELSE @codproveedor END)
ORDER BY
	alm.idalmacen
	,a.codigo
GO
