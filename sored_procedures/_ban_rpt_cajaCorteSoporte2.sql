USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20151202
-- Description:	Soporte para corte de caja
-- =============================================
CREATE PROCEDURE _ban_rpt_cajaCorteSoporte2
	@idsucursal AS INT
	,@fecha AS SMALLDATETIME = NULL
AS

SET NOCOUNT ON

SELECT @fecha = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha, GETDATE()), 3) + ' 00:00')

SELECT
	[concepto] = 'VENTA'
	,[importe] = SUM(ISNULL(f.subtotal, 0))
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_cxc_transacciones_mov AS ctm
		ON ctm.idtran = ct.idtran
	LEFT JOIN ew_cxc_transacciones As f
		ON f.idtran = ctm.idtran2
WHERE
	ct.cancelado = 0
	AND ct.transaccion = 'BDC2'
	AND ct.idsucursal = @idsucursal
	AND (CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ct.fecha, 3) + ' 00:00')) = @fecha

UNION ALL

SELECT
	[concepto] = 'IVA CONTADO'
	,[importe] = ISNULL(SUM(ISNULL(f.impuesto1, 0)), 0)
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_cxc_transacciones_mov AS ctm
		ON ctm.idtran = ct.idtran
	LEFT JOIN ew_cxc_transacciones As f
		ON f.idtran = ctm.idtran2
WHERE
	ct.cancelado = 0
	AND ct.transaccion = 'BDC2'
	AND f.credito = 0
	AND ct.idsucursal = @idsucursal
	AND (CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ct.fecha, 3) + ' 00:00')) = @fecha

UNION ALL

SELECT
	[concepto] = 'IVA CREDITO'
	,[importe] = ISNULL(SUM(ISNULL(f.impuesto1, 0)), 0)
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_cxc_transacciones_mov AS ctm
		ON ctm.idtran = ct.idtran
	LEFT JOIN ew_cxc_transacciones As f
		ON f.idtran = ctm.idtran2
WHERE
	ct.cancelado = 0
	AND ct.transaccion = 'BDC2'
	AND f.credito = 1
	AND ct.idsucursal = @idsucursal
	AND (CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ct.fecha, 3) + ' 00:00')) = @fecha

UNION ALL

SELECT
	[concepto] = 'ANTICIPO'
	,[importe] = ISNULL(SUM(ct.total), 0)
FROM
	ew_cxc_transacciones AS ct
WHERE
	ct.cancelado = 0
	AND ct.transaccion = 'BDC2'
	AND (SELECT COUNT(ctm.idr) FROM ew_cxc_transacciones_mov AS ctm WHERE ctm.idtran = ct.idtran) = 0
	AND ct.idsucursal = @idsucursal
	AND (CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ct.fecha, 3) + ' 00:00')) = @fecha
GO
