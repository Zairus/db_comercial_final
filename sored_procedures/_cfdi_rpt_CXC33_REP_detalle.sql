USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180824
-- Description:	Formato de impreison CFDi 33 para REP
-- =============================================
ALTER PROCEDURE [dbo].[_cfdi_rpt_CXC33_REP_detalle]
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	[uuid] = cct.cfdi_UUID
	, [folio] = p_c.folio
	, [moneda] = cc.cfd_moneda
	, [metodo_pago] = cc.cfd_formaDePago
	, [tipo_relacion] = '04 Sust. CFDi'
	, [parcialidad] = 0
	, [saldo_anterior] = 0
	, [importe_pagado] = 0
	, [saldo_actual] = 0
FROM
	ew_cxc_transacciones AS p
	LEFT JOIN ew_cxc_transacciones AS p_c
		ON p_c.idtran = p.idtran2
	LEFT JOIN ew_cfd_comprobantes_timbre AS cct
		ON cct.idtran = p.idtran2
	LEFT JOIN ew_cfd_comprobantes AS cc
		On cc.idtran = p.idtran2
WHERE
	ISNULL(p_c.cancelado, 0) = 1
	AND p.idtran = @idtran

UNION ALL

SELECT
	[uuid] = cct.cfdi_uuid
	, [folio] = cc.cfd_folio
	, [moneda] = cc.cfd_moneda
	, [metodo_pago] = cc.cfd_formaDePago
	, [tipo_relacion] = 'P01 Pago'
	, [parcialidad] = ROW_NUMBER() OVER (PARTITION BY ctm.idtran2 ORDER BY ctm.idtran ASC, ctm.idmov ASC)
	, [saldo_anterior] = f.saldo + ctm.importe2
	, [importe_pagado] = ctm.importe2
	, [saldo_actual] = f.saldo
FROM 
	ew_cxc_transacciones_mov AS ctm 
	LEFT JOIN ew_cfd_comprobantes AS cc
		On cc.idtran = ctm.idtran2
	LEFT JOIN ew_cfd_comprobantes_timbre AS cct
		ON cct.idtran = ctm.idtran2
	LEFT JOIN ew_cxc_transacciones AS p
		ON p.idtran = ctm.idtran
	LEFT JOIN ew_cxc_transacciones AS f
		ON f.idtran = ctm.idtran2
WHERE
	ctm.idtran = @idtran
GO
