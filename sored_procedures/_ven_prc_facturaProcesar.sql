USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091113
-- Modificacion: Arvin 2010JUL agregar pagos de factura.

-- Description:	Procesar factura de cliente.
-- EXEC _ven_prc_facturaProcesar 981

-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_facturaProcesar]
	@idtran AS BIGINT
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- VALIDAR DATOS 

DECLARE
	@surtir AS BIT

SELECT @surtir = dbo.fn_sys_parametro('VEN_SURFAC')

--------------------------------------------------------------------------------
-- SURTIR MERCANCIA 

IF @surtir = 1
BEGIN
	DECLARE
		@idsucursal AS SMALLINT
		,@idu AS SMALLINT
		,@sql AS VARCHAR(2000)
		,@salida_idtran AS BIGINT
		,@usuario AS VARCHAR(20)
		,@password AS VARCHAR(20)
		,@idtran2 AS INT
	
	--Obtener datos de factura.
	SELECT
		@idsucursal = idsucursal
		,@idu = idu
	FROM 
		ew_ven_transacciones
	WHERE
		idtran = @idtran
	
	SELECT
		@usuario = usuario
		,@password = [password]
	FROM
		ew_usuarios
	WHERE
		idu = @idu
	
	-- Crear salida de almacén. -----------------------
	IF EXISTS(
		SELECT	
			m.idarticulo 
		FROM	
			ew_ven_transacciones_mov AS m
			LEFT JOIN ew_articulos AS a 
				ON a.idarticulo = m.idarticulo
		WHERE
			m.cantidad_facturada != 0
			AND m.cantidad_surtida != 0
			AND a.inventariable = 1
			AND idtran = @idtran
		)
	BEGIN
		SELECT
		@sql = 'INSERT INTO ew_inv_transacciones
		(idtran, idtran2, idsucursal, idalmacen, fecha, folio, transaccion,
		referencia, comentario,idconcepto)
	SELECT
		{idtran}, idtran, idsucursal, idalmacen, fecha, ''{folio}'', ''GDA1'',
		''EFA1 - '' + folio, comentario, 19
	FROM 
		ew_ven_transacciones
	WHERE
		idtran = ' + CONVERT(VARCHAR(20), @idtran) + '

	INSERT INTO ew_inv_transacciones_mov
		(idtran,idtran2, idmov2, consecutivo, tipo, idalmacen,
		idarticulo, series, lote, fecha_caducidad, idcapa, idum,
		cantidad, afectainv, comentario)
	SELECT
		[idtran] = {idtran}
		,[idtran2] = m.idtran
		,[idmov2] = m.idmov
		,[consecutivo] = ROW_NUMBER() OVER (ORDER BY m.idr)
		,[tipo] = 2
		,[idalmacen] = m.idalmacen
		,[idarticulo] = m.idarticulo
		,[series] = m.series
		,[lote] = ic.lote
		,[fecha_caducidad] = ic.fecha_caducidad
		,[idcapa] = m.idcapa
		,[idum] = m.idum
		,[cantidad] = m.cantidad_surtida*um.factor
		,[afectainv] = 1
		,[comentario] = m.comentario
	FROM 
		ew_ven_transacciones_mov m
		LEFT JOIN ew_articulos a ON a.idarticulo=m.idarticulo
		LEFT JOIN ew_inv_capas ic ON m.idcapa = ic.idcapa AND m.idarticulo = ic.idarticulo
		LEFT JOIN ew_cat_unidadesmedida um ON m.idum = um.idum
	WHERE
		m.cantidad_facturada!=0
		AND m.cantidad_surtida!=0
		AND a.inventariable=1
		AND m.idtran = ' + CONVERT(VARCHAR(20), @idtran) 
		
		IF @sql IS NULL OR @sql = ''
		BEGIN
			RAISERROR('No se pudo obtener información para registrar salida.', 16, 1)
			RETURN
		END
		
		EXEC _sys_prc_insertarTransaccion
			@usuario
			,@password
			,'GDA1' --Transacción
			,@idsucursal
			,'A' --Serie
			,@sql
			,6 --Longitod del folio
			,@salida_idtran OUTPUT
			,'' --Afolio
			,'' --Afecha

		IF @salida_idtran IS NULL OR @salida_idtran = 0
		BEGIN
			RAISERROR('No se pudo crear salida de almacén.', 16, 1)
			RETURN
		END
		
		--Actualizar el costo de los artículos
		UPDATE fcd SET
			fcd.costo = ISNULL(itm.costo,0)
		FROM 
			ew_ven_transacciones_mov AS fcd
			LEFT JOIN ew_inv_transacciones_mov AS itm ON itm.idmov2 = fcd.idmov AND itm.tipo = 2
			LEFT JOIN ew_inv_transacciones AS it ON it.idtran = itm.idtran
		WHERE
			fcd.idtran = @idtran
			AND it.idtran2 = @idtran
		
		--------------------------------------------------------------------
		-- Referenciando en el Tracking la salida de almacen
		INSERT INTO ew_sys_movimientos_acumula 
			(idmov1,idmov2,campo,valor)
		VALUES
			(@idtran,@salida_idtran,'',0)
	END
	
END

--------------------------------------------------------------------
-- Surtimos la mercancia en la orden 
--------------------------------------------------------------------
INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	,idmov2
	,campo
	,valor
)
SELECT 
	[idmov] = m.idmov
	,[idmov2] = m.idmov2
	,[campo] = 'cantidad_surtida'
	,[valor] = m.cantidad_surtida
FROM	
	ew_ven_transacciones_mov AS m
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = m.idarticulo
WHERE 
	m.cantidad_surtida ! =0
	AND idtran = @idtran
	AND a.inventariable = 1

--------------------------------------------------------------------
-- Indicamos la mercancia facturada en la orden 
--------------------------------------------------------------------
INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	,idmov2
	,campo
	,valor
)
SELECT 
	[idmov] = idmov
	,[idmov2] = idmov2
	,[campo] = 'cantidad_facturada'
	,[valor] = cantidad_facturada 
FROM	
	ew_ven_transacciones_mov
WHERE 
	idtran = @idtran
	AND cantidad_facturada != 0

-- aplicar los pagos si la factura es de contado ---
IF EXISTS (
	SELECT idtran 
	FROM 
		ew_ven_transacciones 
	WHERE
		credito = 0
		AND idtran = @idtran
)
BEGIN
	EXEC _ven_prc_facturaPagos @idtran
END
	ELSE
BEGIN
	DELETE FROM ew_ven_transacciones_pagos WHERE idtran = @idtran
END

--------------------------------------------------------------------
-- Cambiamos el estado de la orden
--------------------------------------------------------------------
DECLARE cur_detalle CURSOR FOR
	SELECT DISTINCT 
		[idtran]=FLOOR(fm.idmov2)
	FROM
		ew_ven_transacciones_mov fm 
	WHERE
		fm.idtran=@idtran
		AND fm.cantidad_facturada > 0

OPEN cur_detalle
	
FETCH NEXT FROM cur_detalle INTO
	@idtran2

WHILE @@fetch_status=0
BEGIN
	EXEC _ven_prc_ordenEstado @idtran2, @idu
	
	FETCH NEXT FROM cur_detalle INTO 
		@idtran2
END

CLOSE cur_detalle
DEALLOCATE cur_detalle

IF @surtir = 1
BEGIN
	SELECT 
		costo = ISNULL(SUM(costo), 0) 
	FROM 
		ew_ven_transacciones_mov 
	WHERE 
		idtran = @idtran
END
GO
