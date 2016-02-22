USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160215
-- Description:	Estadistico de ventas por vendedor
-- =============================================
ALTER PROCEDURE [dbo].[_ven_rpt_estadisticoVendedor]
	@idsucursal AS INT = 0
	,@fecha1 AS SMALLDATETIME = NULL
	,@fecha2 AS SMALLDATETIME = NULL
AS

SET NOCOUNT ON

SELECT @fecha1 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha1, DATEADD(DAY, -30, GETDATE())), 3) + ' 00:00')
SELECT @fecha2 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha2, GETDATE()), 3) + ' 23:59')

SELECT
	[vendedor] = '[' + LTRIM(RTRIM(STR(v.idvendedor))) + '] ' + v.nombre
	,[codvend] = v.codigo
	,[no_facturas] = (
		ISNULL((
			SELECT COUNT(*)
			FROM
				ew_ven_transacciones AS vt
			WHERE
				vt.cancelado = 0
				AND vt.transaccion LIKE 'EFA%'
				AND vt.idvendedor = v.idvendedor
				AND vt.idsucursal = (CASE WHEN @idsucursal = 0 THEN vt.idsucursal ELSE @idsucursal END)
				AND vt.fecha BETWEEN @fecha1 AND @fecha2
		), 0)
		-ISNULL((
			SELECT COUNT(*)
			FROM
				ew_ven_transacciones AS vt
			WHERE
				vt.cancelado = 0
				AND vt.transaccion LIKE 'EDE%'
				AND vt.idvendedor = v.idvendedor
				AND vt.idsucursal = (CASE WHEN @idsucursal = 0 THEN vt.idsucursal ELSE @idsucursal END)
				AND vt.fecha BETWEEN @fecha1 AND @fecha2
		), 0)
		-ISNULL((
			SELECT COUNT(*)
			FROM
				ew_cxc_transacciones AS ct1
				LEFT JOIN ew_clientes_terminos As ctr
					ON ctr.idcliente = ct1.idcliente
			WHERE
				ct1.cancelado = 0
				AND ct1.transaccion = 'FDA2'
				AND ct1.idconcepto IN (20,30)
				AND ctr.idvendedor = v.idvendedor
				AND ct1.idsucursal = (CASE WHEN @idsucursal = 0 THEN ct1.idsucursal ELSE @idsucursal END)
				AND ct1.fecha BETWEEN @fecha1 AND @fecha2
		), 0)
	)
	,[importe] = (
		ISNULL((
			SELECT SUM(vt.subtotal)
			FROM
				ew_ven_transacciones AS vt
			WHERE
				vt.cancelado = 0
				AND vt.transaccion LIKE 'EFA%'
				AND vt.idvendedor = v.idvendedor
				AND vt.idsucursal = (CASE WHEN @idsucursal = 0 THEN vt.idsucursal ELSE @idsucursal END)
				AND vt.fecha BETWEEN @fecha1 AND @fecha2
		), 0)
		-ISNULL((
			SELECT SUM(vt.subtotal)
			FROM
				ew_ven_transacciones AS vt
			WHERE
				vt.cancelado = 0
				AND vt.transaccion LIKE 'EDE%'
				AND vt.idvendedor = v.idvendedor
				AND vt.idsucursal = (CASE WHEN @idsucursal = 0 THEN vt.idsucursal ELSE @idsucursal END)
				AND vt.fecha BETWEEN @fecha1 AND @fecha2
		), 0)
		-ISNULL((
			SELECT SUM(ct1.subtotal)
			FROM
				ew_cxc_transacciones AS ct1
				LEFT JOIN ew_clientes_terminos As ctr
					ON ctr.idcliente = ct1.idcliente
			WHERE
				ct1.cancelado = 0
				AND ct1.transaccion = 'FDA2'
				AND ct1.idconcepto IN (20,30)
				AND ctr.idvendedor = v.idvendedor
				AND ct1.idsucursal = (CASE WHEN @idsucursal = 0 THEN ct1.idsucursal ELSE @idsucursal END)
				AND ct1.fecha BETWEEN @fecha1 AND @fecha2
		), 0)
	)
	,[porcentaje] = (
		(
			ISNULL((
				SELECT SUM(vt.subtotal)
				FROM
					ew_ven_transacciones AS vt
				WHERE
					vt.cancelado = 0
					AND vt.transaccion LIKE 'EFA%'
					AND vt.idvendedor = v.idvendedor
					AND vt.idsucursal = (CASE WHEN @idsucursal = 0 THEN vt.idsucursal ELSE @idsucursal END)
					AND vt.fecha BETWEEN @fecha1 AND @fecha2
			), 0)
			-ISNULL((
				SELECT SUM(vt.subtotal)
				FROM
					ew_ven_transacciones AS vt
				WHERE
					vt.cancelado = 0
					AND vt.transaccion LIKE 'EDE%'
					AND vt.idvendedor = v.idvendedor
					AND vt.idsucursal = (CASE WHEN @idsucursal = 0 THEN vt.idsucursal ELSE @idsucursal END)
					AND vt.fecha BETWEEN @fecha1 AND @fecha2
			), 0)
			-ISNULL((
				SELECT SUM(ct1.subtotal)
				FROM
					ew_cxc_transacciones AS ct1
					LEFT JOIN ew_clientes_terminos As ctr
						ON ctr.idcliente = ct1.idcliente
				WHERE
					ct1.cancelado = 0
					AND ct1.transaccion = 'FDA2'
					AND ct1.idconcepto IN (20,30)
					AND ctr.idvendedor = v.idvendedor
					AND ct1.idsucursal = (CASE WHEN @idsucursal = 0 THEN ct1.idsucursal ELSE @idsucursal END)
					AND ct1.fecha BETWEEN @fecha1 AND @fecha2
			), 0)
		)
		/ISNULL((
			SELECT SUM(vt.subtotal * (CASE WHEN vt.transaccion LIKE 'EFA%' THEN 1 ELSE -1 END))
			FROM
				ew_ven_transacciones AS vt
			WHERE
				vt.cancelado = 0
				AND (
					vt.transaccion LIKE 'EFA%'
					OR vt.transaccion LIKE 'EDE%'
				)
				AND vt.idsucursal = (CASE WHEN @idsucursal = 0 THEN vt.idsucursal ELSE @idsucursal END)
				AND vt.fecha BETWEEN @fecha1 AND @fecha2
		), 0)
	)
FROM 
	ew_ven_vendedores AS v
WHERE
	v.activo = 1
GO
