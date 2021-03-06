USE db_comercial_final
GO
IF OBJECT_ID('_com_prc_facturaCompraProcesar') IS NOT NULL
BEGIN
	DROP PROCEDURE _com_prc_facturaCompraProcesar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110429
-- Description:	Procesar factura de compra
-- =============================================
CREATE PROCEDURE [dbo].[_com_prc_facturaCompraProcesar]
	@idtran AS INT
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACION DE VARIABLES ####################################################

DECLARE
	@idsucursal AS SMALLINT
	, @idtran_oc AS INT
	, @idu AS SMALLINT

DECLARE
	@sql AS VARCHAR(2000)
	, @entrada_idtran AS BIGINT
	, @usuario AS VARCHAR(20)
	, @password AS VARCHAR(20)

DECLARE
	@gastos_incluidos AS DECIMAL(18,6)
	, @importe_sin_gasto AS DECIMAL(18,6)
	, @prorratear AS BIT
	, @surtir AS BIT

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

SELECT
	@idsucursal = ct.idsucursal
	, @idu = ct.idu
	, @idtran_oc = ISNULL(co.idtran, 0)
FROM 
	ew_com_transacciones AS ct
	LEFT JOIN ew_com_ordenes AS co
		ON co.idtran = ct.idtran2
WHERE
	ct.idtran = @idtran

SELECT
	@usuario = usuario
	, @password = [password]
FROM 
	ew_usuarios
WHERE
	idu = @idu

SELECT
	@importe_sin_gasto = SUM(ctm.importe)
FROM
	ew_com_transacciones_mov AS ctm
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = ctm.idarticulo
WHERE
	a.idtipo = 0
	AND ctm.idtran = @idtran

SELECT
	@gastos_incluidos = SUM(ctm.importe)
FROM
	ew_com_transacciones_mov AS ctm
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = ctm.idarticulo
WHERE
	a.idtipo = 2
	AND ctm.idtran = @idtran

SELECT @importe_sin_gasto = ISNULL(@importe_sin_gasto, 0)
SELECT @gastos_incluidos = ISNULL(@gastos_incluidos, 0)
SELECT @prorratear = dbo._sys_fnc_parametroActivo('COM_PRORRATEO_EN_FACTURA')
SELECT @surtir = dbo._sys_fnc_parametroActivo('COM_NOTA_COMPRA_SURTIR')

IF EXISTS (
	SELECT *
	FROM
		ew_com_transacciones AS ct
	WHERE
		ct.idtran = @idtran
		AND ct.idtran2 = 0
		AND @surtir = 0
)
BEGIN
	RAISERROR('Error: No es posible registrar compra directa cuando el parametro COM_NOTA_COMPRA_SURTIR no esta activo.', 16, 1)
	RETURN
END

--------------------------------------------------------------------------------
-- CREAR ENTRADA A ALMACEN #####################################################

IF @surtir = 1
BEGIN
	SELECT @sql = ''

	EXEC _sys_prc_insertarTransaccion
		@usuario
		, @password
		, 'GDC1' --Transacción
		, @idsucursal
		, 'A' --Serie
		, @sql
		, 6 --Longitod del folio
		, @entrada_idtran OUTPUT
		, '' --Afolio
		, '' --Afecha

	IF @entrada_idtran IS NULL OR @entrada_idtran = 0
	BEGIN
		RAISERROR('No se pudo crear entrada a almacén.', 16, 1)
		RETURN
	END

	INSERT INTO ew_inv_transacciones (
		idtran
		, idtran2
		, idsucursal
		, idalmacen
		, fecha
		, folio
		, transaccion
		, idconcepto
		, referencia
		, comentario
	)
	SELECT
		[idtran] = st.idtran
		, [idtran2] = ct.idtran
		, [idsucursal] = ct.idsucursal
		, [idalmacen] = ct.idalmacen
		, [fecha] = ct.fecha
		, [folio] = st.folio
		, [transaccion] = 'GDC1'
		, [idconcepto] = 16
		, [referencia] = 'CRE1 - ' + ct.folio
		, [comentario] = ct.comentario
	FROM 
		ew_com_transacciones AS ct
		LEFT JOIN ew_sys_transacciones AS st
			ON st.idtran = @entrada_idtran
	WHERE
		ct.idtran = @idtran

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
		, identidad
	)
	SELECT
		[idtran] = st.idtran
		, [idmov2] = ctm.idmov
		, [consecutivo] = ROW_NUMBER() OVER (ORDER BY ctm.idr)
		, [tipo] = 1
		, [idlamacen] = ISNULL(NULLIF(ctm.idalmacen, 0), ct.idalmacen)
		, [idarticulo] = ctm.idarticulo
		, [series] = ctm.series
		, [lote] = ctm.lote
		, [fecha_caducidad] = ctm.fecha_caducidad
		, [idum] = a.idum_almacen
		, [cantidad] = (ctm.cantidad_facturada * ISNULL(auf.factor, 1))
		, [costo] = (
			CASE
				WHEN ct.idmoneda = 0 THEN ctm.importe 
				ELSE (ctm.importe * ct.tipocambio)
			END
			+ ctm.gastos
			+ (
				CASE
					WHEN @gastos_incluidos > 0 AND @prorratear = 1 THEN
						(
							@gastos_incluidos
							* (ctm.importe / @importe_sin_gasto)
						)
					ELSE 0
				END
			)
		)
		, [afectainv] = 1
		, [comentario] = ctm.comentario
		, [identidad] = ct.idproveedor
	FROM 
		ew_com_transacciones_mov AS ctm
		LEFT JOIN ew_com_transacciones AS ct
			ON ct.idtran = ctm.idtran
		LEFT JOIN ew_articulos AS a
			ON a.idarticulo = ctm.idarticulo
		LEFT JOIN ew_articulos_unidades_factores AS auf
			ON auf.idum_base = a.idum_compra
			AND auf.idum_producto = a.idum_almacen

		LEFT JOIN ew_sys_transacciones AS st
			ON st.idtran = @entrada_idtran
	WHERE
		ctm.cantidad_facturada > 0
		AND a.inventariable = 1
		AND a.idtipo = 0
		AND ctm.idtran = @idtran
END

--------------------------------------------------------------------------------
-- ACTUALIZAR ESTADO ORDEN COMPRA ##############################################

IF @idtran_oc > 0
BEGIN
	INSERT INTO ew_sys_movimientos_acumula (
		idmov1
		, idmov2
		, campo
		, valor
	)
	SELECT 
		[idmov1] = idmov
		, [idmov2] = idmov2
		, [campo] = 'cantidad_facturada'
		, [valor] = cantidad_facturada 
	FROM
		ew_com_transacciones_mov
	WHERE
		idtran = @idtran
		AND idmov2 > 0

	INSERT INTO ew_sys_movimientos_acumula (
		idmov1
		, idmov2
		, campo
		, valor
	)
	SELECT 
		[idmov1] = idmov
		, [idmov2] = idmov2
		, [campo] = 'cantidad_surtida'
		, [valor] = cantidad_facturada 
	FROM
		ew_com_transacciones_mov
	WHERE
		idtran = @idtran
		AND @surtir = 1
		AND idmov2 > 0
		
	EXEC _com_prc_ordenEstado @idtran_oc, @idu
END

--------------------------------------------------------------------------------
-- CONTABILIZAR ################################################################

EXEC _ct_prc_polizaAplicarDeConfiguracion @idtran, 'CFA2', @idtran
GO
