USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110428
-- Description:	Diario de ventas
-- =============================================
ALTER PROCEDURE [dbo].[_ven_rpt_diario]
	 @idsucursal AS SMALLINT = 0
	,@fecha1 AS SMALLDATETIME = NULL
	,@fecha2 AS SMALLDATETIME = NULL
AS

SET NOCOUNT ON

SELECT @fecha1 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha1, GETDATE()), 3) + ' 00:00')
SELECT @fecha2 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha2, GETDATE()), 3) + ' 23:59')

SELECT
	 [sucursal] = s.nombre
	,vt.fecha
	,[folio] = vt.folio
	,c.codigo
	,[contado] = (CASE WHEN ct.credito = 0 THEN vt.total ELSE 0 END)
	,[credito] = (CASE WHEN ct.credito = 1 THEN vt.total ELSE 0 END)
	,vt.costo
	,[codvend] = v.codigo
	,[vendedor] = v.nombre
	,[total] = vt.total
	--forma = (CASE WHEN dc.tipopago = 1 THEN ''Efectivo'' WHEN dc.tipopago = 2 THEN ''Cheque'' WHEN dc.tipopago = 3 THEN ''Tarjeta'' WHEN dc.tipopago = 4 THEN ''Depósito'' WHEN dc.tipopago = 5 THEN ''Transferencia'' ELSE '''' END)
	,[forma] = ISNULL(bf.nombre, '')
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
WHERE
	vt.cancelado = 0
	AND vt.transaccion LIKE 'EFA%'
	AND vt.idsucursal = (CASE @idsucursal WHEN 0 THEN vt.idsucursal ELSE @idsucursal END)
	AND vt.fecha BETWEEN @fecha1 AND @fecha2
ORDER BY
	 vt.idsucursal
	,vt.folio
GO
