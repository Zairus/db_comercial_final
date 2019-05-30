USE db_comercial_final
GO
IF OBJECT_ID('_cxc_rpt_diario_r2') IS NOT NULL
BEGIN
	DROP PROCEDURE _cxc_rpt_diario_r2
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110513
-- Description:	Diario de cobranza
-- =============================================
CREATE PROCEDURE [dbo].[_cxc_rpt_diario_r2]
	@idsucursal AS SMALLINT = 0
	, @idcuenta AS INT = 0
	, @fecha1 AS SMALLDATETIME = NULL
	, @fecha2 AS SMALLDATETIME = NULL
	, @tipoventa AS SMALLINT = -1
AS

SET NOCOUNT ON

SELECT @fecha1 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha1, GETDATE()), 3) + ' 00:00')
SELECT @fecha2 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha2, GETDATE()), 3) + ' 23:59')

SELECT
	[sucursal] = s.nombre
	, [bancocuenta] = ISNULL((b.nombre + ' - ' + cb.no_cuenta), '')
	, [forma_pago] = ISNULL(bf.nombre, '')
	, [forma_pago_b] = ISNULL(bf.nombre, '')
	, [transaccion] = ct.transaccion
	, [idtran] = ct.idtran
	, [ctipo] = ct.tipo
	, [tipo] = ct.tipo
	, [bancofolio] = ISNULL('Ref. Banco: ' + bt.folio, 'Folio: ' + ct.folio)
	, [referencia] = ISNULL(bt.folio, '')
	, [codcliente] = c.codigo
	, [factura] = ISNULL((
		SELECT TOP 1
			f.transaccion + '-' + f.folio
		FROM
			ew_cxc_transacciones_mov AS ctm
			LEFT JOIN ew_cxc_transacciones AS f
				ON f.idtran = ctm.idtran2
		WHERE
			ctm.idtran = ct.idtran
	), '-Sin Referencia-')
	, [fecha] = ct.fecha
	, [subtotal] = ct.subtotal
	, [iva] = ct.impuesto1
	, [total] = ct.total
	, [refpago] = ''
	, [costo] = 0
	, [fidtran] = 0
	, [iddoc] = ct.idr
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = ct.idsucursal
	LEFT JOIN ew_ban_transacciones AS bt
		ON bt.idtran = ct.idtran
	LEFT JOIN ew_ban_cuentas As cb
		ON cb.idcuenta = ISNULL(bt.idcuenta, ct.idcuenta)
	LEFT JOIN ew_ban_bancos AS b
		ON b.idbanco = cb.idbanco
	LEFT JOIN ew_ban_formas AS bf
		ON bf.idforma = ct.idforma
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = ct.idcliente
WHERE
	ct.tipo = 2
	AND ct.cancelado = 0
	AND ct.fecha BETWEEN @fecha1 AND @fecha2
	AND ct.idsucursal = ISNULL(NULLIF(@idsucursal, 0), ct.idsucursal)
	AND cb.idcuenta = ISNULL(NULLIF(@idcuenta, 0), cb.idcuenta)
	AND (
		(
			SELECT COUNT(*) 
			FROM 
				ew_cxc_transacciones_mov AS ctm1 
				LEFT JOIN ew_cxc_transacciones AS f
					ON f.idtran = ctm1.idtran2
			WHERE 
				ctm1.idtran =  ct.idtran
				AND f.credito = @tipoventa
		) > 0
		OR @tipoventa = -1
	)
ORDER BY
	s.nombre
	, ISNULL((b.nombre + ' - ' + cb.no_cuenta), '')
	, ISNULL(bf.nombre, '')
GO
