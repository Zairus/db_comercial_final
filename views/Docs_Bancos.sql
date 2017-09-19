USE db_comercial_final
GO
ALTER VIEW [dbo].[Docs_Bancos]
AS
SELECT
	[codcuenta] = b.idcuenta
	, [transaccion] = b.transaccion
	, [folio] = b.folio
	, [forma] = b.idforma
	, [concepto] = c.nombre
	, [codsuc] = b.idsucursal
	, [idsucursal] = b.idsucursal
	, [tipo] = b.tipo
	, [fecha] = b.fecha
	, [fechacap] = b.fechahora
	, [importe] = b.importe
	, [tcbanco] = b.tipocambio
	, [tc_dof] = b.tipocambio
	, [beneficiario] = b.identidad
	, [codigo] = en.codigo
	, [nombre] = en.nombre
	, [codcont] = ''
	, [Estatus] = dbo.fn_sys_estadoActual(b.idtran)
	, [cancelado] = b.cancelado
	, [FechaCancelado] = b.cancelado_fecha
	, [conciliado] = b.conciliado_id
	, [FechaBanco] = b.aplicado_fecha
	, [comentario] = b.comentario
	, [ID] = b.idmov
	, [codbanco] = bc.idbanco
	, [iddoc] = b.idtran
	, [usuario] = b.idu
	, [idtran] = b.idtran
	, [r_tipo] = 0
FROM
	dbo.ew_ban_transacciones AS b 
	LEFT OUTER JOIN dbo.ew_ban_cuentas AS bc 
		ON bc.idcuenta = b.idcuenta 
	LEFT OUTER JOIN dbo.conceptos AS c 
		ON c.idconcepto = b.idconcepto 
	LEFT OUTER JOIN dbo.vew_entidades AS en 
		ON en.identidad = b.identidad 
		AND en.idrelacion = b.idrelacion
WHERE
	b.compuesto = 0
	AND b.tipo IN (1,2)

UNION ALL

SELECT
	[codcuenta] = b.idcuenta
	, [transaccion] = b.transaccion
	, [folio] = b.folio
	, [forma] = b.idforma
	, [concepto] = c.nombre
	, [codsuc] = b.idsucursal
	, [idsucursal] = b.idsucursal
	, [tipo] = b.tipo
	, [fecha] = b.fecha
	, [fechacap] = b.fechahora
	, [importe] = btm.importe
	, [tcbanco] = b.tipocambio
	, [tc_dof] = b.tipocambio
	, [beneficiario] = b.identidad
	, [codigo] = en.codigo
	, [nombre] = en.nombre
	, [codcont] = ''
	, [Estatus] = dbo.fn_sys_estadoActual(b.idtran)
	, [cancelado] = b.cancelado
	, [FechaCancelado] = b.cancelado_fecha
	, [conciliado] = btm.conciliado_id
	, [FechaBanco] = b.aplicado_fecha
	, [comentario] = b.comentario
	, [ID] = btm.idmov
	, [codbanco] = bc.idbanco
	, [iddoc] = b.idtran
	, [usuario] = b.idu
	, [idtran] = b.idtran
	, [r_tipo] = 1
FROM
	ew_ban_transacciones AS b
	LEFT JOIN ew_ban_transacciones_mov AS btm
		ON btm.idtran = b.idtran
	LEFT OUTER JOIN dbo.ew_ban_cuentas AS bc 
		ON bc.idcuenta = b.idcuenta 
	LEFT OUTER JOIN dbo.conceptos AS c 
		ON c.idconcepto = b.idconcepto 
	LEFT OUTER JOIN dbo.vew_entidades AS en 
		ON en.identidad = b.identidad 
		AND en.idrelacion = b.idrelacion
WHERE
	b.compuesto = 1
	AND b.tipo IN (1,2)
GO
