USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180917
-- Description:	Consulta pendientes de captura para carga de saldos
-- =============================================
ALTER PROCEDURE _cxc_prc_migracionPendientesDeCaptura
AS

SET NOCOUNT ON

SELECT TOP 100
	[folio] = cm.folio
	, [fecha] = cm.fecha
	, [idr] = cm.idr
	, [vencimiento] = cm.vencimiento
	, [idcliente] = c.idcliente
	, [cliente] = c.nombre
	, [cliente_codigo] = cm.codcliente
	, [idmoneda] = cm.idmoneda
	, [importe] = cm.importe
	, [impuesto1] = cm.impuesto1
	, [impuesto2] = cm.impuesto2
	, [total] = (
		cm.importe 
		+ (
			cm.impuesto1 
			+ cm.impuesto2 
			+ cm.impuesto3 
			+ cm.impuesto4
		) 
		- (
			cm.impuesto1_ret 
			+ cm.impuesto2_ret
		)
	)
	, [saldo] = cm.saldo
	, [idsucursal] = cm.idsucursal
	, [uuid] = cm.uuid
FROM
	ew_cxc_migracion AS cm
	LEFT JOIN vew_clientes AS c
		ON c.codigo = cm.codcliente
WHERE
	cm.saldo = 0
GO
