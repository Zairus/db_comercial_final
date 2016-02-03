USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160122
-- Description:	Acumulado de ventas por cliente
-- =============================================
ALTER PROCEDURE _ven_rpt_acumuladoVentasPorCliente
	@codcliente AS VARCHAR(30) = ''
	,@codvend AS VARCHAR(30) = ''
	,@fecha1 AS SMALLDATETIME = NULL
	,@fecha2 AS SMALLDATETIME = NULL
AS

SET NOCOUNT ON

SELECT @fecha1 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha1, DATEADD(DAY, -30, GETDATE())), 3) + ' 00:00')
SELECT @fecha2 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha2, GETDATE()), 3) + ' 23:59')

SELECT
	c.codigo
	,c.nombre
	,[subtotal] = SUM(vt.subtotal)
	,[impuesto] = SUM(vt.impuesto1 + vt.impuesto2)
	,[total] = SUM(vt.total)
	,[fecha1] = @fecha1
	,[fecha2] = @fecha2
FROM
	ew_ven_transacciones AS vt
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = vt.idcliente
	LEFT JOIN ew_ven_vendedores AS v
		ON v.idvendedor = vt.idvendedor
WHERE
	vt.cancelado = 0
	AND (
		vt.transaccion LIKE 'EFA%'
		OR vt.transaccion LIKE 'EDE%'
	)
	AND c.codigo = (CASE WHEN @codcliente = '' THEN c.codigo ELSE @codcliente END)
	AND v.codigo = (CASE WHEN @codvend = '' THEN v.codigo ELSE @codvend END)
	AND vt.fecha BETWEEN @fecha1 AND @fecha2
GROUP BY
	c.codigo
	,c.nombre
ORDER BY
	c.codigo
GO
