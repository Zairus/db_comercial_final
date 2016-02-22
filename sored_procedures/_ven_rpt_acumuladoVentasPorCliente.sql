USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160122
-- Description:	Acumulado de ventas por cliente
-- =============================================
ALTER PROCEDURE [dbo].[_ven_rpt_acumuladoVentasPorCliente]
	@codcliente AS VARCHAR(30) = ''
	,@codvend AS VARCHAR(30) = ''
	,@fecha1 AS SMALLDATETIME = NULL
	,@fecha2 AS SMALLDATETIME = NULL
AS

SET NOCOUNT ON

SELECT @fecha1 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha1, DATEADD(DAY, -30, GETDATE())), 3) + ' 00:00')
SELECT @fecha2 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha2, GETDATE()), 3) + ' 23:59')

SELECT
	acum.codigo
	,acum.nombre
	,[subtotal] = SUM(acum.subtotal)
	,[impuesto] = SUM(acum.impuesto)
	,[total] = SUM(acum.subtotal)
FROM (
	SELECT
		[codigo] = c.codigo
		,[nombre] = c.nombre
		,[subtotal] = (vt.subtotal * (CASE WHEN vt.transaccion LIKE 'EFA%' THEN 1 ELSE -1 END))
		,[impuesto] = ((vt.impuesto1 + vt.impuesto2) * (CASE WHEN vt.transaccion LIKE 'EFA%' THEN 1 ELSE -1 END))
		,[total] = (vt.total * (CASE WHEN vt.transaccion LIKE 'EFA%' THEN 1 ELSE -1 END))
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
		AND ISNULL(v.codigo, '') = (CASE WHEN @codvend = '' THEN ISNULL(v.codigo, '') ELSE @codvend END)
		AND vt.fecha BETWEEN @fecha1 AND @fecha2

	UNION ALL

	SELECT
		[codigo] = c.codigo
		,[nombre] = c.nombre
		,[subtotal] = ct.subtotal * -1
		,[impuesto] = (ct.impuesto1 + ct.impuesto2) * -1
		,[total] = ct.total * -1
	FROM
		ew_cxc_transacciones AS ct
		LEFT JOIN ew_clientes AS c
			ON c.idcliente = ct.idcliente
		LEFT JOIN ew_clientes_terminos AS ctr
			ON ctr.idcliente = ct.idcliente
		LEFT JOIN ew_ven_vendedores AS v
			ON v.idvendedor = ctr.idvendedor
	WHERE
		ct.cancelado = 0
		AND ct.transaccion = 'FDA2'
		AND ct.idconcepto IN (20, 30)
		AND c.codigo = (CASE WHEN @codcliente = '' THEN c.codigo ELSE @codcliente END)
		AND ISNULL(v.codigo, '') = (CASE WHEN @codvend = '' THEN ISNULL(v.codigo, '') ELSE @codvend END)
		AND ct.fecha BETWEEN @fecha1 AND @fecha2
) AS acum
GROUP BY
	acum.codigo
	,acum.nombre
ORDER BY
	acum.codigo
GO
