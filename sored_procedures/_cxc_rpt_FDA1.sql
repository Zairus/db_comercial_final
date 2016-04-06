USE [db_comercial_final]
GO
/*******************************************************************************
 *Procedimiento _cxc_rpt_FDA1 Y FDC1
 *------------------------------------------------------------------------------
 *Nota de Abono (FDA1) y Nota de Cargo (FDC1)
 *Creado: MARZO 2010 Fernanda Corona
 *Ejemplo: EXEC _cxc_rpt_FDA1 1363
 ******************************************************************************/
ALTER PROCEDURE [dbo].[_cxc_rpt_FDA1]
	@idtran INT = 0
AS

SET NOCOUNT ON

SELECT 
	t.idtran
	,[sucursal]=s.nombre
	,docto=o.nombre
	,t.folio
	,t.referencia
	,ct.codigo
	,cf.rfc
	,[cliente]=ct.nombre
	,[concepto_nombre]=c.nombre
	,t.subtotal
	,[iva]=t.impuesto1	
	,[iva_ret]=t.impuesto1_ret
	,[isr_ret]=t.impuesto2_ret
	,t.total
	,[pendiente]=t.saldo
	,moneda=(SELECT m.nombre FROM ew_ban_monedas m WHERE t.idmoneda=m.idmoneda)
	,tm.fecha
	,tm.comentario
	,[ref_transaccion]=ref.transaccion
	,[ref_concepto]=c2.nombre
	,[ref_folio]=ref.folio
	,[ref_referencia]=ref.referencia
	,[ref_fecha]=ref.fecha
	,[ref_idmoneda]=(SELECT m.nombre FROM ew_ban_monedas m WHERE m.idmoneda=ref.idmoneda)
	,[ref_tipocambio]=ref.tipocambio
	,[ref_importe]=tm.importe
	,[ref_iva]=tm.impuesto1
	,[ref_ieps]=tm.impuesto2
	,[ref_total]=tm.importe2
	,[ref_moneda]=(SELECT m.nombre FROM ew_ban_monedas m WHERE ref.idmoneda=m.idmoneda)	
	
FROM 
	ew_cxc_transacciones AS t
	LEFT JOIN ew_cxc_transacciones_mov AS tm 
		ON t.idtran = (CASE WHEN t.tipo = 1 THEN tm.idtran2 ELSE tm.idtran END)
	LEFT JOIN conceptos AS c 
		ON c.idconcepto = t.idconcepto
	LEFT JOIN ew_clientes AS ct 
		ON ct.idcliente = t.idcliente
	LEFT JOIN ew_clientes_facturacion AS cf 
		ON cf.idcliente = ct.idcliente 
		AND cf.idfacturacion = ct.idfacturacion
	LEFT JOIN sucursales AS s 
		ON s.idsucursal = t.idsucursal
	LEFT JOIN ew_cxc_transacciones AS ref 
		ON ref.idtran = (CASE WHEN t.tipo = 1 THEN tm.idtran ELSE tm.idtran2 END)
	LEFT JOIN conceptos AS c2 
		ON c2.idconcepto = ref.idconcepto
	LEFT JOIN objetos AS o 
		ON o.codigo = t.transaccion
WHERE 
    t.tipo IN (1,2)
	AND t.idtran = @idtran 
GO
