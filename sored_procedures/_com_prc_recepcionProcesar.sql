USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091029
-- Description:	Procesar recepción
-- =============================================
ALTER PROCEDURE [dbo].[_com_prc_recepcionProcesar]
	@idtran AS BIGINT
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACION DE VARIABLES ####################################################

DECLARE
	@idsucursal AS SMALLINT
	,@idu AS SMALLINT

DECLARE
	@sql AS VARCHAR(2000)
	,@entrada_idtran AS BIGINT
	,@usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)
	,@idmoneda AS TINYINT

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

SELECT
	@idsucursal = ct.idsucursal
	,@idu = ct.idu
	,@idmoneda = ct.idmoneda
FROM 
	ew_com_transacciones AS ct
WHERE
	ct.idtran = @idtran

SELECT
	@usuario = usuario
	,@password = [password]
FROM ew_usuarios
WHERE
	idu = @idu

IF @idmoneda <> 0
BEGIN
	IF EXISTS (
		SELECT * 
		FROM
			ew_com_transacciones_mov AS ctm
			LEFT JOIN ew_com_ordenes AS cor
				ON cor.idtran = ctm.idtran2
			LEFT JOIN ew_com_transacciones AS cfa
				ON cfa.idtran2 = cor.idtran
		WHERE
			ctm.idtran = @idtran
			AND cfa.idr IS NULL
	)
	BEGIN
		RAISERROR('Error: No existe factura de compra para la orden indicada.', 16, 1)
		RETURN
	END
END

--------------------------------------------------------------------------------
-- CREAR ENTRADA A ALMACEN #####################################################

SELECT
	@sql = 'INSERT INTO ew_inv_transacciones
	(idtran, idtran2, idsucursal, idalmacen, fecha, folio, transaccion,
	referencia,idconcepto, comentario)
SELECT
	{idtran}, idtran, idsucursal, idalmacen, fecha, ''{folio}'', ''GDC1'',
	''CRE1 - '' + folio, 16, comentario
FROM ew_com_transacciones
WHERE
	idtran = ' + CONVERT(VARCHAR(20), @idtran) + '

INSERT INTO ew_inv_transacciones_mov
	(idtran, idtran2, idmov2, consecutivo, tipo, idalmacen,
	idarticulo, series, lote, fecha_caducidad, idum,
	cantidad, costo, afectainv, comentario)
SELECT
	[idtran] = {idtran}
	,[idtran2] = ctm.idtran
	,ctm.idmov
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY ctm.idr)
	,[tipo] = 1
	,[idlamacen] = ctm.idalmacen
	,[idarticulo] = ctm.idarticulo
	,[series] = ctm.series
	,[lote] = ctm.lote
	,[fecha_caducidad] = ctm.fecha_caducidad
	,[idum] = a.idum_almacen
	,[cantidad] = ctm.cantidad_recibida * (CASE WHEN um.factor = NULL THEN 1 ELSE um.factor END)
	,[costo] = (
		(
			ctm.importe
			*(
				CASE
					WHEN ctm.idmoneda = 0 THEN 1 
					ELSE dbo.fn_ban_obtenerTC(cfa.cfa_idmoneda, cfa.cfa_fecha)
				END
			)
		)
		+ctm.gastos
	)
	,[afectainv] = 1
	,[comentario] = ctm.comentario
FROM
	ew_com_transacciones_mov AS ctm
	LEFT JOIN ew_com_transacciones AS ct ON ct.idtran = ctm.idtran
	LEFT JOIN ew_ban_monedas AS bm ON bm.idmoneda = ctm.idmoneda
	LEFT JOIN ew_articulos a ON a.idarticulo = ctm.idarticulo
	LEFT JOIN ew_cat_unidadesmedida um ON a.idum_compra = um.idum

	LEFT JOIN ew_com_ordenes AS cor ON cor.idtran = ctm.idtran2
	OUTER APPLY (
		SELECT TOP 1
			[cfa_idmoneda] = cfa1.idmoneda
			,[cfa_fecha] = cfa1.fecha
		FROM
			ew_com_transacciones AS cfa1
		WHERE
			cfa1.idtran2 = cor.idtran
	) AS cfa
WHERE
	ctm.cantidad_recibida > 0
	AND ctm.idtran = ' + CONVERT(VARCHAR(20), @idtran)

IF @sql IS NULL OR @sql = ''
BEGIN
	RAISERROR('No se pudo obtener información para registrar entrada.', 16, 1)
	RETURN
END

EXEC _sys_prc_insertarTransaccion
	@usuario
	,@password
	,'GDC1' --Transacción
	,@idsucursal
	,'A' --Serie
	,@sql
	,6 --Longitod del folio
	,@entrada_idtran OUTPUT
	,'' --Afolio
	,'' --Afecha

IF @entrada_idtran IS NULL OR @entrada_idtran = 0
BEGIN
	RAISERROR('No se pudo crear entrada a almacén.', 16, 1)
	RETURN
END

--------------------------------------------------------------------------------
-- ACTUALIZAR CANTIDADES RECIBIDAS DE OC #######################################

INSERT INTO ew_sys_movimientos_acumula 
	(idmov1,idmov2,campo,valor)
SELECT 
	idmov
	,idmov2
	,[campo] = 'cantidad_surtida'
	,[valor] = cantidad_recibida
FROM 
	ew_com_transacciones_mov
WHERE 
	idtran = @idtran

UPDATE co SET
	co.tipocambio = rd.tipocambio
FROM 
	ew_com_transacciones_mov AS rd
	LEFT JOIN ew_com_ordenes_mov AS com
		ON com.idmov = rd.idmov2
	LEFT JOIN ew_com_ordenes AS co
		ON co.idtran = com.idtran
WHERE
	co.idmoneda > 0
	AND rd.idtran = @idtran

INSERT INTO ew_sys_transacciones2 (
	idtran
	,idestado
)
SELECT DISTINCT
	co.idtran
	,[idestado] = (
		CASE 
			WHEN (com.cantidad_ordenada - com.cantidad_surtida) > 0 THEN
				dbo.fn_sys_estadoID('SUR~')
			WHEN (com.cantidad_ordenada - com.cantidad_surtida) = 0 THEN
				dbo.fn_sys_estadoID('RCBO')
		END
	)
FROM 
	ew_com_transacciones_mov AS rd
	LEFT JOIN ew_com_ordenes_mov AS com
		ON com.idmov = rd.idmov2
	LEFT JOIN ew_com_ordenes AS co
		ON co.idtran = com.idtran
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = co.idtran
WHERE
	(
		(
			(com.cantidad_ordenada - com.cantidad_surtida) > 0
			AND st.idestado < dbo.fn_sys_estadoID('SUR~')
		)
		OR (
			(com.cantidad_ordenada - com.cantidad_surtida) = 0
			AND st.idestado < dbo.fn_sys_estadoID('RCBO')
		)
	)
	AND rd.idtran = @idtran
GO
