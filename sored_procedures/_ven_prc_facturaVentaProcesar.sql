USE db_comercial_final
GO
IF OBJECT_ID('_ven_prc_facturaVentaProcesar') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_prc_facturaVentaProcesar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110224
-- Description:	Procesar factura de venta
-- =============================================
CREATE PROCEDURE [dbo].[_ven_prc_facturaVentaProcesar]
	@idtran AS INT
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACION DE VARIABLES ####################################################

DECLARE
	@registros AS INT

DECLARE
	@fecha AS DATETIME
	, @tipo AS TINYINT
	, @idalmacen AS SMALLINT
	, @idconcepto AS INT
	, @idu AS SMALLINT
	, @inv_idtran AS INT

DECLARE
	@idcliente AS INT
	, @inventario_partes AS BIT
	, @inventario_partes_actualizar AS BIT
	, @mayoreo AS BIT
	, @codciudad AS VARCHAR(20)
	, @rfc AS VARCHAR(20)
	, @idfacturacion AS INT

DECLARE
	@total_detalle AS DECIMAL(18,6)
	, @total_documento AS DECIMAL(18,6)

DECLARE
	@credito AS BIT
	, @credito_limite AS DECIMAL(18,6)
	, @cliente_saldo AS DECIMAL(18,6)
	, @error_mensaje AS VARCHAR(MAX)

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

SELECT
	@fecha = vt.fecha
	, @tipo = 2
	, @idalmacen = vt.idalmacen
	, @idconcepto = 19
	, @idu = vt.idu
	, @idcliente = vt.idcliente
	, @inventario_partes = c.inventario_partes
	, @inventario_partes_actualizar = c.inventario_partes_actualizar
	, @mayoreo = c.mayoreo
	, @idfacturacion = (SELECT TOP 1 cfa.idfacturacion FROM ew_clientes_facturacion AS cfa WHERE cfa.idcliente = c.idcliente)
	, @total_documento = vt.total
	, @credito = ct.credito
	, @credito_limite = ctr.credito_limite
	, @cliente_saldo = csa.saldo
FROM
	ew_ven_transacciones AS vt
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = vt.idcliente
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = vt.idtran
	LEFT JOIN ew_clientes_terminos AS ctr
		ON ctr.idcliente = vt.idcliente
	LEFT JOIN ew_cxc_saldos_actual AS csa
		ON csa.idcliente = ct.idcliente
		AND csa.idmoneda = ct.idmoneda
WHERE
	vt.idtran = @idtran

SELECT
	@total_detalle = SUM(total)
FROM
	ew_ven_transacciones_mov
WHERE
	idtran = @idtran

IF @total_detalle <> @total_documento
BEGIN
	RAISERROR('Erorr: El total de la factura no coincide con sus partidas.', 16, 1)
	RETURN
END

IF @credito = 1 AND (@cliente_saldo > @credito_limite)
BEGIN
	RAISERROR('Error: El cliente ha exedido su límite de crédito', 16, 1)
	RETURN
END

IF EXISTS(SELECT * FROM ew_cxc_transacciones WHERE cfd_iduso = 0 AND idtran = @idtran)
BEGIN
	RAISERROR('Error: No se ha indicado uso para comprobante fiscal.', 16, 1)
	RETURN
END

-- ########################################################
-- VALIDAR REGISTROS DE VENTA

SELECT
	@registros = COUNT(*)
FROM
	ew_ven_transacciones_mov
WHERE
	idtran = @idtran

IF @registros = 0
BEGIN
	RAISERROR('Error: No se indicaron registros de venta.', 16, 1)
	RETURN
END

-- ########################################################
-- EFECTUAR SALIDA DE ALMACEN

EXEC [dbo].[_inv_prc_transaccionCrear]
	@idtran2 = @idtran
	, @fecha = @fecha
	, @tipo = @tipo
	, @idalmacen = @idalmacen
	, @idconcepto = @idconcepto
	, @idu = @idu
	, @inv_idtran = @inv_idtran OUTPUT

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
	[idtran] = @inv_idtran
	, [idmov2] = vtm.idmov
	, [consecutivo] = ROW_NUMBER() OVER (ORDER BY vtm.idr)
	, [tipo] = @tipo
	, [idalmacen] = @idalmacen
	, [idarticulo] = vtm.idarticulo
	, [series] = vtm.series
	, [lote] = ''
	, [fecha_caducidad] = NULL
	, [idum] = vtm.idum
	, [cantidad] = vtm.cantidad_facturada
	, [afectainv] = 1
	, [comentario] = vtm.comentario
FROM
	ew_ven_transacciones_mov AS vtm
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vtm.idarticulo
WHERE
	a.inventariable = 1
	AND vtm.idtran = @idtran

-- ########################################################
-- ACTUALIZAR COSTO DE VENTAS

UPDATE vtm SET
	vtm.costo = itm.costo
FROM
	ew_ven_transacciones_mov AS vtm
	LEFT JOIN ew_inv_transacciones_mov AS itm
		ON itm.idmov2 = vtm.idmov
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vtm.idarticulo
WHERE
	a.inventariable = 1
	AND vtm.idtran = @idtran

UPDATE ew_ven_transacciones SET
	costo = (
		SELECT
			SUM(vtm.costo)
		FROM
			ew_ven_transacciones_mov AS vtm
		WHERE
			vtm.idtran = @idtran
	)
WHERE
	idtran = @idtran

-- ########################################################
-- VERIFICAR MARGENES

EXEC [dbo].[_ven_prc_facturaPreciosValidar]
	@idtran = @idtran
	, @mostrar_costo = 1
	, @error_mensaje = @error_mensaje OUTPUT

IF @error_mensaje IS NOT NULL
BEGIN
	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

-- ########################################################
-- ACTUALIZAR INVENTARIO DE CLIENTE

IF @inventario_partes = 1
BEGIN
	UPDATE ci SET
		 ci.precio_especial = vtm.precio_unitario
		, ci.cantidad = (ci.cantidad + vtm.cantidad_facturada)
	FROM
		ew_ven_transacciones_mov AS vtm
		LEFT JOIN ew_ven_transacciones AS vt
			ON vt.idtran = vtm.idtran
		LEFT JOIN ew_clientes_inventario AS ci
			ON ci.idcliente = vt.idcliente
			AND ci.idarticulo = vtm.idarticulo
	WHERE
		vtm.idtran = @idtran
		AND ci.id IS NOT NULL
	
	INSERT INTO ew_clientes_inventario (
		idcliente
		, idarticulo
		, precio_especial
		, cantidad
	)
	SELECT
		vt.idcliente
		, vtm.idarticulo
		, [precio_especial] = vtm.precio_unitario
		, [cantidad] = vtm.cantidad_facturada
	FROM
		ew_ven_transacciones_mov AS vtm
		LEFT JOIN ew_ven_transacciones AS vt
			ON vt.idtran = vtm.idtran
	WHERE
		vtm.idarticulo NOT IN (
			SELECT
				ci.idarticulo
			FROM
				ew_clientes_inventario AS ci
			WHERE
				ci.idcliente = vt.idcliente
		)
		AND vtm.actualizar = 1
		AND vtm.idtran = @idtran
END

-- ########################################################
-- ALMACENAR INFROACIÓN PARA GARANTÍAS DE VENTA

INSERT INTO ew_ven_garantias (
	idtran
	, idcliente
	, codigo
	, nombre
	, direccion1
	, direccion2
	, ubicacion_instalacion
)
SELECT
	vt.idtran
	, vt.idcliente
	, c.codigo
	, c.nombre
	, ISNULL(cu.direccion1, '')
	, ISNULL(cu.direccion2, '')
	, vt.ubicacion_instalacion
FROM
	ew_ven_transacciones AS vt
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = vt.idcliente
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = vt.idtran
	LEFT JOIN ew_clientes_ubicaciones AS cu
		ON cu.idubicacion = ct.idubicacion
		AND cu.idcliente = vt.idcliente
WHERE
	vt.idtran NOT IN (
		SELECT
			vg.idtran
		FROM
			ew_ven_garantias AS vg
	)
	AND vt.idtran = @idtran

-- ########################################################
-- CFDI

SELECT
	@codciudad = cd.codciudad
	, @rfc = cf.rfc
FROM
	ew_clientes_facturacion AS cf
	LEFT JOIN ew_sys_ciudades AS cd
		ON cd.idciudad = cf.idciudad
WHERE
	idcliente = @idcliente
	AND idfacturacion = @idfacturacion

IF @codciudad = '' OR @codciudad = '0' OR @codciudad IS NULL
BEGIN
	RAISERROR('Error: Hay un error con la dirección del cliente, revisar ciudad y/o país.', 16, 1)
	RETURN
END

IF [dbo].[fn_sys_validaRFC](@rfc) = 0
BEGIN
	RAISERROR('Error: Hay un error con el RFC del cliente.', 16, 1)
	RETURN
END

-- ########################################################
-- APLICAR PAGOS EN FACTURA

EXEC [dbo].[_ven_prc_facturaPagos]
	@idtran = @idtran

-- ########################################################
-- CONTABILIZAR VENTA CON COSTO

EXEC [dbo].[_ct_prc_polizaAplicarDeConfiguracion]
	@idtran = @idtran
GO
