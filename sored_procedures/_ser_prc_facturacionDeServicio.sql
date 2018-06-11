USE db_innova_datos2
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180601
-- Description:	Elaborar factura a partir de plan de cliente
-- =============================================
ALTER PROCEDURE [dbo].[_ser_prc_facturacionDeServicio]
	@periodo AS INT
	,@dia AS INT
	,@idcliente AS INT
	,@plan_codigo AS VARCHAR(10)
	,@no_orden AS VARCHAR(50)
	,@idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)
	,@transaccion AS VARCHAR(5) = 'EFA1'
	,@idsucursal AS INT
	,@serie AS VARCHAR(1) = 'A'
	,@foliolen AS SMALLINT = 6
	,@factura_idtran AS INT
	,@afolio AS VARCHAR(15) = ''
	,@afecha AS VARCHAR(20) = ''
	,@idalmacen AS INT
	,@fecha AS DATETIME = GETDATE()

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
	c.idcliente = @idcliente

SELECT TOP 1 
	@idalmacen = alm.idalmacen 
FROM 
	ew_inv_almacenes AS alm 
WHERE 
	alm.tipo = 1 
	AND alm.idsucursal = @idsucursal

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
		,[subtotal] = csp.costo
		,[impuesto1] = ROUND((csp.costo * ci.valor), 2)
		,[impuesto2] = 0
		,[redondeo] = 0
		,[idu] = @idu
		,[comentario] = 'Facturacion automatica'
		,[no_orden] = @no_orden
	FROM
		ew_sys_transacciones AS st
		LEFT JOIN ew_clientes AS c
			ON c.idcliente = @idcliente
		LEFT JOIN ew_clientes_terminos AS ctr
			ON ctr.idcliente = c.idcliente
		LEFT JOIN ew_clientes_servicio_planes As csp
			ON csp.idcliente = c.idcliente
			AND csp.plan_codigo = @plan_codigo
		LEFT JOIN ew_cat_impuestos AS ci
			ON ci.idimpuesto = 1
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
		,[subtotal] = csp.costo
		,[impuesto1] = ROUND((csp.costo * ci.valor), 2)
		,[impuesto2] = 0
		,[redondeo] = 0
		,[idu] = @idu
		,[comentario] = 'Facturacion automatica'
	FROM
		ew_sys_transacciones AS st
		LEFT JOIN ew_clientes AS c
			ON c.idcliente = @idcliente
		LEFT JOIN ew_clientes_terminos AS ctr
			ON ctr.idcliente = c.idcliente
		LEFT JOIN ew_clientes_servicio_planes As csp
			ON csp.idcliente = c.idcliente
			AND csp.plan_codigo = @plan_codigo
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
		,[consecutivo] = 1
		,[idarticulo] = a.idarticulo
		,[idum] = a.idum_venta
		,[idalmacen] = @idalmacen
		,[tipo] = 0
		,[cantidad_ordenada] = 1
		,[cantidad_autorizada] = 1
		,[cantidad_surtida] = 1
		,[cantidad_facturada] = 1
		,[cantidad] = 1
		,[precio_unitario] = csp.costo
		,[idimpuesto1] = ci.idimpuesto
		,[idimpuesto1_valor] = ci.valor
		,[precio_venta] = csp.costo
		,[importe] = csp.costo
		,[impuesto1] = ROUND((csp.costo * ci.valor), 2)
		,[comentario] = 'Facturacion automatica'
		,[no_orden] = @no_orden
	FROM
		ew_sys_transacciones AS st
		LEFT JOIN ew_clientes AS c
			ON c.idcliente = @idcliente
		LEFT JOIN ew_clientes_servicio_planes As csp
			ON csp.idcliente = c.idcliente
			AND csp.plan_codigo = @plan_codigo
		LEFT JOIN ew_cat_impuestos AS ci
			ON ci.idimpuesto = 1
		LEFT JOIN ew_articulos AS a
			ON a.codigo = dbo._sys_fnc_parametroTexto('SER_CONCEPTORENTA')
	WHERE
		st.idtran = @factura_idtran

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
		, [plan_codigo] = @plan_codigo
		, [ejercicio] = YEAR(GETDATE())
		, [periodo] = @periodo
	FROM
		ew_ven_transacciones_mov AS vtm
	WHERE
		vtm.idtran = @factura_idtran
END

EXEC _cxc_prc_aplicarTransaccion @factura_idtran, @fecha, @idu

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
