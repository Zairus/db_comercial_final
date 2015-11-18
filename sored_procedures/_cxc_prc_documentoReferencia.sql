USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20151118
-- Description:	Referencia para documentos CXC en aplicaciones
-- =============================================
ALTER PROCEDURE [dbo].[_cxc_prc_documentoReferencia]
	@transacciones AS VARCHAR(2000)
AS

SET NOCOUNT ON

DECLARE
	@idtran AS INT
	
SELECT
	[ref_transaccion] = r.transaccion
	,[ref_concepto] = o.nombre + ' ' + ISNULL(c.nombre, '')
	,[ref_folio] = r.folio
	,[ref_referencia] = r.referencia
	
	,[ref_fecha] = r.fecha
	,[ref_vencimiento] = r.vencimiento

	,[ref_subtotal] = r.subtotal
	,[ref_total] = r.total
	,[ref_saldo] = r.saldo
	,[ref_factor] = (r.impuesto1 / r.total)
	
	,[ref_impuesto1] = r.impuesto1
	,[ref_impuesto2] = r.impuesto2
	,[ref_impuesto1_ret] = r.impuesto1_ret
	,[ref_impuesto2_ret] = r.impuesto2_ret

	,[ref_idmoneda] = r.idmoneda
	,[ref_tipocambio] = r.tipocambio
	,[tipocambio] = r.tipocambio

	,[idmov2] = r.idmov
	,[idtran2] = r.idtran
FROM
	ew_cxc_transacciones AS r
	LEFT JOIN objetos AS o
		ON o.codigo = r.transaccion
	LEFT JOIN conceptos AS c 
		ON c.idconcepto > 0
		AND c.idconcepto = r.idconcepto
WHERE
	r.idtran IN (
		SELECT valor 
		FROM _sys_fnc_separarMultilinea (@transacciones, '	')
	)
GO
