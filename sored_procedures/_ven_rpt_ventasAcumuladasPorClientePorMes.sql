USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160118
-- Description:	Ventas acumuladas por cliente por mes
-- =============================================
ALTER PROCEDURE _ven_rpt_ventasAcumuladasPorClientePorMes
	@ejercicio AS INT = NULL
	,@idcliente AS INT = 0
AS

SET NOCOUNT ON

SELECT @ejercicio = ISNULL(@ejercicio, YEAR(GETDATE()))

SELECT
	c.codigo
	,c.nombre

	,[periodo1] = ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 1 THEN vt.subtotal ELSE 0 END), 0)
	,[periodo2] = ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 2 THEN vt.subtotal ELSE 0 END), 0)
	,[periodo3] = ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 3 THEN vt.subtotal ELSE 0 END), 0)
	,[periodo4] = ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 4 THEN vt.subtotal ELSE 0 END), 0)
	,[periodo5] = ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 5 THEN vt.subtotal ELSE 0 END), 0)
	,[periodo6] = ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 6 THEN vt.subtotal ELSE 0 END), 0)
	,[periodo7] = ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 7 THEN vt.subtotal ELSE 0 END), 0)
	,[periodo8] = ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 8 THEN vt.subtotal ELSE 0 END), 0)
	,[periodo9] = ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 9 THEN vt.subtotal ELSE 0 END), 0)
	,[periodo10] = ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 10 THEN vt.subtotal ELSE 0 END), 0)
	,[periodo11] = ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 11 THEN vt.subtotal ELSE 0 END), 0)
	,[periodo12] = ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 12 THEN vt.subtotal ELSE 0 END), 0)

	,[venta] = ISNULL(SUM(vt.subtotal), 0)
FROM
	ew_clientes AS c
	LEFT JOIN ew_ven_transacciones AS vt
		ON vt.cancelado = 0
		AND (
			vt.transaccion LIKE 'EFA%'
			OR vt.transaccion LIKE 'EDE%'
		)
		AND YEAR(vt.fecha) = @ejercicio
		AND vt.idcliente = c.idcliente
WHERE
	c.idcliente = (CASE WHEN @idcliente = 0 THEN c.idcliente ELSE @idcliente END)
GROUP BY
	c.codigo
	,c.nombre
HAVING
	ISNULL(SUM(vt.subtotal), 0) > 0
GO
