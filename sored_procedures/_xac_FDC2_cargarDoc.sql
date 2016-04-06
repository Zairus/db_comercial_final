USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160306
-- Description:	Cargar devolucion de dinero a cliente
-- =============================================
ALTER PROCEDURE _xac_FDC2_cargarDoc
	@idtran AS INT
AS

SET NOCOUNT ON

--#################################################
-- 1) ew_cxc_transacciones
--#################################################

SELECT
	[transaccion] = ct.transaccion
	,[idsucursal] = ct.idsucursal
	,[folio] = ct.folio
	,[fecha] = ct.fecha
	,[idcuenta] = ct.idcuenta
	,[idconcepto] = ct.idconcepto
	,[tipo] = ct.tipo
	,[cancelado] = ct.cancelado
	,[cancelado_fecha] = ct.cancelado_fecha
	,[idu] = ct.idu
	,[idr] = ct.idr
	,[idtran] = ct.idtran
	,[idmov] = ct.idmov
	,[codcliente] = c.codigo
	,[nombre] = c.nombre
	,[idcliente] = ct.idcliente
	,[spa] = ''
	,[total] = ct.total
	,[impuesto1] = ct.impuesto1
	,[subtotal] = ct.subtotal
	,[saldo] = ct.saldo
	,[comentario] = ct.comentario
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = ct.idcliente
WHERE
	ct.idtran = @idtran

--#################################################
-- 2) ew_ban_transacciones
--#################################################

SELECT
	[transaccion] = bt.transaccion
	,[idsucursal] = bt.idsucursal
	,[folio] = bt.folio
	,[fecha] = bt.fecha
	,[idcuenta] = bt.idcuenta
	,[idconcepto] = bt.idconcepto
	,[contabilidad] = bc.contabilidad1
	,[cancelado] = bt.cancelado
	,[cancelado_fecha] = bt.cancelado_fecha
	,[idu] = bt.idu
	,[idr] = bt.idr
	,[idtran] = bt.idtran
	,[idmov] = bt.idmov
	,[tipo] = bt.tipo
	,[total] = bt.total
	,[impuesto1] = bt.impuesto
	,[subtotal] = bt.subtotal
	,[comentario] = bt.comentario
FROM
	ew_ban_transacciones AS bt
	LEFT JOIN ew_ban_cuentas AS bc
		ON bc.idcuenta = bt.idcuenta
WHERE
	bt.idtran = @idtran
	
--#################################################
-- 3) contabilidad
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
-- 4) bitacora
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
