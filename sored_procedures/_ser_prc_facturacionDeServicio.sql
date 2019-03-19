USE db_comercial_final
GO
IF OBJECT_ID('_ser_prc_facturacionDeServicio') IS NOT NULL
BEGIN
	DROP PROCEDURE _ser_prc_facturacionDeServicio
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180601
-- Description:	Elaborar factura a partir de plan de cliente
-- =============================================
CREATE PROCEDURE [dbo].[_ser_prc_facturacionDeServicio]
	@periodo AS INT
	, @dia AS INT
	, @idcliente AS INT
	, @plan_codigo AS VARCHAR(MAX)
	, @no_orden AS VARCHAR(50)
	, @idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@usuario AS VARCHAR(20)
	, @password AS VARCHAR(20)
	, @transaccion AS VARCHAR(5) = 'EFA1'
	, @idsucursal AS INT
	, @serie AS VARCHAR(1) = 'A'
	, @foliolen AS SMALLINT = 6
	, @factura_idtran AS INT
	, @afolio AS VARCHAR(15) = ''
	, @afecha AS VARCHAR(20) = ''
	, @idalmacen AS INT
	, @fecha AS DATETIME = GETDATE()
	, @importe AS DECIMAL(18, 6)
	, @impuesto AS DECIMAL(18, 6)
	, @poliza_idtran AS INT = NULL
	, @mensaje VARCHAR(500)

SELECT
	@usuario = u.usuario
	,@password = u.[password]
FROM
	evoluware_usuarios AS u
WHERE
	u.activo = 1
	AND u.idu = @idu

IF @usuario IS NULL OR @usuario = ''
BEGIN
	RAISERROR('Error: El usuario es invalido.', 16, 1)
	RETURN
END

SELECT TOP 1
	@idsucursal = se.idsucursal3
FROM
	ew_clientes AS c
	LEFT JOIN ew_clientes_servicio_planes As csp
		ON csp.idcliente = c.idcliente
	LEFT JOIN ew_clientes_servicio_equipos As cse
		ON cse.idcliente = c.idcliente
		AND cse.plan_codigo = csp.plan_codigo
	LEFT JOIN ew_ser_equipos AS se
		ON se.idequipo = cse.idequipo
WHERE
	se.serie IS NOT NULL
	AND c.idcliente = @idcliente
	
IF @idsucursal IS NULL
BEGIN
	RAISERROR('Error: No hay planes para el cliente indicado.', 16, 1)
	RETURN
END

SELECT TOP 1 
	@idalmacen = alm.idalmacen 
FROM 
	ew_inv_almacenes AS alm 
WHERE 
	alm.tipo = 1 
	AND alm.idsucursal = @idsucursal

UPDATE ew_clientes_terminos SET
	autorizacion = 1
WHERE
	idcliente = @idcliente

SELECT @plan_codigo = REPLACE(LTRIM(RTRIM(@plan_codigo)), CHAR(9), ',')

SELECT
	[consecutivo] = ROW_NUMBER() OVER (ORDER BY csp.plan_codigo)
	, [idarticulo] = a.idarticulo
	, [idum] = a.idum_venta
	, [precio_unitario] = ISNULL(NULLIF(csp.costo_especial, 0), csp.costo)
	, [idimpuesto1] = ci.idimpuesto
	, [idimpuesto1_valor] = ci.valor
	, [precio_venta] = ISNULL(NULLIF(csp.costo_especial, 0), csp.costo)
	, [importe] = ISNULL(NULLIF(csp.costo_especial, 0), csp.costo)
	, [impuesto1] = ROUND((ISNULL(NULLIF(csp.costo_especial, 0), csp.costo) * ci.valor), 2)
	, [plan_codigo] = csp.plan_codigo
INTO #_tmp_detalle_ser
FROM
	ew_clientes AS c
	LEFT JOIN ew_articulos AS a
		ON a.codigo = dbo._sys_fnc_parametroTexto('SER_CONCEPTORENTA')
	LEFT JOIN ew_clientes_servicio_planes AS csp
			ON csp.idcliente = c.idcliente
			AND csp.plan_codigo IN (SELECT p.valor FROM [dbo].[_sys_fnc_separarMultilinea](@plan_codigo, ',') AS p)
	LEFT JOIN ew_cat_impuestos AS ci
			ON ci.idimpuesto = 1
WHERE
	c.idcliente = @idcliente

SELECT
	@importe = SUM(importe)
	, @impuesto = SUM(impuesto1)
FROM
	#_tmp_detalle_ser
	
IF EXISTS(
	SELECT *
	FROM
		ew_clientes_terminos AS ctr
	WHERE
		ctr.credito = 0
		AND ctr.idcliente = @idcliente
)
BEGIN
	SELECT 
		@mensaje = (
			'Error: '
			+ 'El cliente '
			+ c.nombre
			+ ', no tiene credito autorizado.'
		)
	FROM
		ew_clientes AS c
	WHERE
		c.idcliente = @idcliente

	RAISERROR(@mensaje, 16, 1)
	RETURN
END

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
	
IF @factura_idtran IS NOT NULL AND @factura_idtran > 0
BEGIN
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
		,[redondeo]
		,[idu]
		,[idforma]
		,[comentario]
		,[no_orden]
	)
	SELECT
		[idtran] = st.idtran
		,[idconcepto] = 19
		,[idsucursal] = @idsucursal
		,[idalmacen] = @idalmacen
		,[fecha] = st.fecha
		,[folio] = st.folio
		,[transaccion] = st.transaccion
		,[idcliente] = c.idcliente
		,[idfacturacion] = c.idfacturacion
		,[idlista] = 0
		,[credito] = ctr.credito
		,[credito_plazo] = ctr.credito_plazo
		,[idmoneda] = 0
		,[subtotal] = @importe
		,[impuesto1] = @impuesto
		,[impuesto2] = 0
		,[redondeo] = 0
		,[idu] = @idu
		,[idforma] = ISNULL((SELECT idforma FROM ew_ban_formas_aplica WHERE codigo = '99'), 0)
		,[comentario] = 'Facturacion automatica'
		,[no_orden] = @no_orden
	FROM
		ew_sys_transacciones AS st
		LEFT JOIN ew_clientes AS c
			ON c.idcliente = @idcliente
		LEFT JOIN ew_clientes_terminos AS ctr
			ON ctr.idcliente = c.idcliente
	WHERE
		st.idtran = @factura_idtran

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
		,[redondeo]
		,[idu]
		,[idmetodo]
		,[cfd_iduso]
		,[idforma]
		,[comentario]
	)
	SELECT
		[idtran] = st.idtran
		,[idconcepto] = 19
		,[idsucursal] = @idsucursal
		,[fecha] = @fecha
		,[transaccion] = st.transaccion
		,[folio] = st.folio
		,[tipo] = 1
		,[idcliente] = c.idcliente
		,[idfacturacion] = c.idfacturacion
		,[credito] = ctr.credito
		,[credito_dias] = ctr.credito_plazo
		,[idimpuesto1] = ci.idimpuesto
		,[idimpuesto1_valor] = ci.valor
		,[idimpuesto2] = 0
		,[idimpuesto2_valor] = 0
		,[subtotal] = @importe
		,[impuesto1] = @impuesto
		,[impuesto2] = 0
		,[redondeo] = 0
		,[idu] = @idu
		,[idmetodo] = 2
		,[cfd_iduso] = c.cfd_iduso
		,[idforma] = ISNULL((SELECT idforma FROM ew_ban_formas_aplica WHERE codigo = '99'), 0)
		,[comentario] = 'Facturacion automatica'
	FROM
		ew_sys_transacciones AS st
		LEFT JOIN ew_clientes AS c
			ON c.idcliente = @idcliente
		LEFT JOIN ew_clientes_terminos AS ctr
			ON ctr.idcliente = c.idcliente
		LEFT JOIN ew_cat_impuestos AS ci
			ON ci.idimpuesto = 1
	WHERE
		st.idtran = @factura_idtran
		
	INSERT INTO ew_ven_transacciones_mov (
		[idtran]
		,[idtran2]
		,[consecutivo]
		,[idarticulo]
		,[idum]
		,[idalmacen]
		,[tipo]
		,[cantidad_ordenada]
		,[cantidad_autorizada]
		,[cantidad_surtida]
		,[cantidad_facturada]
		,[cantidad]
		,[precio_unitario]
		,[idimpuesto1]
		,[idimpuesto1_valor]
		,[precio_venta]
		,[importe]
		,[impuesto1]
		,[comentario]
		,[no_orden]
	)
	SELECT
		[idtran] = st.idtran
		,[idtran2] = 0
		,[consecutivo] = tds.consecutivo
		,[idarticulo] = tds.idarticulo
		,[idum] = tds.idum
		,[idalmacen] = @idalmacen
		,[tipo] = 0
		,[cantidad_ordenada] = 1
		,[cantidad_autorizada] = 1
		,[cantidad_surtida] = 1
		,[cantidad_facturada] = 1
		,[cantidad] = 1
		,[precio_unitario] = tds.precio_venta
		,[idimpuesto1] = ci.idimpuesto
		,[idimpuesto1_valor] = ci.valor
		,[precio_venta] = tds.precio_venta
		,[importe] = tds.importe
		,[impuesto1] = tds.impuesto1
		,[comentario] = 'Facturacion automatica'
		,[no_orden] = @no_orden
	FROM
		#_tmp_detalle_ser AS tds
		LEFT JOIN ew_sys_transacciones AS st
			ON st.idtran = @factura_idtran
		LEFT JOIN ew_cat_impuestos AS ci
			ON ci.idimpuesto = 1

	INSERT INTO ew_ven_transacciones_mov_servicio (
		idtran
		, idmov
		, plan_codigo 
		, ejercicio
		, periodo
	)
	SELECT
		[idtran] = vtm.idtran
		, [idmov] = vtm.idmov
		, [plan_codigo] = tds.plan_codigo
		, [ejercicio] = YEAR(GETDATE())
		, [periodo] = @periodo
	FROM
		ew_ven_transacciones_mov AS vtm
		LEFT JOIN #_tmp_detalle_ser AS tds
			ON tds.consecutivo = vtm.consecutivo
	WHERE
		vtm.idtran = @factura_idtran
END

DROP TABLE #_tmp_detalle_ser

EXEC _cxc_prc_aplicarTransaccion @factura_idtran, @fecha, @idu

EXEC _ct_prc_polizaAplicarDeConfiguracion @factura_idtran, 'EFA6', @factura_idtran, @poliza_idtran OUTPUT, 0, @fecha

SELECT
	[factura_folio] = vt.folio
	,[facturado] = CONVERT(BIT, 1)
	,[idtran2] = vt.idtran
	,[objidtran] = vt.idtran
FROM
	ew_ven_transacciones AS vt
WHERE
	vt.idtran = @factura_idtran
GO
