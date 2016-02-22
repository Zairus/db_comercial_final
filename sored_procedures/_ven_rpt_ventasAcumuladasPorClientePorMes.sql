USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160118
-- Description:	Ventas acumuladas por cliente por mes
-- =============================================
ALTER PROCEDURE [dbo].[_ven_rpt_ventasAcumuladasPorClientePorMes]
	@ejercicio AS INT = NULL
	,@idcliente AS INT = 0
AS

SET NOCOUNT ON

SELECT @ejercicio = ISNULL(@ejercicio, YEAR(GETDATE()))

SELECT
	c.codigo
	,c.nombre

	,[periodo1] = (
		ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 1 THEN vt.subtotal * (CASE WHEN vt.transaccion LIKE 'EFA%' THEN 1 ELSE -1 END) ELSE 0 END), 0) 
		-ISNULL((
			SELECT SUM(ct.subtotal)
			FROM ew_cxc_transacciones AS ct 
			WHERE 
				ct.cancelado = 0 
				AND ct.transaccion = 'FDA2' 
				AND ct.idconcepto IN (20, 30) 
				AND ct.idcliente = c.idcliente 
				AND MONTH(ct.fecha) = 1 
				AND YEAR(ct.fecha) = @ejercicio
		), 0)
	)
	,[periodo2] = (
		ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 2 THEN vt.subtotal * (CASE WHEN vt.transaccion LIKE 'EFA%' THEN 1 ELSE -1 END)  ELSE 0 END), 0) 
		-ISNULL((
			SELECT SUM(ct.subtotal) 
			FROM ew_cxc_transacciones AS ct 
			WHERE 
				ct.cancelado = 0 
				AND ct.transaccion = 'FDA2' 
				AND ct.idconcepto IN (20, 30) 
				AND ct.idcliente = c.idcliente 
				AND MONTH(ct.fecha) = 2
				AND YEAR(ct.fecha) = @ejercicio
		), 0)
	)
	,[periodo3] = (
		ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 3 THEN vt.subtotal * (CASE WHEN vt.transaccion LIKE 'EFA%' THEN 1 ELSE -1 END)  ELSE 0 END), 0) 
		-ISNULL((
			SELECT SUM(ct.subtotal) 
			FROM ew_cxc_transacciones AS ct 
			WHERE 
				ct.cancelado = 0 
				AND ct.transaccion = 'FDA2' 
				AND ct.idconcepto IN (20, 30) 
				AND ct.idcliente = c.idcliente 
				AND MONTH(ct.fecha) = 3
				AND YEAR(ct.fecha) = @ejercicio
		), 0)
	)
	,[periodo4] = (
		ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 4 THEN vt.subtotal * (CASE WHEN vt.transaccion LIKE 'EFA%' THEN 1 ELSE -1 END)  ELSE 0 END), 0) 
		-ISNULL((
			SELECT SUM(ct.subtotal) 
			FROM ew_cxc_transacciones AS ct 
			WHERE 
				ct.cancelado = 0 
				AND ct.transaccion = 'FDA2' 
				AND ct.idconcepto IN (20, 30) 
				AND ct.idcliente = c.idcliente 
				AND MONTH(ct.fecha) = 4
				AND YEAR(ct.fecha) = @ejercicio
		), 0)
	)
	,[periodo5] = (
		ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 5 THEN vt.subtotal * (CASE WHEN vt.transaccion LIKE 'EFA%' THEN 1 ELSE -1 END)  ELSE 0 END), 0) 
		-ISNULL((
			SELECT SUM(ct.subtotal) 
			FROM ew_cxc_transacciones AS ct 
			WHERE 
				ct.cancelado = 0 
				AND ct.transaccion = 'FDA2' 
				AND ct.idconcepto IN (20, 30) 
				AND ct.idcliente = c.idcliente 
				AND MONTH(ct.fecha) = 5
				AND YEAR(ct.fecha) = @ejercicio
		), 0)
	)
	,[periodo6] = (
		ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 6 THEN vt.subtotal * (CASE WHEN vt.transaccion LIKE 'EFA%' THEN 1 ELSE -1 END)  ELSE 0 END), 0) 
		-ISNULL((
			SELECT SUM(ct.subtotal) 
			FROM ew_cxc_transacciones AS ct 
			WHERE 
				ct.cancelado = 0 
				AND ct.transaccion = 'FDA2' 
				AND ct.idconcepto IN (20, 30) 
				AND ct.idcliente = c.idcliente 
				AND MONTH(ct.fecha) = 6
				AND YEAR(ct.fecha) = @ejercicio
		), 0)
	)
	,[periodo7] = (
		ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 7 THEN vt.subtotal * (CASE WHEN vt.transaccion LIKE 'EFA%' THEN 1 ELSE -1 END)  ELSE 0 END), 0) 
		-ISNULL((
			SELECT SUM(ct.subtotal) 
			FROM ew_cxc_transacciones AS ct 
			WHERE 
				ct.cancelado = 0 
				AND ct.transaccion = 'FDA2' 
				AND ct.idconcepto IN (20, 30) 
				AND ct.idcliente = c.idcliente 
				AND MONTH(ct.fecha) = 7
				AND YEAR(ct.fecha) = @ejercicio
		), 0)
	)
	,[periodo8] = (
		ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 8 THEN vt.subtotal * (CASE WHEN vt.transaccion LIKE 'EFA%' THEN 1 ELSE -1 END)  ELSE 0 END), 0) 
		-ISNULL((
			SELECT SUM(ct.subtotal) 
			FROM ew_cxc_transacciones AS ct 
			WHERE 
				ct.cancelado = 0 
				AND ct.transaccion = 'FDA2' 
				AND ct.idconcepto IN (20, 30) 
				AND ct.idcliente = c.idcliente 
				AND MONTH(ct.fecha) = 8
				AND YEAR(ct.fecha) = @ejercicio
		), 0)
	)
	,[periodo9] = (
		ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 9 THEN vt.subtotal * (CASE WHEN vt.transaccion LIKE 'EFA%' THEN 1 ELSE -1 END)  ELSE 0 END), 0) 
		-ISNULL((
			SELECT SUM(ct.subtotal) 
			FROM ew_cxc_transacciones AS ct 
			WHERE 
				ct.cancelado = 0 
				AND ct.transaccion = 'FDA2' 
				AND ct.idconcepto IN (20, 30) 
				AND ct.idcliente = c.idcliente 
				AND MONTH(ct.fecha) = 9
				AND YEAR(ct.fecha) = @ejercicio
		), 0)
	)
	,[periodo10] = (
		ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 10 THEN vt.subtotal * (CASE WHEN vt.transaccion LIKE 'EFA%' THEN 1 ELSE -1 END)  ELSE 0 END), 0) 
		-ISNULL((
			SELECT SUM(ct.subtotal) 
			FROM ew_cxc_transacciones AS ct 
			WHERE 
				ct.cancelado = 0 
				AND ct.transaccion = 'FDA2' 
				AND ct.idconcepto IN (20, 30) 
				AND ct.idcliente = c.idcliente 
				AND MONTH(ct.fecha) = 10
				AND YEAR(ct.fecha) = @ejercicio
		), 0)
	)
	,[periodo11] = (
		ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 11 THEN vt.subtotal * (CASE WHEN vt.transaccion LIKE 'EFA%' THEN 1 ELSE -1 END)  ELSE 0 END), 0) 
		-ISNULL((
			SELECT SUM(ct.subtotal) 
			FROM ew_cxc_transacciones AS ct 
			WHERE 
				ct.cancelado = 0 
				AND ct.transaccion = 'FDA2' 
				AND ct.idconcepto IN (20, 30) 
				AND ct.idcliente = c.idcliente 
				AND MONTH(ct.fecha) = 11
				AND YEAR(ct.fecha) = @ejercicio
		), 0)
	)
	,[periodo12] = (
		ISNULL(SUM(CASE WHEN MONTH(vt.fecha) = 12 THEN vt.subtotal * (CASE WHEN vt.transaccion LIKE 'EFA%' THEN 1 ELSE -1 END)  ELSE 0 END), 0) 
		-ISNULL((
			SELECT SUM(ct.subtotal) 
			FROM ew_cxc_transacciones AS ct 
			WHERE 
				ct.cancelado = 0 
				AND ct.transaccion = 'FDA2' 
				AND ct.idconcepto IN (20, 30) 
				AND ct.idcliente = c.idcliente 
				AND MONTH(ct.fecha) = 12
				AND YEAR(ct.fecha) = @ejercicio
		), 0)
	)

	,[venta] = (
		ISNULL(SUM(vt.subtotal * (CASE WHEN vt.transaccion LIKE 'EFA%' THEN 1 ELSE -1 END) ), 0)
		-ISNULL((
			SELECT SUM(ct.subtotal)
			FROM ew_cxc_transacciones AS ct 
			WHERE 
				ct.cancelado = 0 
				AND ct.transaccion = 'FDA2' 
				AND ct.idconcepto IN (20, 30) 
				AND ct.idcliente = c.idcliente
				AND YEAR(ct.fecha) = @ejercicio
		), 0)
	)
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
	,c.idcliente
	,c.nombre
HAVING
	(
		ISNULL(SUM(vt.subtotal), 0)
		+ISNULL((
			SELECT SUM(ct.subtotal)
			FROM ew_cxc_transacciones AS ct 
			WHERE 
				ct.cancelado = 0 
				AND ct.transaccion = 'FDA2' 
				AND ct.idconcepto IN (20, 30) 
				AND ct.idcliente = c.idcliente
				AND YEAR(ct.fecha) = @ejercicio
		), 0)
	) <> 0
GO
