USE [db_refriequipos_datos]
GO
IF OBJECT_ID('_ven_rpt_diario') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_rpt_diario
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110428
-- Description:	Diario de ventas
-- =============================================
CREATE PROCEDURE [dbo].[_ven_rpt_diario]
	@idsucursal AS SMALLINT = 0
	, @fecha1 AS SMALLDATETIME = NULL
	, @fecha2 AS SMALLDATETIME = NULL
	, @condicionventa AS SMALLINT = -1
	, @objeto AS INT = -1
AS

SET NOCOUNT ON

DECLARE 
	@objetocodigo AS VARCHAR(5) = ''

SELECT @fecha1 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha1, GETDATE()), 3) + ' 00:00')
SELECT @fecha2 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha2, GETDATE()), 3) + ' 23:59')

SELECT 
	@objetocodigo = codigo 
FROM 
	objetos 
WHERE 
	objeto = @objeto

SELECT @objetocodigo = ISNULL(@objetocodigo, '')

SELECT
	[sucursal] = s.nombre
	, [fecha] = CONVERT(DATE, vt.fecha, 103)
	, [folio] = (
		vt.folio 
		+ ' (' + vt.transaccion + ')'
	)
	, [codigo] = (
		c.codigo 
		+ (
			CASE 
				WHEN DB_NAME() NOT LIKE 'db_refri%' THEN 
					' (' + c.nombre + ')' 
				ELSE '' 
			END
		)
	)
	, [subtotal] = vt.subtotal
	, [iva] = vt.impuesto1
	, [contado] = (
		CASE 
			WHEN ABS([dbo].[_cxc_fnc_documentoSaldoR2] (vt.idtran, CONVERT(SMALLDATETIME, vt.fecha))) > 0.01 THEN 0 
			ELSE vt.total 
		END
	)
	, [credito] = (
		CASE 
			WHEN ABS([dbo].[_cxc_fnc_documentoSaldoR2] (vt.idtran, CONVERT(SMALLDATETIME, vt.fecha))) > 0.01 THEN vt.total 
			ELSE 0 
		END
	)
	, [costo] = vt.costo
	, [codvend] = v.codigo
	, [vendedor] = v.nombre
	, [total] = vt.total
	, [forma] = ISNULL(ISNULL(bfa.nombre, bf.nombre), 'Por Definir')
	, [idtran] = vt.idtran
FROM
	ew_ven_transacciones AS vt
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = vt.idsucursal
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = vt.idcliente
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = vt.idtran
	LEFT JOIN ew_ven_vendedores AS v
		ON v.idvendedor = vt.idvendedor
	LEFT JOIN ew_ban_formas AS bf
		ON bf.idforma = ct.idforma
		AND ct.credito = 0
	LEFT JOIN ew_cfd_comprobantes AS cc
		ON cc.idtran = ct.idtran
	LEFT JOIN ew_ban_formas_aplica bfa
		ON bfa.codigo = cc.cfd_metodoDePago
		AND (
			ct.credito = 0
			OR bfa.codigo = '99'
		)
		
	LEFT JOIN objetos AS o 
		ON o.codigo = ct.transaccion
WHERE
	vt.cancelado = 0
	AND vt.transaccion LIKE 'EFA%'
	AND vt.transaccion NOT IN ('EFA4', 'EFA7')
	AND vt.idsucursal = (CASE @idsucursal WHEN 0 THEN vt.idsucursal ELSE @idsucursal END)
	AND vt.fecha BETWEEN @fecha1 AND @fecha2
	AND vt.credito = (CASE @condicionventa WHEN -1 THEN vt.credito ELSE @condicionventa END)
	AND o.codigo IN (
		SELECT ov.codigo 
		FROM 
			objetos AS ov 
		WHERE 
			ov.codigo LIKE (
				CASE 
					WHEN @objeto = -1 THEN ov.codigo 
					WHEN @objeto = -2 THEN 
						CASE 
							WHEN ct.transaccion = 'EFA1' THEN 'EFA1' 
							ELSE 
								CASE 
									WHEN ct.transaccion = 'EFA4' THEN 'EFA4' 
									ELSE	
										CASE 
											WHEN ct.transaccion = 'EFA6' THEN 'EFA6' 
										END 
								END 
							END 
						ELSE @objetocodigo 
				END
			)
	)

ORDER BY
	vt.idsucursal
	, ct.fechahora
	, vt.folio
GO
