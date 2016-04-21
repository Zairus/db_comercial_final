USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160407
-- Description:	Formato impresion corte de caja detalle ventas
-- =============================================
ALTER PROCEDURE [dbo].[_ban_rpt_BPR2_res]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@idtran_prev AS INT
	,@idcuenta AS INT
	,@importe AS DECIMAL(18,6)

SELECT
	@idcuenta = bd.idcuenta1
	,@importe = bd.importe
FROM
	ew_ban_documentos AS bd
WHERE
	bd.idtran = @idtran

SELECT TOP 1
	@idtran_prev = bd.idtran
FROM
	ew_ban_documentos AS bd
WHERE
	bd.cancelado = 0
	AND bd.transaccion = 'BPR2'
	AND bd.idcuenta1 = @idcuenta
	AND bd.idtran < @idtran
ORDER BY
	bd.idtran DESC

SELECT @idtran_prev = ISNULL(@idtran_prev, 0)

SELECT
	bt.idtran
	,[movimiento] = o.nombre
	,[concepto] = ISNULL(c.nombre, '')
	,[referencia] = (
		ISNULL(
			(bd_o.nombre + ' ' + bd.folio)
			,ISNULL(
				(f_o.nombre + ' ' + f.folio + ': ' + cl.nombre)
				,o.nombre + ' ' + bt.folio
			)
		)
	)
	,bt.fecha
	,bt.folio
	,[importe] = ISNULL(ctm.importe, bt.total) * (CASE WHEN bt.tipo = 1 THEN 1 ELSE -1 END)
FROM
	ew_ban_transacciones AS bt
	LEFT JOIN objetos AS o
		ON o.codigo = bt.transaccion
	LEFT JOIN conceptos AS c
		ON c.idconcepto = bt.idconcepto

	LEFT JOIN ew_ban_documentos AS bd
		ON bd.idtran = bt.idtran2
	LEFT JOIN objetos AS bd_o
		ON bd_o.codigo = bd.transaccion

	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = bt.idtran
	LEFT JOIN ew_cxc_transacciones_mov AS ctm
		ON ctm.idtran = ct.idtran
	LEFT JOIN ew_cxc_transacciones AS f
		ON f.idtran = ctm.idtran2
	LEFT JOIN objetos AS f_o
		ON f_o.codigo = f.transaccion
	LEFT JOIN ew_clientes AS cl
		ON cl.idcliente = f.idcliente
WHERE
	bt.cancelado = 0
	AND bt.tipo IN (1,2)
	AND bt.referencia NOT LIKE 'BPR2%'
	AND bt.idcuenta = @idcuenta
	AND bt.idtran BETWEEN @idtran_prev AND @idtran
GO
