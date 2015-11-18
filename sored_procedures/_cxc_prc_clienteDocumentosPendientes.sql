USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20151118
-- Description:	Documentos pendientes de pago por cliente
-- =============================================
ALTER PROCEDURE _cxc_prc_clienteDocumentosPendientes
	@idcliente AS INT
AS

SET NOCOUNT ON

SELECT
	[ref_transaccion] = ct.transaccion
	,[ref_concepto] = o.nombre + ' ' + ISNULL(c.nombre, '')
	,[ref_folio] = ct.folio
	,[ref_referencia] = ct.referencia
	
	,[ref_fecha] = ct.fecha
	,[ref_vencimiento] = ct.vencimiento

	,[ref_subtotal] = ct.subtotal
	,[ref_total] = ct.total
	,[ref_saldo] = ct.saldo
	
	,[ref_impuesto1] = ct.impuesto1
	,[ref_impuesto2] = ct.impuesto2
	,[ref_impuesto1_ret] = ct.impuesto1_ret
	,[ref_impuesto2_ret] = ct.impuesto2_ret

	,[ref_idmoneda] = ct.idmoneda
	,[ref_tipocambio] = ct.tipocambio
	,[tipocambio] = ct.tipocambio

	,[idmov2] = ct.idmov
	,[idtran2] = ct.idtran
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
	LEFT JOIN conceptos AS c 
		ON c.idconcepto > 0
		AND c.idconcepto = ct.idconcepto
WHERE
	ct.cancelado = 0
	AND ct.tipo = 1
	AND ct.saldo > 0
	AND ct.idcliente = @idcliente
GO
