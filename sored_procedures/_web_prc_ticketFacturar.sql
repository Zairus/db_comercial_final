USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160328
-- Description:	Facturar un ticket de venta desde portal web
-- =============================================
ALTER PROCEDURE [dbo].[_web_prc_ticketFacturar]
	@idtran AS INT
	,@rfc AS VARCHAR(14)
	,@nombre AS VARCHAR(500)
	,@calle AS VARCHAR(500)
	,@noExterior AS VARCHAR(500)
	,@noInterior AS VARCHAR(500)
	,@referencia AS VARCHAR(500)
	,@colonia AS VARCHAR(500)
	,@idciudad AS INT
	,@codigo_postal AS VARCHAR(500)
	,@correo_electronico AS VARCHAR(500)

	,@resultado_codigo AS INT OUTPUT
	,@resultado_mensaje AS VARCHAR(500) OUTPUT
	,@factura_idtran AS INT OUTPUT
AS

SET NOCOUNT ON

DECLARE
	@usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)
	,@transaccion AS VARCHAR(5) = 'EFA4'
	,@idsucursal AS INT
	,@serie AS VARCHAR(3) = 'A'
	,@foliolen AS TINYINT = 6
	,@afolio AS VARCHAR(10) = ''
	,@afecha AS VARCHAR(20) = ''
	,@idcliente AS INT
	,@folio AS VARCHAR(15)

SELECT
	@resultado_codigo = 0
	,@resultado_mensaje = 'Factura registrada con éxito.'

SELECT
	@usuario = usuario
	,@password = [password]
FROM
	evoluware_usuarios
WHERE
	idu = 1

SELECT
	@idsucursal = idsucursal
FROM
	ew_sys_transacciones
WHERE
	idtran = @idtran

EXEC _sys_prc_insertarTransaccion
	@usuario
	,@password
	,@transaccion
	,@idsucursal
	,@serie
	,''
	,@foliolen
	,@factura_idtran OUTPUT
	,@afolio
	,@afecha

IF @factura_idtran IS NULL OR @factura_idtran = 0
BEGIN
	SELECT @resultado_codigo = 1
	SELECT @resultado_mensaje = 'Ocurrió un error al intentar generar la transacción.'
	GOTO PRESENTAR_RESULTADO
END

SELECT TOP 1
	@idcliente = cf.idcliente
FROM
	ew_clientes_facturacion AS cf
WHERE
	cf.rfc = @rfc

IF @idcliente IS NULL
BEGIN
	SELECT 
		@idcliente = MAX(c.idcliente)
	FROM
		ew_clientes AS c

	SELECT @idcliente = ISNULL(@idcliente, 0) + 1

	INSERT INTO ew_clientes (
		idcliente
		,codigo
		,nombre
		,nombre_corto
		,activo
		,comentario
	)
	VALUES (
		@idcliente
		,UPPER(LTRIM(RTRIM(@rfc)))
		,@nombre
		,LEFT(@nombre, 10)
		,1
		,'Creado desde Portal Web'
	)

	INSERT INTO ew_clientes_facturacion (
		[idcliente]
		,[idfacturacion]
		,[razon_social]
		,[tipo]
		,[rfc]
		,[activo]
		,[direccion1]
		,[calle]
		,[noExterior]
		,[noInterior]
		,[referencia]
		,[colonia]
		,[idciudad]
		,[codpostal]
		,[email]
		,[comentario]
	)
	SELECT
		[idcliente] = @idcliente
		,[idfacturacion] = 0
		,[razon_social] = @nombre
		,[tipo] = 0
		,[rfc] = UPPER(LTRIM(RTRIM(@rfc)))
		,[activo] = 1
		,[direccion1] = @calle + ' ' + @noExterior
		,[calle] = @calle
		,[noExterior] = @noExterior
		,[noInterior] = @noInterior
		,[referencia] = @referencia
		,[colonia] = @colonia
		,[idciudad] = @idciudad
		,[codpostal] = @codigo_postal
		,[email] = @correo_electronico
		,[comentario] = 'Creado desde Portal Web'
END

SELECT
	@folio = folio
FROM
	ew_sys_transacciones
WHERE
	idtran = @factura_idtran

BEGIN TRY
	INSERT INTO ew_ven_transacciones (
		[idtran]
		,[idconcepto]
		,[idsucursal]
		,[idalmacen]
		,[fecha]
		,[folio]
		,[transaccion]
		,[idcliente]
		,[idfacturacion]
		,[idlista]
		,[credito]
		,[credito_plazo]
		,[idmoneda]
		,[subtotal]
		,[impuesto1]
		,[impuesto2]
		,[idu]
		,[comentario]
	)
	SELECT
		[idtran] = @factura_idtran
		,[idconcepto] = 19
		,[idsucursal] = @idsucursal
		,[idalmacen] = 1
		,[fecha] = GETDATE()
		,[folio] = @folio
		,[transaccion] = @transaccion
		,[idcliente] = @idcliente
		,[idfacturacion] = (SELECT TOP 1 cf.idfacturacion FROM ew_clientes_facturacion AS cf WHERE cf.idcliente = @idcliente)
		,[idlista] = (SELECT TOP 1 lp.idlista FROM ew_ven_listaprecios AS lp WHERE activo = 1 ORDER BY lp.idlista)
		,[credito] = 1
		,[credito_plazo] = 0
		,[idmoneda] = 0
		,[subtotal] = vt.subtotal
		,[impuesto1] = vt.impuesto1
		,[impuesto2] = vt.impuesto2
		,[idu] = 1
		,[comentario] = 'Generado desde WEB'
	FROM
		ew_ven_transacciones AS vt
	WHERE
		vt.idtran = @idtran
END TRY
BEGIN CATCH
	SELECT @resultado_codigo = 2
	SELECT @resultado_mensaje = ERROR_MESSAGE()
	GOTO PRESENTAR_RESULTADO
END CATCH

BEGIN TRY
	INSERT INTO ew_cxc_transacciones (
		[idtran]
		,[idconcepto]
		,[idsucursal]
		,[fecha]
		,[transaccion]
		,[folio]
		,[tipo]
		,[idcliente]
		,[idfacturacion]
		,[credito]
		,[credito_dias]
		,[idimpuesto1]
		,[idimpuesto1_valor]
		,[idimpuesto2]
		,[idimpuesto2_valor]
		,[subtotal]
		,[impuesto1]
		,[impuesto2]
		,[idu]
		,[comentario]
	)
	SELECT
		[idtran] = @factura_idtran
		,[idconcepto] = 19
		,[idsucursal] = @idsucursal
		,[fecha] = GETDATE()
		,[transaccion] = @transaccion
		,[folio] = @folio
		,[tipo] = 1
		,[idcliente] = @idcliente
		,[idfacturacion] = (SELECT TOP 1 cf.idfacturacion FROM ew_clientes_facturacion AS cf WHERE cf.idcliente = @idcliente)
		,[credito] = 0
		,[credito_dias] = 0
		,[idimpuesto1] = ct.idimpuesto1
		,[idimpuesto1_valor] = ct.idimpuesto1_valor
		,[idimpuesto2] = ct.idimpuesto2
		,[idimpuesto2_valor] = ct.idimpuesto2_valor
		,[subtotal] = ct.subtotal
		,[impuesto1] = ct.impuesto1
		,[impuesto2] = ct.impuesto2
		,[idu] = 1
		,[comentario] = 'Generado desde WEB'
	FROM
		ew_cxc_transacciones AS ct
	WHERE
		ct.idtran = @idtran
END TRY
BEGIN CATCH
	SELECT @resultado_codigo = 3
	SELECT @resultado_mensaje = ERROR_MESSAGE()
	GOTO PRESENTAR_RESULTADO
END CATCH

BEGIN TRY
	INSERT INTO ew_cxc_transacciones_rel (
		[idtran]
		,[idtran2]
		,[saldo]
		,[comentario]
	)
	SELECT
		[idtran] = @factura_idtran
		,[idtran2] = @idtran
		,[saldo] = ct.saldo
		,[comentario] = 'Generado desde WEB'
	FROM
		ew_cxc_transacciones AS ct
	WHERE
		ct.idtran = @idtran
END TRY
BEGIN CATCH
	SELECT @resultado_codigo = 4
	SELECT @resultado_mensaje = ERROR_MESSAGE()
	GOTO PRESENTAR_RESULTADO
END CATCH

BEGIN TRY
	INSERT INTO ew_ven_transacciones_mov (
		[idtran]
		,[consecutivo]
		,[idarticulo]
		,[idum]
		,[idalmacen]
		,[tipo]
		,[cantidad_ordenada]
		,[cantidad_facturada]
		,[series]
		,[descuento1]
		,[descuento2]
		,[descuento3]
		,[idimpuesto1]
		,[idimpuesto1_valor]
		,[idimpuesto2]
		,[idimpuesto2_valor]
		,[precio_venta]
		,[importe]
		,[impuesto1]
		,[impuesto2]
		,[comentario]
	)
	SELECT
		[idtran] = @factura_idtran
		,[consecutivo] = vtm.consecutivo
		,[idarticulo] = vtm.idarticulo
		,[idum] = vtm.idum
		,[idalmacen] = vtm.idalmacen
		,[tipo] = vtm.tipo
		,[cantidad_ordenada] = vtm.cantidad_ordenada
		,[cantidad_facturada] = vtm.cantidad_facturada
		,[series] = vtm.series
		,[descuento1] = vtm.descuento1
		,[descuento2] = vtm.descuento2
		,[descuento3] = vtm.descuento3
		,[idimpuesto1] = vtm.idimpuesto1
		,[idimpuesto1_valor] = vtm.idimpuesto1_valor
		,[idimpuesto2] = vtm.idimpuesto2
		,[idimpuesto2_valor] = vtm.idimpuesto2_valor
		,[precio_venta] = vtm.precio_venta
		,[importe] = vtm.importe
		,[impuesto1] = vtm.impuesto1
		,[impuesto2] = vtm.impuesto2
		,[comentario] = vtm.comentario
	FROM
		ew_ven_transacciones_mov AS vtm
	WHERE
		vtm.idtran = @idtran
END TRY
BEGIN CATCH
	SELECT @resultado_codigo = 5
	SELECT @resultado_mensaje = ERROR_MESSAGE()
	GOTO PRESENTAR_RESULTADO
END CATCH

BEGIN TRY
	EXEC [dbo].[_ven_prc_facturaTicketsProcesar] @idtran
END TRY
BEGIN CATCH
	SELECT @resultado_codigo = 6
	SELECT @resultado_mensaje = ERROR_MESSAGE()
	GOTO PRESENTAR_RESULTADO
END CATCH

BEGIN TRY
	EXEC _cfd_prc_timbrarComprobante @factura_idtran
	WAITFOR DELAY '00:00:02'
END TRY
BEGIN CATCH
	SELECT @resultado_codigo = 7
	SELECT @resultado_mensaje = ERROR_MESSAGE()
	GOTO PRESENTAR_RESULTADO
END CATCH

PRESENTAR_RESULTADO:
GO
