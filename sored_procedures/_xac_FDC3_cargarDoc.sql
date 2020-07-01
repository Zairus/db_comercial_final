USE db_comercial_final
GO
IF OBJECT_ID('_xac_FDC3_cargarDoc') IS NOT NULL
BEGIN
	DROP PROCEDURE _xac_FDC3_cargarDoc
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200328
-- Description:	Cargar devolucion de dinero a cliente
-- =============================================
CREATE PROCEDURE [dbo].[_xac_FDC3_cargarDoc]
	@idtran AS INT
AS

SET NOCOUNT ON

--#################################################
-- 1) ew_cxc_transacciones
--#################################################
SELECT
	[transaccion] = ct.transaccion
	, [idsucursal] = ct.idsucursal
	, [folio] = ct.folio
	, [fecha] = ct.fecha
	, [idcuenta] = ct.idcuenta
	, [idconcepto] = ct.idconcepto
	, [contabilidad] = bc.contabilidad1
	, [tipo] = ct.tipo
	, [cancelado] = ct.cancelado
	, [cancelado_fecha] = ct.cancelado_fecha
	, [estado] = [dbo].[fn_sys_estadoActualNombre](ct.idtran)
	, [idu] = ct.idu
	, [idr] = ct.idr
	, [idtran] = ct.idtran
	, [idmov] = ct.idmov
	, [codcliente] = c.codigo
	, [nombre] = c.nombre
	, [idcliente] = ct.idcliente
	, [idimpuesto1] = ct.idimpuesto1
	, [idimpuesto1_valor] = ct.idimpuesto1_valor
	, [spa] = ''
	, [total] = ct.total
	, [subtotal] = ct.subtotal
	, [impuesto1] = ct.impuesto1
	, [saldo] = ct.saldo
	, [comentario] = ct.comentario
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_ban_cuentas AS bc
		ON bc.idcuenta = ct.idcuenta
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = ct.idcliente
WHERE
	ct.idtran = @idtran

--#################################################
-- 2) ew_ban_transacciones
--#################################################
SELECT
	[referencia] = bt.referencia
	, [tipo] = bt.tipo
	, [importe] = bt.importe
	, [impuesto] = bt.impuesto
FROM
	ew_ban_transacciones AS bt
WHERE
	bt.idtran = @idtran

--#################################################
-- 3) ew_ban_transacciones_mov
--#################################################
SELECT
	[pago_folio] = st.folio
	, [pago_fecha] = st.fecha
	, [pago_cuenta] = ppd.cuenta
	, [idtran2] = btm.idtran2
	, [importe] = btm.importe
	, [comentario] = btm.comentario
	, [idr] = btm.idr
	, [idtran] = btm.idtran
	, [idmov] = btm.idmov
	, [objidtran] = btm.idtran2
FROM
	ew_ban_transacciones_mov AS btm
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = btm.idtran2
	LEFT JOIN ew_cxc_pagos_posible_devolver AS ppd
		ON ppd.idtran = btm.idtran2
WHERE
	btm.idtran = @idtran

--#################################################
-- 4) contabilidad
--#################################################
SELECT
	idr
	, objidtran
	, idtran2
	, consecutivo
	, fecha
	, tipo_nombre
	, folio
	, referencia
	, cuenta
	, cuenta_nombre
	, cargos
	, abonos
	, concepto
FROM
	contabilidad 
WHERE  
	contabilidad.idtran2 = @idtran 
 
--#################################################
-- 5) bitacora
--#################################################
SELECT
	fechahora
	, codigo
	, nombre
	, usuario_nombre
	, host
	, comentario
FROM 
	bitacora
WHERE  
	bitacora.idtran = @idtran 
ORDER BY 
	fechahora 
GO
