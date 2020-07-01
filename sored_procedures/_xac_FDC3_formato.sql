USE db_comercial_final
GO
IF OBJECT_ID('_xac_FDC3_formato') IS NOT NULL
BEGIN
	DROP PROCEDURE _xac_FDC3_formato
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200328
-- Description:	Datos para formato de FDC3
-- =============================================
GO
CREATE PROCEDURE [dbo].[_xac_FDC3_formato]
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	[documento] = o.nombre
	, [folio] = ct.folio
	, [fecha] = ct.fecha
	, [cliente] = c.nombre + ' [' + c.codigo + ']'
	, [rfc] = c.rfc
	, [cuenta] = bci.cuenta
	, [referencia] = bt.referencia
	, [concepto] = conc.nombre
	, [moneda] = bm.nombre
	, [comentario] = ct.comentario
	, [total] = ct.total

	, [pago_folio] = p.folio
	, [pago_fecha] = p.fecha
	, [pago_cuenta] = ppd.cuenta
	, [pago_importe] = btm.importe
	, [pago_devoluciones] = ppd.devoluciones
	, [devolucion_comentario] = btm.comentario
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_ban_transacciones AS bt
		ON bt.idtran = ct.idtran
	LEFT JOIN ew_ban_transacciones_mov AS btm
		ON btm.idtran = ct.idtran
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
	LEFT JOIN vew_clientes AS c
		ON c.idcliente = ct.idcliente
	LEFT JOIN db_comercial.dbo.evoluware_conceptos AS conc
		ON conc.idconcepto = ct.idconcepto
	LEFT JOIN ew_ban_monedas AS bm
		ON bm.idmoneda = ct.idmoneda

	LEFT JOIN ew_cxc_transacciones AS p
		ON p.idtran = btm.idtran2
	LEFT JOIN ew_cxc_pagos_posible_devolver AS ppd
		ON ppd.idtran = p.idtran

	LEFT JOIN ew_ban_cuentas_informacion AS bci
		ON bci.idcuenta = bt.idcuenta
WHERE
	ct.idtran = @idtran
GO
