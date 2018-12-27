USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20171212
-- Description:	Formato de impreison CFDi 33 para CXC
-- ==============================================
ALTER PROCEDURE [dbo].[_cfdi_rpt_CXC33_relacionados]
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	[transaccion] = f.transaccion
	, [movimiento] = o.nombre
	, [idconcepto] = f.idconcepto
	, [fecha] = f.fecha
	, [folio] = f.folio
	, [subtotal] = f.subtotal
	, [impuesto1] = f.impuesto1
	, [impuesto2] = f.impuesto2
	, [impuesto1_ret] = f.impuesto1_ret
	, [impuesto2_ret] = f.impuesto2_ret
	, [total] = f.total
	, [aplicado] = ctm.importe
	, [comentario] = ctm.comentario
FROM 
	ew_cxc_transacciones_mov AS ctm
	LEFT JOIN ew_cxc_transacciones AS f
		ON f.idtran = ctm.idtran2
	LEFT JOIN objetos AS o
		ON o.codigo = f.transaccion
WHERE 
	ctm.idtran = @idtran

UNION ALL

SELECT
	[transaccion] = f.transaccion
	, [movimiento] = (
		o.nombre 
		+ ': '
		+ cct.cfdi_uuid
		+ ', '
		+ csr.descripcion + ' [' + csr.c_tiporelacion + ']'
	)
	, [idconcepto] = f.idconcepto
	, [fecha] = f.fecha
	, [folio] = f.folio
	, [subtotal] = f.subtotal
	, [impuesto1] = f.impuesto1
	, [impuesto2] = f.impuesto2
	, [impuesto1_ret] = f.impuesto1_ret
	, [impuesto2_ret] = f.impuesto2_ret
	, [total] = f.total
	, [aplicado] = 0
	, [comentario] = csr.descripcion + ' [' + csr.c_tiporelacion + ']'
FROM 
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_cxc_transacciones AS f
		ON f.idtran = ct.idtran2
	LEFT JOIN objetos AS o
		ON o.codigo = f.transaccion
	LEFT JOIN ew_cfd_comprobantes_timbre AS cct
		ON cct.idtran = ct.idtran2
	LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_tiporelacion AS csr
		ON csr.idr = ct.idrelacion
WHERE 
	ct.idtran = @idtran
	AND csr.c_tiporelacion IS NOT NULL
GO
