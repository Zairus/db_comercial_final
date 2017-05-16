USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110513
-- Description:	Diario de cobranza
-- =============================================
ALTER PROCEDURE [dbo].[_cxc_rpt_diario]
	 @idsucursal AS SMALLINT = 0
	,@fecha1 AS SMALLDATETIME = NULL
	,@fecha2 AS SMALLDATETIME = NULL
AS

SET NOCOUNT ON

SELECT @fecha1 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha1, GETDATE()), 3) + ' 00:00')
SELECT @fecha2 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha2, GETDATE()), 3) + ' 00:00')

SELECT
	 [idtran] = ISNULL(db.idtran, dc.idtran)
	,[dcidtran] = dc.idtran
	,[ctipo] = (
		CASE 
			WHEN dc.transaccion = 'BDC2' AND da.idtran IS NOT NULL THEN '1) '
			WHEN dc.transaccion = 'BDC2' AND da.idtran IS NULL THEN '2) ' 
			ELSE '3) '
		END
	)
	,[tipo] = t.nombre
	,[bancofolio] = ISNULL('Ref. Banco: ' + db.folio, 'Folio: ' + dc.folio)
	,[bancocuenta] = ISNULL((b.nombre + '-' + cb.no_cuenta), '')
	,[referencia] = dc.folio
	,[codcliente] = c.codigo
	,[transaccion] = dc.transaccion
	,[factura] = fact.folio
	,[fecha] = dc.fecha
	,[subtotal] = ISNULL(da.subtotal, dc.subtotal)
	,[iva] = ISNULL(da.impuesto4, dc.impuesto1)
	,[total] = ISNULL(da.importe, dc.total)
	,[refpago] = ''
	,[TipoPago] = ISNULL(bf.nombre, '')
	,[costo] = 0
	,[fidtran] = ISNULL(fact.idtran, 0)
	,[iddoc] = dc.idr
	
	,dc.transaccion
FROM
	ew_cxc_transacciones AS dc
	LEFT JOIN ew_cxc_transacciones_mov AS da
		ON da.idtran = dc.idtran
	LEFT JOIN ew_cxc_transacciones AS fact
		ON fact.idtran = da.idtran2
	LEFT JOIN ew_ban_transacciones AS db
		ON db.idtran = dc.idtran2
	LEFT JOIN ew_ban_cuentas As cb
		ON cb.idcuenta = dc.idcuenta
	LEFT JOIN ew_ban_bancos AS b
		ON b.idbanco = cb.idbanco
	LEFT JOIN objetos AS t
		ON t.codigo = dc.transaccion
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = dc.idcliente
	LEFT JOIN ew_ban_formas AS bf
		ON bf.idforma = db.idforma
WHERE
	dc.tipo IN (1,2)
	AND dc.fecha BETWEEN @fecha1 AND @fecha2
	AND dc.cancelado = 0
	AND dc.transaccion NOT IN ('EFA1')
	AND ISNULL(fact.idsucursal,  dc.idsucursal) = (
		CASE @idsucursal 
			WHEN 0 THEN ISNULL(fact.idsucursal,  dc.idsucursal) 
			ELSE @idsucursal 
		END
	)
GO
