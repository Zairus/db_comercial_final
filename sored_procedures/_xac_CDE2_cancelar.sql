USE db_comercial_final
GO
IF OBJECT_ID('_xac_CDE2_cancelar') IS NOT NULL
BEGIN
	DROP PROCEDURE _xac_CDE2_cancelar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200414
-- Description:	Cancelar devolución de compras.
-- =============================================
CREATE PROCEDURE [dbo].[_xac_CDE2_cancelar]
	@idtran AS INT
	, @idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@ent_idtran AS INT
	, @usuario AS VARCHAR(20)
	, @password AS VARCHAR(20)
	, @transaccion AS VARCHAR(5) = 'GDC1'
	, @idsucursal AS INT
	, @fecha AS DATETIME
	, @cancelado_fecha AS DATETIME

-- ##############################################################
-- OBTENER DATOS DE TRANSACCION

SELECT
	@cancelado_fecha = ct.fecha
	, @usuario = u.usuario
	, @password = u.[password]
	, @idsucursal = ct.idsucursal
	, @fecha = ct.fecha
FROM
	ew_com_transacciones AS ct
	LEFT JOIN evoluware_usuarios AS u
		ON u.idu = ct.idu
WHERE
	ct.idtran = @idtran

-- ##############################################################
-- DETERMINAR SI SE REALIZARA ENTRADA A ALMACEN Y APLICAR

IF (
	SELECT COUNT(*) 
	FROM 
		ew_inv_transacciones AS it 
		LEFT JOIN ew_inv_transacciones_mov AS itm
			ON itm.idtran = it.idtran
	WHERE 
		it.idtran2 = @idtran
		AND itm.tipo = 2
) = 0
BEGIN
	GOTO DEVOLUCION_APLICADA
END

-- ##############################################################
-- CREAR REGISTRO DE TRANSACCION

EXEC [dbo].[_sys_prc_insertarTransaccion]
	@usuario = @usuario
	, @password = @password
	, @transaccion = @transaccion
	, @idsucursal = @idsucursal
	, @serie = 'A'
	, @sql = ''
	, @foliolen = 6
	, @idtran = @ent_idtran OUTPUT
	, @afolio = ''
	, @afecha = ''

INSERT INTO ew_inv_transacciones (
	idtran
	, idtran2
	, idsucursal
	, idconcepto
	, idalmacen
	, fecha
	, folio
	, transaccion
	, referencia
	, comentario
)
SELECT
	[idtran] = st.idtran
	, [idtran2] = dev.idtran
	, [idsucursal] = dev.idsucursal
	, [idconcepto] = 1017
	, [idalmacen] = dev.idalmacen
	, [fecha] = @fecha
	, [folio] = st.folio
	, [transaccion] = st.transaccion
	, [referencia] = dev.transaccion + ' - ' + dev.folio
	, [comentario] = dev.comentario
FROM
	ew_sys_transacciones AS st
	LEFT JOIN ew_com_transacciones AS dev
		ON dev.idtran = @idtran
WHERE
	st.idtran = @ent_idtran

INSERT INTO ew_inv_transacciones_mov (
	idtran
	, idmov2
	, consecutivo
	, tipo
	, idalmacen
	, idarticulo
	, series
	, lote
	, fecha_caducidad
	, idum
	, cantidad
	, costo
	, afectainv
	, comentario
)
SELECT
	[idtran] = st.idtran
	, [idmov2] = itm.idmov
	, [consecutivo] = ROW_NUMBER() OVER (ORDER BY itm.idr)
	, [tipo] = 1
	, [idalmacen] = itm.idalmacen
	, [idarticulo] = itm.idarticulo
	, [series] = itm.series
	, [lote] = itm.lote
	, [fecha_caducidad] = itm.fecha_caducidad
	, [idum] = itm.idum
	, [cantidad] = itm.cantidad
	, [costo] = itm.costo
	, [afectainv] = 1
	, [comentario] = itm.comentario
FROM
	ew_inv_transacciones AS it
	LEFT JOIN ew_inv_transacciones_mov AS itm
		ON itm.idtran = it.idtran
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = @ent_idtran
WHERE
	it.idtran2 = @idtran
	AND itm.tipo = 2

DEVOLUCION_APLICADA:

-- ##############################################################
-- ACTUALIZAR CANTIDADES DEVUELTAS EN ORDEN DE COMPRA

INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	, idmov2
	, campo
	, valor
)
SELECT 
	[idmov1] = idmov
	, [idmov2] = idmov2
	, [campo] = 'cantidad_devuelta'
	, [valor] = ISNULL(cantidad_devuelta, 0) * -1
FROM 
	ew_com_transacciones_mov
WHERE 
	idtran = @idtran

-- ##############################################################
-- CANCELAR EN CXP Y CONTABILIZAR CANCELACION

UPDATE ew_com_transacciones SET 
	cancelado = 1
	, cancelado_fecha = @cancelado_fecha
WHERE
	idtran = @idtran

EXEC [dbo].[_cxp_prc_cancelarTransaccion] @idtran, @cancelado_fecha, @idu

EXEC [dbo].[_ct_prc_transaccionCancelarContabilidad] @idtran, 3, @cancelado_fecha, @idu
GO
