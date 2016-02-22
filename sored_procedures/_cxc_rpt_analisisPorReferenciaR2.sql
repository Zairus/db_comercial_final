USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160126
-- Description:	Analisis por referencia
-- =============================================
ALTER PROCEDURE [dbo].[_cxc_rpt_analisisPorReferenciaR2]
	@idsucursal AS INT = 0
	,@codcliente AS VARCHAR(30) = ''
	,@idconcepto AS SMALLINT = 0
	,@fecha1 AS SMALLDATETIME = NULL
	,@fecha2 AS SMALLDATETIME = NULL
	,@tipo AS SMALLINT = 0
	,@idmoneda AS SMALLINT = -1
AS

SET NOCOUNT ON

SELECT @fecha1 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha1, DATEADD(DAY, -30, GETDATE())), 3) + ' 00:00')
SELECT @fecha2 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha2, GETDATE()), 3) + ' 23:59')

SELECT
	[cliente] = c.nombre + ' [' + c.codigo + ']'
	,[grupo] = o.nombre + ' ' + ct.folio
	,[sucursal] = s.nombre
	,[tipo] = (CASE WHEN ct.tipo = 1 THEN 'Cargo' ELSE 'Abono' END)
	,[movimiento] = o.nombre
	,[concepto] = co.nombre
	,ct.fecha
	,ct.folio
	,[moneda] = bm.nombre
	,[incremento] = ct.total
	,[decremento] = 0.00
	,[saldo] = ct.saldo

	,[fecha_hora] = ct.fechahora
	,[id_orden] = ct.idtran
	,ct.idtran
	,[prioridad] = 0
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = ct.idcliente
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = ct.idsucursal
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
	LEFT JOIN conceptos AS co
		ON co.idconcepto = ct.idconcepto
	LEFT JOIN ew_ban_monedas AS bm
		ON bm.idmoneda = ct.idmoneda
WHERE
	ct.cancelado = 0
	AND ct.tipo IN (1,2)
	AND ct.idsucursal = (CASE WHEN @idsucursal = 0 THEN ct.idsucursal ELSE @idsucursal END)
	AND c.codigo = (CASE WHEN @codcliente = '' THEN c.codigo ELSE @codcliente END)
	AND ct.idconcepto = (CASE WHEN @idconcepto = 0 THEN ct.idconcepto ELSE @idconcepto END)
	AND ct.fecha BETWEEN @fecha1 AND @fecha2
	AND ct.tipo = (CASE WHEN @tipo = 0 THEN ct.tipo ELSE @tipo END)
	AND ct.idmoneda = (CASE WHEN @idmoneda = -1 THEN ct.idmoneda ELSE @idmoneda END)

UNION ALL

SELECT
	[cliente] = c.nombre + ' [' + c.codigo + ']'
	,[grupo] = o_f.nombre + ' ' + f.folio
	,[sucursal] = s.nombre
	,[tipo] = (CASE WHEN p.tipo = 1 THEN 'Cargo' ELSE 'Abono' END)
	,[movimiento] = o.nombre
	,[concepto] = co.nombre
	,p.fecha
	,p.folio
	,[moneda] = bm.nombre
	,[incremento] = 0.00
	,[decremento] = pd.importe2 * -1
	,[saldo] = 0

	,[fecha_hora] = pd.fechahora
	,[id_orden] = f.idtran
	,pd.idtran
	,[prioridad] = 1
FROM
	ew_cxc_transacciones_mov AS pd
	LEFT JOIN ew_cxc_transacciones AS p
		ON p.idtran = pd.idtran
	LEFT JOIN ew_cxc_transacciones AS f
		ON f.idtran = pd.idtran2
	LEFT JOIN objetos AS o_f
		ON o_f.codigo = f.transaccion
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = f.idcliente
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = f.idsucursal
	LEFT JOIN objetos AS o
		ON o.codigo = p.transaccion
	LEFT JOIN conceptos AS co
		ON co.idconcepto = p.idconcepto
	LEFT JOIN ew_ban_monedas AS bm
		ON bm.idmoneda = p.idmoneda
WHERE
	p.cancelado = 0
	AND f.cancelado = 0
	AND p.tipo IN (1,2)
	AND f.idsucursal = (CASE WHEN @idsucursal = 0 THEN f.idsucursal ELSE @idsucursal END)
	AND c.codigo = (CASE WHEN @codcliente = '' THEN c.codigo ELSE @codcliente END)
	AND p.idconcepto = (CASE WHEN @idconcepto = 0 THEN p.idconcepto ELSE @idconcepto END)
	AND f.fecha BETWEEN @fecha1 AND @fecha2
	AND f.tipo = (CASE WHEN @tipo = 0 THEN f.tipo ELSE @tipo END)
	AND f.idmoneda = (CASE WHEN @idmoneda = -1 THEN f.idmoneda ELSE @idmoneda END)

UNION ALL

SELECT
	[cliente] = c.nombre + ' [' + c.codigo + ']'
	,[grupo] = op.nombre + ' ' + p.folio
	,[sucursal] = s.nombre
	,[tipo] = (CASE WHEN f.tipo = 1 THEN 'Cargo' ELSE 'Abono' END)
	,[movimiento] = o.nombre
	,[concepto] = co.nombre
	,f.fecha
	,f.folio
	,[moneda] = bm.nombre
	,[incremento] = 0.00
	,[decremento] = pd.importe * -1
	,[saldo] = 0

	,[fecha_hora] = pd.fechahora
	,[id_orden] = pd.idtran
	,pd.idtran
	,[prioridad] = 1
FROM
	ew_cxc_transacciones_mov AS pd
	LEFT JOIN ew_cxc_transacciones AS p
		ON p.idtran = pd.idtran
	LEFT JOIN objetos AS op
		ON op.codigo = p.transaccion
	LEFT JOIN ew_cxc_transacciones AS f
		ON f.idtran = pd.idtran2
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = f.idcliente
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = f.idsucursal
	LEFT JOIN objetos AS o
		ON o.codigo = f.transaccion
	LEFT JOIN conceptos AS co
		ON co.idconcepto = f.idconcepto
	LEFT JOIN ew_ban_monedas AS bm
		ON bm.idmoneda = p.idmoneda
WHERE
	p.cancelado = 0
	AND f.cancelado = 0
	AND p.tipo IN (1,2)
	AND p.idsucursal = (CASE WHEN @idsucursal = 0 THEN p.idsucursal ELSE @idsucursal END)
	AND c.codigo = (CASE WHEN @codcliente = '' THEN c.codigo ELSE @codcliente END)
	AND p.idconcepto = (CASE WHEN @idconcepto = 0 THEN p.idconcepto ELSE @idconcepto END)
	AND p.fecha BETWEEN @fecha1 AND @fecha2
	AND p.tipo = (CASE WHEN @tipo = 0 THEN p.tipo ELSE @tipo END)
	AND p.idmoneda = (CASE WHEN @idmoneda = -1 THEN p.idmoneda ELSE @idmoneda END)

ORDER BY
	[cliente]
	,[id_orden]
	,[prioridad]
	,[fecha_hora]
GO
