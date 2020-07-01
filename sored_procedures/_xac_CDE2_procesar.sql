USE db_comercial_final
GO
IF OBJECT_ID('_xac_CDE2_procesar') IS NOT NULL
BEGIN
	DROP PROCEDURE _xac_CDE2_procesar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200414
-- Description:	Procesar devolución de compras.
-- =============================================
CREATE PROCEDURE [dbo].[_xac_CDE2_procesar]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@devolver AS BIT

DECLARE
	@sal_idtran AS INT
	, @usuario AS VARCHAR(20)
	, @password AS VARCHAR(20)
	, @transaccion AS VARCHAR(5) = 'GDA1'
	, @idsucursal AS INT
	, @fecha AS DATETIME
	, @idu AS INT

-- ##############################################################
-- DETERMINAR SI SE REALIZARA DEVOLUCION

SELECT TOP 1
	@devolver = (
		CASE
			WHEN ISNULL(alm.permitir_devolucion, 0) = 1 OR ISNULL(almd.permitir_devolucion, 0) = 1 THEN 1
			ELSE 0
		END
	)
FROM
	ew_com_transacciones AS cde
	LEFT JOIN ew_inv_almacenes AS alm
		ON alm.idalmacen = cde.idalmacen
	LEFT JOIN ew_com_transacciones_mov AS cdem
		ON cdem.idtran = cde.idtran
	LEFT JOIN ew_inv_almacenes AS almd
		ON almd.idalmacen = cdem.idalmacen
WHERE
	cde.idtran = @idtran
ORDER BY
	ISNULL(alm.permitir_devolucion, 0) DESC
	, ISNULL(almd.permitir_devolucion, 0) DESC

SELECT @devolver = ISNULL(@devolver, 0)

IF @devolver = 0
BEGIN
	GOTO DEVOLUCION_APLICADA
END

-- ##############################################################
-- OBTENER DATOS DE TRANSACCION

SELECT
	@usuario = u.usuario
	, @password = u.[password]
	, @idsucursal = ct.idsucursal
	, @fecha = ct.fecha
	, @idu = ct.idu
FROM
	ew_com_transacciones AS ct
	LEFT JOIN evoluware_usuarios AS u
		ON u.idu = ct.idu
WHERE
	ct.idtran = @idtran

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
	, @idtran = @sal_idtran OUTPUT
	, @afolio = ''
	, @afecha = ''

-- ##############################################################
-- INSERTAR REGISTROS DE LA DEVOLUCION

INSERT INTO ew_inv_transacciones (
	idtran
	, idtran2
	, idsucursal
	, idalmacen
	, fecha
	, folio
	, transaccion
	, referencia
	, comentario
	, idconcepto
)
SELECT
	[idtran] = st.idtran
	, [idtran2] = dev.idtran
	, [idsucursal] = @idsucursal
	, [idalmacen] = dev.idalmacen
	, [fecha] = st.fecha
	, [folio] = st.folio
	, [transaccion] = st.transaccion
	, [referencia] = dev.transaccion + ' - ' + dev.folio
	, [comentario] = ''
	, [idconcepto] = 17
FROM
	ew_sys_transacciones AS st
	LEFT JOIN ew_com_transacciones AS dev
		ON dev.idtran = @idtran
WHERE
	st.idtran = @sal_idtran

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
	, afectainv
	, comentario
)
SELECT
	[idtran] = st.idtran
	, [idmov2] = devm.idmov
	, [consecutivo] = ROW_NUMBER() OVER (ORDER BY devm.idr)
	, [tipo] = 2
	, [idalmacen] = devm.idalmacen
	, [idarticulo] = devm.idarticulo
	, [series] = devm.series
	, [lote] = devm.lote
	, [fecha_caducidad] = devm.fecha_caducidad
	, [idum] = devm.idum
	, [cantidad] = devm.cantidad_devuelta
	, [afectainv] = 1
	, [comentario] = devm.comentario
FROM
	ew_sys_transacciones AS st
	LEFT JOIN ew_com_transacciones AS dev
		ON dev.idtran = @idtran
	LEFT JOIN ew_com_transacciones_mov AS devm
		ON devm.idtran = dev.idtran
	LEFT JOIN ew_inv_almacenes AS alm
		ON alm.idalmacen = devm.idalmacen
WHERE
	st.idtran = @sal_idtran
	AND alm.permitir_devolucion = 1

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
	, [valor] = cantidad_devuelta
FROM 
	ew_com_transacciones_mov
WHERE 
	idtran = @idtran
	
-- ##############################################################
-- ACTUALIZAR EN CXP Y CONTABILIZAR

EXEC [dbo].[_cxp_prc_aplicarTransaccion] @idtran, @fecha, @idu

EXEC [dbo].[_ct_prc_polizaAplicarDeConfiguracion] @idtran, 'CDE1', @idtran
GO