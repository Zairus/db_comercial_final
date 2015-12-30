USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20151202
-- Description:	Soporte para corte de caja
-- =============================================
CREATE PROCEDURE _ban_rpt_cajaCorteSoporte3
	@idsucursal AS INT
	,@fecha AS SMALLDATETIME = NULL
AS

SET NOCOUNT ON

SELECT @fecha = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha, GETDATE()), 3) + ' 00:00')

SELECT
	[caja] = (bb.nombre + '-' + bc.no_cuenta)
	,[forma] = (CASE WHEN bt.transaccion = 'BDC2' THEN 'Pago ' ELSE 'Ingreso ' END) + ISNULL(bf.nombre, 'NO IDENTIFICADO')
	,[importe] = SUM(bt.total)
FROM
	ew_ban_transacciones AS bt
	LEFT JOIN ew_ban_cuentas AS bc
		ON bc.idcuenta = bt.idcuenta
	LEFT JOIN ew_ban_bancos AS bb
		ON bb.idbanco = bc.idbanco
	LEFT JOIN ew_ban_formas AS bf
		ON bf.idforma = bt.idforma
WHERE
	bt.cancelado = 0
	AND bt.tipo = 1
	AND bc.tipo = 3
	AND bt.idsucursal = @idsucursal
	AND (CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), bt.fecha, 3) + ' 00:00')) = @fecha
GROUP BY
	(bb.nombre + '-' + bc.no_cuenta)
	,(CASE WHEN bt.transaccion = 'BDC2' THEN 'Pago ' ELSE 'Ingreso ' END) + ISNULL(bf.nombre, 'NO IDENTIFICADO')
GO
