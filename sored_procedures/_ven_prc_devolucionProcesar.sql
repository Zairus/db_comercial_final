USE db_comercial_final
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 201104
-- Modificacion: 

-- Description:	Procesar nota de crédito por devolucion de cliente.
-- EXEC _ven_prc_devolucionProcesar 0

-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_devolucionProcesar]
	@idtran AS BIGINT
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- VALIDAR DATOS 


DECLARE
	@surtir AS BIT
	,@msg		VARCHAR(250)

SELECT @surtir = dbo.fn_sys_parametro('VEN_SURFAC')

--------------------------------------------------------------------------------
-- SURTIR MERCANCIA 

IF @surtir = 1
BEGIN
	DECLARE
		@idsucursal		SMALLINT
		,@idu			SMALLINT
		,@sql			VARCHAR(2000)
		,@salida_idtran	BIGINT
		,@usuario		VARCHAR(20)
		,@password		VARCHAR(20)
		,@idtran2		INT
	
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
	FROM ew_usuarios
	WHERE
		idu = @idu
	
	-- Crear salida de almacén. -----------------------
	IF EXISTS(
		SELECT	
			m.idarticulo 
		FROM	
			ew_ven_transacciones_mov m
			LEFT JOIN ew_articulos a ON a.idarticulo=m.idarticulo
		WHERE
			m.cantidad!=0
			AND a.inventariable=1
			AND idtran = @idtran
		)
	BEGIN
		SELECT
		@sql = 'INSERT INTO ew_inv_transacciones (
			idtran
			, idtran2
			, idsucursal
			, idalmacen
			, fecha
			, folio
			, transaccion
			, referencia
			, comentario
			, idconcepto)
	SELECT
		{idtran}
		, idtran
		, idsucursal
		, idalmacen
		, fecha
		, ''{folio}''
		, ''GDC2''
		, ''EDE1 - '' + folio
		, comentario
		, 20
	FROM 
		ew_ven_transacciones
	WHERE
		idtran = ' + CONVERT(VARCHAR(20), @idtran) + '

	INSERT INTO ew_inv_transacciones_mov (
		idtran
		, idtran2
		, idmov2
		, afectaref
		, consecutivo
		, tipo
		, idalmacen
		, idarticulo
		, series
		, lote
		, fecha_caducidad
		, idcapa
		, idum
		, cantidad
		, costo
		, afectainv
		, comentario)
	SELECT
		[idtran] = {idtran}
		,[idtran2] = m.idtran
		,[idmov2] = itm.idmov
		,[afectaref] = 1
		,[consecutivo] = ROW_NUMBER() OVER (ORDER BY m.idr)
		,[tipo] = 1
		,[idlamacen] = m.idalmacen
		,[idarticulo] = m.idarticulo
		,[series] = m.series
		,[lote] = ic.lote
		,[fecha_caducidad] = ic.fecha_caducidad
		,[idcapa] = m.idcapa
		,[idum] = m.idum
		,[cantidad] = m.cantidad
		,[costo] = m.costo
		,[afectainv] = 1
		,[comentario] = m.comentario
	FROM 
		ew_ven_transacciones_mov m 
		LEFT JOIN ew_inv_transacciones_mov itm 
			ON itm.tipo = 2
			AND itm.idmov2 = m.idmov2
		LEFT JOIN ew_articulos a 
			ON a.idarticulo = m.idarticulo
		LEFT JOIN ew_inv_capas ic 
			ON ic.idcapa = m.idcapa 
			AND ic.idarticulo = m.idarticulo 
	WHERE
		m.cantidad!=0
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
			,'GDC2' --Transacción
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
		
		UPDATE vm SET
			vm.costo = ISNULL(im.costo,0)
		FROM
			ew_ven_transacciones_mov AS vm
			LEFT JOIN ew_inv_transacciones AS i ON i.idtran2=vm.idtran
			LEFT JOIN ew_inv_transacciones_mov AS im ON im.idtran2=vm.idtran AND im.idmov2=vm.idmov2 AND im.tipo=1
		WHERE
			vm.idtran=@idtran
	END
	
END
--------------------------------------------------------------------
-- Devolvemos la mercancia en la orden de Venta
--------------------------------------------------------------------
INSERT INTO ew_sys_movimientos_acumula 
	(idmov1,idmov2,campo,valor)
SELECT 
	m.idmov,m2.idmov2,'cantidad_devuelta',m.cantidad
FROM	
	ew_ven_transacciones_mov m
	LEFT JOIN ew_ven_transacciones_mov m2 ON m2.idmov=m.idmov2
	LEFT JOIN ew_articulos a ON a.idarticulo=m.idarticulo
WHERE 
	m.cantidad!=0
	AND m.idtran = @idtran

--------------------------------------------------------------------
-- Indicamos la mercancia en la factura
--------------------------------------------------------------------
INSERT INTO ew_sys_movimientos_acumula (idmov1,idmov2,campo,valor)
SELECT 
	idmov,idmov2,'cantidad_devuelta',cantidad
FROM	
	ew_ven_transacciones_mov
WHERE 
	idtran = @idtran
	AND cantidad!=0
	
--------------------------------------------------------------------
-- Aplicando el saldo en CXC
--------------------------------------------------------------------
DECLARE 
	@saldo		DECIMAL(15,2)
	,@total		DECIMAL(15,2)

SELECT 
	@idtran2=d.idtran2, @total=d.total, @saldo=ISNULL(f.saldo,0)
FROM 
	ew_ven_transacciones d 
	LEFT JOIN ew_cxc_transacciones f ON f.idtran=d.idtran2 
WHERE 
	d.idtran=@idtran


IF @saldo>0
BEGIN
	INSERT INTO ew_cxc_transacciones_mov
		(idtran, consecutivo, idtran2, fecha, tipocambio
		,importe, importe2, impuesto1, impuesto1_ret
		,impuesto2,impuesto2_ret,idu)
	SELECT
		idtran, 1, idtran2, fecha, [tipocambio]=1
		,[importe]=(CASE WHEN @total>@saldo THEN @saldo ELSE @total END)
		,[importe2]=(CASE WHEN @total>@saldo THEN @saldo ELSE @total END)
		,impuesto1,impuesto1_ret,impuesto2,impuesto2_ret
		,idu
	FROM
		ew_ven_transacciones
	WHERE
		idtran=@idtran
END
GO
