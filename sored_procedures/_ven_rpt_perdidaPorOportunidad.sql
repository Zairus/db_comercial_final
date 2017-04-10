USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150922
-- Description:	Pérdida por oportunidad de venta
-- =============================================
ALTER PROCEDURE [dbo].[_ven_rpt_perdidaPorOportunidad]
	@idsucursal AS INT = 0
	,@nivel_codigo AS VARCHAR(20) = ''
	,@idcliente AS INT = 0
	,@idvendedor AS INT = 0
	,@codigo1 AS VARCHAR(30) = ''
	,@codigo2 AS VARCHAR(30) = ''
	,@fecha1 AS SMALLDATETIME = NULL
	,@fecha2 AS SMALLDATETIME = NULL
AS

SET NOCOUNT ON

IF @codigo2 = ''
BEGIN
	SELECT @codigo2 = MAX(codigo) FROM ew_articulos
END

SELECT @fecha1 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha1, DATEADD(DAY, -30, GETDATE())), 3) + ' 00:00')
SELECT @fecha2 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha2, GETDATE()), 3) + ' 23:59')

SELECT 
	[idarticulo] = vom.idarticulo
	,[veces_negado] = COUNT(vo.idtran)
	,[cantidad_ordenada] = SUM(vom.cantidad_ordenada) 
	,[cantidad_surtida] = SUM(vom.cantidad_surtida) 
	,[cantidad_negada] = SUM(vom.cantidad_negada) 
	,[importe] = SUM(vom.precio_unitario * vom.cantidad_negada)
	,[ultima_fecha] = MAX(vo.fecha) 
INTO
	#_tmp_perdidaAcumulado
FROM 
	ew_ven_ordenes_mov AS vom 
	LEFT JOIN ew_ven_ordenes AS vo 
		ON vo.idtran = vom.idtran 
WHERE
	vo.cancelado = 0
	AND vo.transaccion = 'EOR1'
	AND vom.cantidad_negada > 0

	AND vo.idsucursal = (CASE WHEN @idsucursal = 0 THEN vo.idsucursal ELSE @idsucursal END)
	AND vo.idcliente = (CASE WHEN @idcliente = 0 THEN vo.idcliente ELSE @idcliente END)
	AND vo.idvendedor = (CASE WHEN @idvendedor = 0 THEN vo.idvendedor ELSE @idvendedor END)
	AND vo.fecha BETWEEN @fecha1 AND @fecha2
GROUP BY
	vom.idarticulo

SELECT
	a.codigo
	,a.nombre
	,[linea] = ISNULL(an2.nombre, '-Sin clasificar-')
	,[veces_negado] = ISNULL(pa.veces_negado, 0)
	,[cantidad_ordenada] = ISNULL(pa.cantidaD_ordenada, 0)
	,[cantidad_surtida] = ISNULL(pa.cantidad_surtida, 0)
	,[cantidad_negada] = ISNULL(pa.cantidad_negada, 0)
	,[importe] = ISNULL(pa.importe, 0)
	,[ultima_fecha] = ISNULL(pa.ultima_fecha, 0)
FROM 
	ew_articulos AS a
	LEFT JOIN ew_articulos_niveles AS an2
		ON an2.codigo = a.nivel1
	LEFT JOIN #_tmp_perdidaAcumulado AS pa
		ON pa.idarticulo = a.idarticulo
WHERE
	ISNULL(pa.cantidad_negada, 0) > 0
	AND ISNULL(an2.codigo, '') = (CASE WHEN @nivel_codigo = '' THEN ISNULL(an2.codigo, '') ELSE @nivel_codigo END)
	AND a.codigo BETWEEN @codigo1 AND @codigo2

DROP TABLE #_tmp_perdidaAcumulado
GO
