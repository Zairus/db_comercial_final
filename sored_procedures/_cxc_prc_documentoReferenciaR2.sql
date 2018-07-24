USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20161118
-- Description:	Referencia para documentos CXC en aplicaciones v2
-- =============================================
ALTER PROCEDURE [dbo].[_cxc_prc_documentoReferenciaR2]
	@transacciones AS VARCHAR(2000)
AS

SET NOCOUNT ON

DECLARE
	@idtran AS INT
	
SELECT
	[ref_folio] = ct.folio
	,[ref_transaccion] = ct.transaccion
	,[ref_concepto] = o.nombre + ' [' + ct.transaccion + ']'
	,[ref_referencia] = ct.referencia
	,[ref_fecha] = ct.fecha
	,[ref_vencimiento] = ct.vencimiento
	,[ref_idmoneda] = ct.idmoneda
	,[ref_tipocambio] = ct.tipocambio
	,[tipocambio] = ct.tipocambio
	,[ref_subtotal] = ct.subtotal
	,[ref_impuesto1] = ct.impuesto1
	,[ref_impuesto2] = ct.impuesto2
	,[ref_impuesto1_ret] = ct.impuesto1_ret
	,[ref_impuesto2_ret] = ct.impuesto2_ret
	,[ref_total] = ct.total
	,[ref_saldo] = ct.saldo
	,[idtran2] = ct.idtran
	,[objidtran] = ct.idtran
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
	LEFT JOIN conceptos AS c 
		ON c.idconcepto > 0
		AND c.idconcepto = ct.idconcepto
WHERE
	ct.idtran IN (
		SELECT d.valor 
		FROM _sys_fnc_separarMultilinea (@transacciones, '	') AS d
	)
GO
