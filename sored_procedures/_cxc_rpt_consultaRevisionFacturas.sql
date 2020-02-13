USE db_comercial_final
GO
IF OBJECT_ID('_cxc_rpt_consultaRevisionFacturas') IS NOT NULL
BEGIN
	DROP PROCEDURE _cxc_rpt_consultaRevisionFacturas
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190712
-- Description:	Consulta para revision de facturas en cobranza
-- =============================================
CREATE PROCEDURE [dbo].[_cxc_rpt_consultaRevisionFacturas]
	@codcliente AS VARCHAR(20) = ''
	, @fecha1 AS DATETIME = NULL
	, @fecha2 AS DATETIME = NULL
AS

SET NOCOUNT ON

SELECT @fecha1 = CONVERT(DATETIME, CONVERT(VARCHAR(10), ISNULL(@fecha1, GETDATE()), 103) + ' 00:00')
SELECT @fecha2 = CONVERT(DATETIME, CONVERT(VARCHAR(10), ISNULL(@fecha2, GETDATE()), 103) + ' 23:59')

SELECT
	[cliente] = c.nombre
	, [movimiento] = o.nombre
	, [folio] = ct.folio
	, [fecha_emision] = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(10), ct.fecha, 103))
	, [fecha_revision] = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(10), (
		CASE
			WHEN ctr.dia_revision = DATEPART(WEEKDAY, ct.fecha) THEN 
				ct.fecha
			ELSE 
				DATEADD(DAY, (DATEDIFF(DAY, ctr.dia_revision - 1, ct.fecha) / 7) * 7 + 7, ctr.dia_revision - 1)
		END
	), 103))
	, [fecha_enviada] = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(10), (
		SELECT TOP 1
			se.fecha
		FROM 
			dbEVOLUWARE.dbo.ew_sys_email AS se
		WHERE
			se.db = DB_NAME()
			AND se.idtran = ct.idtran
		ORDER BY
			se.idr DESC
	), 103))
	, [total] = ct.total
	, [saldo] = ct.saldo
	, [idtran] = ct.idtran
FROM 
	ew_cxc_transacciones AS ct 
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = ct.idcliente
	LEFT JOIN ew_clientes_terminos AS ctr
		ON ctr.idcliente = c.idcliente
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
WHERE 
	ct.cancelado = 0
	AND ct.tipo = 1
	AND ct.saldo > 0.01
	AND c.codigo = ISNULL(NULLIF(@codcliente, ''), c.codigo)
	AND (
		CASE
			WHEN ctr.dia_revision = DATEPART(WEEKDAY, ct.fecha) THEN 
				ct.fecha
			ELSE 
				DATEADD(DAY, (DATEDIFF(DAY, ctr.dia_revision - 1, ct.fecha) / 7) * 7 + 7, ctr.dia_revision - 1)
		END
	) BETWEEN @fecha1 AND @fecha2
ORDER BY
	c.nombre
	, ct.fecha
GO
