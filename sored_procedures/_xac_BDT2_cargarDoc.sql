USE db_comercial_final
GO
IF OBJECT_ID('_xac_BDT2_cargarDoc') IS NOT NULL
BEGIN
	DROP PROCEDURE _xac_BDT2_cargarDoc
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190430
-- Description:	Cargar integracion de deposito bancario
-- =============================================
CREATE PROCEDURE _xac_BDT2_cargarDoc
	@idtran AS INT
AS

SET NOCOUNT ON

-- Tabla: ew_ban_documentos
SELECT
	[transaccion] = bd.transaccion
	, [idsucursal] = bd.idsucursal
	, [fecha] = bd.fecha
	, [idcuenta1] = bd.idcuenta1
	, [idmoneda] = bd.idmoneda
	, [tipocambio] = bd.tipocambio
	, [folio] = bd.folio
	, [idu] = bd.idu
	, [cancelado] = bd.cancelado
	, [cancelado_fecha] = (CASE WHEN bd.cancelado = 0 THEN NULL ELSE bd.cancelado_fecha END)
	, [estado] = [dbo].[fn_sys_estadoActualNombre](bd.idtran)
	, [idr] = bd.idr
	, [idtran] = bd.idtran
	, [idmov] = bd.idmov
	, [idcuenta2] = bd.idcuenta2
	, [idmoneda2] = bd.idmoneda2
	, [tipocambio2] = bd.tipocambio2
	, [idconcepto] = bd.idconcepto
	, [fecha2] = bd.fecha2
	, [fecha3] = bd.fecha3
	, [idforma] = bd.idforma
	, [formas] = ''
	, [formas_ejecutar] = 'Obtener...'
	, [spa1] = ''
	, [importe] = bd.importe
	, [comentario] = bd.comentario
	, [spa3] = ''
FROM
	ew_ban_documentos AS bd
WHERE
	bd.idtran = @idtran

-- Tabla: ew_ban_documentos_mov
SELECT
	[ref_forma] = bf.nombre
	, [ref_fecha] = bt.fecha
	, [ref_movimiento] = o.nombre
	, [ref_folio] = bt.folio
	, [idforma] = bdm.idforma
	, [cantidad] = bdm.cantidad
	, [pago_total] = bt.total
	, [pago_saldo] = (
		bt.importe 
		- ISNULL((
			SELECT SUM(bdm1.importe) 
			FROM 
				ew_ban_documentos_mov AS bdm1 
				LEFT JOIN ew_ban_documentos AS bd1 
					ON bd1.idtran = bdm1.idtran
			WHERE
				bdm1.idtran2 = bt.idtran
				AND bd1.cancelado = 0
		), 0)
	)
	, [importe] = bdm.importe
	, [idtran2] = bdm.idtran2
	, [objidtran] = bdm.idtran2
	, [comentario] = bdm.comentario
	, [idr] = bdm.idr
	, [idtran] = bdm.idtran
	, [idmov] = bdm.idmov
	, [spa2] = ''
FROM
	ew_ban_documentos_mov AS bdm
	LEFT JOIN ew_ban_transacciones AS bt 
		ON bt.idtran = bdm.idtran2
	LEFT JOIN objetos AS o
		ON o.codigo = bt.transaccion
	LEFT JOIN ew_ban_formas AS bf
		ON bf.idforma = bt.idforma
WHERE
	bdm.idtran = @idtran

-- Tabla: contabilidad
SELECT *
FROM
	contabilidad
WHERE
	idtran2 = @idtran

-- Tabla: bitacora
SELECT *
FROM
	bitacora
WHERE
	idtran = @idtran
GO
