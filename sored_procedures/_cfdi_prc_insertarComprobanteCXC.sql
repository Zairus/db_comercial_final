USE db_comercial_final
GO
IF OBJECT_ID('_cfdi_prc_insertarComprobanteCXC') IS NOT NULL
BEGIN
	DROP PROCEDURE _cfdi_prc_insertarComprobanteCXC
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20171113
-- Description:	Insertar documento de cliente para comprobante fiscal
-- =============================================
CREATE PROCEDURE [dbo].[_cfdi_prc_insertarComprobanteCXC]
	@idtran AS INT 
AS

SET NOCOUNT ON

DECLARE
	@rfc AS VARCHAR(13)
	, @razon_social AS VARCHAR(250)
	, @cfd_version AS VARCHAR(10)
	, @idfolio AS INT
	, @folio AS INT
	, @formas_pago AS VARCHAR(500) = ''
	, @transaccion AS VARCHAR(5)

DECLARE
	@cliente_idfacturacion AS INT

SELECT
	@idfolio = ct.cfd_idfolio
	, @folio = ct.cfd_folio
FROM
	ew_cfd_transacciones AS ct
WHERE
	ct.idtran = @idtran

SELECT
	@cliente_idfacturacion = ISNULL((
		SELECT TOP 1
			f.idfacturacion
		FROM
			ew_cxc_transacciones_mov AS ctm
			LEFT JOIN ew_cxc_transacciones AS f
				ON f.idtran = ctm.idtran2
		WHERE
			ctm.idtran = ct.idtran
			AND ct.tipo = 2
	), ISNULL(cf.idfacturacion, 0))
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_clientes_facturacion AS cf
		ON cf.idcliente = ct.idcliente
		AND cf.idfacturacion = ct.idfacturacion
WHERE
	ct.idtran = @idtran

SELECT 
	@rfc = f.rfc 
	, @razon_social  = f.razon_social
	, @transaccion = ct.transaccion
FROM 
	dbo.ew_cxc_transacciones AS ct
	LEFT JOIN dbo.ew_clientes_facturacion AS f 
		ON f.idcliente = ct.idcliente
		AND f.idfacturacion = @cliente_idfacturacion
WHERE
	ct.idtran = @idtran

IF @transaccion LIKE 'EFA%'
BEGIN
	EXEC [dbo].[_ven_prc_facturaProcesarImpuestos] @idtran
END

IF @transaccion LIKE 'EDE%'
BEGIN
	EXEC [dbo].[_ven_prc_facturaProcesarImpuestos] @idtran
END

IF @transaccion = 'EFA4'
BEGIN
	DECLARE
		@ticket_idtran AS INT

	DECLARE cur_tickets CURSOR FOR
		SELECT
			ctr.idtran2
		FROM
			ew_cxc_transacciones_rel AS ctr
		WHERE
			ctr.idtran = @idtran

	OPEN cur_tickets

	FETCH NEXT FROM cur_tickets INTO
		@ticket_idtran

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC [dbo].[_ven_prc_facturaProcesarImpuestos] @ticket_idtran

		FETCH NEXT FROM cur_tickets INTO
			@ticket_idtran
	END

	CLOSE cur_tickets
	DEALLOCATE cur_tickets
END

SELECT @rfc = REPLACE(REPLACE(@rfc,' ',''), '-', '')

IF NOT EXISTS(
	SELECT cfd_nombre 
	FROM 
		dbo.ew_cfd_rfc 
	WHERE 
		cfd_rfc = @rfc
)
BEGIN
	INSERT INTO dbo.ew_cfd_rfc (
		cfd_rfc
		,cfd_nombre
	) 
	SELECT 
		@rfc
		,@razon_social
END
	ELSE
BEGIN
	UPDATE dbo.ew_cfd_rfc SET 
		cfd_nombre = @razon_social 
	WHERE 
		cfd_rfc = @rfc
END

SELECT TOP 1
	@formas_pago = bf.codigo
FROM
	ew_cxc_transacciones_mov AS ctm
	LEFT JOIN ew_cxc_transacciones AS p
		ON p.idtran = ctm.idtran
	LEFT JOIN ew_ban_formas AS bf
		ON bf.idforma = p.idforma
WHERE
	p.tipo = 2
	AND ctm.idtran2 = @idtran

IF @formas_pago = ''
BEGIN
	SELECT @formas_pago = NULL
END

SELECT @cfd_version = dbo._sys_fnc_parametroTexto('CFDI_VERSION')

-- ########################################################
-- Insertar en EW_CFD_COMPROBANTES

INSERT INTO [dbo].[ew_cfd_comprobantes] (
	[idtran]
	, [idsucursal]
	, [idestado]
	, [idfolio]
	, [cfd_version]
	, [cfd_fecha]
	, [cfd_folio]
	, [cfd_serie]
	, [cfd_noCertificado]
	, [cfd_formaDePago]
	, [cdf_condicionesDePago]
	, [cfd_subTotal]
	, [cfd_descuento]
	, [cfd_motivoDescuento]
	, [cfd_total]
	, [cfd_tipoDeComprobante]
	, [rfc_emisor]
	, [rfc_receptor]
	, [receptor_nombre]
	, [comentario]
	, [cfd_metodoDePago]
	, [cfd_NumCtaPago]
	, [cfd_Moneda]
	, [cfd_TipoCambio]
	, [cfd_uso]
)
SELECT
	[idtran] = ct.idtran
	, [idsucursal] = ct.idsucursal
	, [idestado] = 0
	, [idfolio] = @idfolio
	, [cfd_version] = @cfd_version
	, [cfd_fecha] = (
		CASE 
			WHEN ct.transaccion = 'BDC2' THEN ct.fechahora 
			ELSE ct.fecha 
		END
	)
	, [cfd_folio] = @folio
	, [cfd_serie] = f.serie
	, [cfd_noCertificado] = cer.noCertificado
	, [cfd_formaDePago] = ISNULL((
		CASE 
			WHEN @cfd_version = '3.3' THEN ISNULL(csm.c_metodopago, 'PUE') 
			ELSE csm.descripcion 
		END
	), 'PUE')
	, [cdf_condicionesDePago] = (
		CASE WHEN ct.tipo = 1 
			THEN 
				(
					CASE 
						WHEN ct.credito = 0 THEN 'CONTADO' --ABS(ct.saldo) < 0.01
						ELSE 'CREDITO' 
					END
				)
			ELSE 
				'' 
		END
	)
	, [cfd_subTotal] = ct.subtotal
	, [cfd_descuento] = 0
	, [cfd_motivoDescuento] = ''
	, [cfd_total] = ct.total
	, [cfd_tipoDeComprobante] = (
		CASE
			WHEN ct.tipo = 1 THEN 'I'
			ELSE
				CASE
					WHEN ct.transaccion = 'BDC2' THEN 'P'
					ELSE 'E'
				END
		END
	)
	, [rfc_emisor] = dbo.fn_sys_parametro('RFC')
	, [rfc_receptor] = @rfc
	, [receptor_nombre] = cf.razon_social
	, [comentario] = ''
	, [cfd_metodoDePago] = ISNULL(@formas_pago, ISNULL(bf.codigo, '99'))
	, [cfd_NumCtaPago] = '' --#####################
	, [cfd_Moneda] = bm.codigo
	, [cfd_TipoCambio] = ct.tipocambio
	, [cfd_uso] = ISNULL(csu.c_usocfdi, 'P01')
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_cfd_folios AS f
		ON f.idfolio = @idfolio
	LEFT JOIN ew_cfd_certificados AS cer
		ON cer.idcertificado = f.idcertificado
	LEFT JOIN ew_ban_monedas AS bm
		ON bm.idmoneda = ct.idmoneda
	LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_metodopago AS csm
		ON csm.idr = ct.idmetodo
	LEFT JOIN ew_ban_formas AS bf
		ON bf.idforma = (
			CASE
				WHEN ct.transaccion = 'EFA4' THEN
					(
						SELECT TOP 1
							vtp1.idforma
						FROM
							ew_cxc_transacciones_rel AS ctr1
							LEFT JOIN ew_ven_transacciones_pagos AS vtp1
								ON vtp1.idtran = ctr1.idtran2
						WHERE
							ctr1.idtran = ct.idtran
						ORDER BY
							vtp1.total DESC
					)
				ELSE ct.idforma
			END
		)
	LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_uso AS csu
		ON csu.id = ct.cfd_iduso

	LEFT JOIN ew_clientes_facturacion cf
		ON cf.idcliente = ct.idcliente 
		AND cf.idfacturacion = @cliente_idfacturacion
WHERE
	ct.idtran = @idtran
	

-- ########################################################
-- Insertar en EW_CFD_COMPROBANTES_UBICACION

INSERT INTO [dbo].[ew_cfd_comprobantes_ubicacion] (
	[idtran]
	, [idtipo]
	, [ubicacion]
	, [cfd_calle]
	, [cfd_noExterior]
	, [cfd_noInterior]
	, [cfd_colonia]
	, [cfd_localidad]
	, [cfd_referencia]
	, [cfd_municipio]
	, [cfd_estado]
	, [cfd_pais]
	, [cfd_codigoPostal]
)
SELECT
	[idtran] = @idtran
	, [idtipo] = 1
	, [ubicacion] = 'DomicilioFiscal'
	, f.calle
	, f.noExterior
	, f.noInterior
	, f.colonia
	, c.ciudad
	, f.referencia
	, c.municipio
	, c.estado
	, c.pais
	, f.codpostal
FROM
	dbo.ew_cxc_transacciones AS cxc
	LEFT JOIN dbo.ew_clientes_facturacion AS f 
		ON f.idcliente = 0 
		AND f.idfacturacion = ISNULL(cxc.idsucursal, 0)
	LEFT JOIN dbo.ew_sys_ciudades AS c 
		ON c.idciudad = f.idciudad
WHERE
	cxc.idtran = @idtran
	AND f.idr IS NOT NULL
	
UNION ALL

SELECT
	[idtran] = @idtran
	, [idtipo] = 2
	, [ubicacion] = 'Domicilio'
	, f.calle
	, f.noExterior
	, f.noInterior
	, f.colonia
	, c.ciudad
	, f.referencia
	, c.municipio
	, c.estado
	, c.pais
	, f.codpostal
FROM
	dbo.ew_cxc_transacciones AS cxc
	LEFT JOIN dbo.ew_clientes_facturacion AS f 
		ON f.idcliente = cxc.idcliente 
		AND f.idfacturacion = @cliente_idfacturacion
	LEFT JOIN dbo.ew_sys_ciudades AS c 
		ON c.idciudad = f.idciudad
WHERE
	cxc.idtran = @idtran

-- ########################################################
-- Insertando el registro del Sello en EW_CFD_COMPROBANTES_SELLO

INSERT INTO dbo.ew_cfd_comprobantes_sello
	(idtran)
VALUES
	(@idtran)

-- ########################################################
-- Insertando los conceptos en EW_CFD_COMPROBANTES_MOV

CREATE TABLE #_tmp_venta_detalle (
	idr INT IDENTITY
	, consecutivo INT
	, consecutivo_padre INT
	, idarticulo INT
	, cantidad DECIMAL(18,6)
	, unidad VARCHAR(100)
	, codigo VARCHAR(30)
	, descripcion VARCHAR(MAX)
	, precio_unitario DECIMAL(18,6)
	, importe DECIMAL(18,6)
	, idimpuesto1 INT
	, impuesto1 DECIMAL(18,6)
	, idimpuesto2 INT
	, impuesto2 DECIMAL(18,6)
	, idimpuesto3 INT NOT NULL DEFAULT 0
	, impuesto3 DECIMAL(18,6) NOT NULL DEFAULT 0
	, idimpuesto4 INT NOT NULL DEFAULT 0
	, impuesto4 DECIMAL(18,6) NOT NULL DEFAULT 0
	, idimpuesto1_ret INT NOT NULL DEFAULT 0
	, impuesto1_ret DECIMAL(18,6) NOT NULL DEFAULT 0
	, idimpuesto2_ret INT NOT NULL DEFAULT 0
	, impuesto2_ret DECIMAL(18,6) NOT NULL DEFAULT 0
	, idmov MONEY
) ON [PRIMARY]

-- ########################################################
-- # PREPARANDO DETALLE NORMAL DE VENTA ##

INSERT INTO #_tmp_venta_detalle (
	consecutivo
	, consecutivo_padre
	, idarticulo
	, cantidad
	, unidad
	, codigo
	, descripcion
	, precio_unitario
	, importe
	, idimpuesto1
	, impuesto1
	, idimpuesto2
	, impuesto2
	, idimpuesto1_ret
	, impuesto1_ret
	, idimpuesto2_ret
	, impuesto2_ret
	, idmov
)
SELECT
	[consecutivo] = vtm.consecutivo
	, [consecutivo_padre] = 0
	, [idarticulo] = vtm.idarticulo
	, [cantidad] = (CASE WHEN vt.transaccion = 'EDE1' THEN vtm.cantidad ELSE vtm.cantidad_facturada END)
	, [unidad] = um.nombre
	, [codigo] = a.codigo
	, [descripcion] = (
		a.nombre
		+ (
			CASE
				WHEN LEN(CONVERT(VARCHAR(MAX), vtm.comentario)) > 0 THEN
					' ' + CONVERT(VARCHAR(MAX), vtm.comentario)
				ELSE ''
			END
		)
	)
	, [precio_unitario] = ROUND(
		(
			vtm.importe
			+ISNULL((
				SELECT SUM(vtm1.importe) 
				FROM 
					ew_ven_transacciones_mov AS vtm1
				WHERE 
					vtm1.no_imprimir = 1
					AND vtm1.idtran = vtm.idtran 
					AND vtm1.idr > vtm.idr
					AND vtm1.idr < ISNULL((
						SELECT TOP 1
							vtm2.idr
						FROM
							ew_ven_transacciones_mov AS vtm2
						WHERE
							vtm2.no_imprimir = 0
							AND vtm2.idtran = vtm.idtran
							AND vtm2.idr > vtm.idr
						ORDER BY
							vtm2.idr
					), 999999999)
			), 0)
		)
		/ (
			CASE 
				WHEN vt.transaccion = 'EDE1' THEN vtm.cantidad 
				ELSE vtm.cantidad_facturada 
			END
		)
	, 6)
	, [importe] = (
		vtm.importe
		+ISNULL((
			SELECT SUM(vtm1.importe) 
			FROM 
				ew_ven_transacciones_mov AS vtm1
			WHERE 
				vtm1.no_imprimir = 1
				AND vtm1.idtran = vtm.idtran 
				AND vtm1.idr > vtm.idr
				AND vtm1.idr < ISNULL((
					SELECT TOP 1
						vtm2.idr
					FROM
						ew_ven_transacciones_mov AS vtm2
					WHERE
						vtm2.no_imprimir = 0
						AND vtm2.idtran = vtm.idtran
						AND vtm2.idr > vtm.idr
					ORDER BY
						vtm2.idr
				), 999999999)
		), 0)
	)
	, [idimpuesto1] = vtm.idimpuesto1
	, [impuesto1] = (
		vtm.impuesto1
		+ISNULL((
			SELECT SUM(vtm1.impuesto1) 
			FROM 
				ew_ven_transacciones_mov AS vtm1
			WHERE 
				vtm1.no_imprimir = 1
				AND vtm1.idtran = vtm.idtran 
				AND vtm1.idr > vtm.idr
				AND vtm1.idr < ISNULL((
					SELECT TOP 1
						vtm2.idr
					FROM
						ew_ven_transacciones_mov AS vtm2
					WHERE
						vtm2.no_imprimir = 0
						AND vtm2.idtran = vtm.idtran
						AND vtm2.idr > vtm.idr
					ORDER BY
						vtm2.idr
				), 999999999)
		), 0)
	)
	, [idimpuesto2] = vtm.idimpuesto2
	, [impuesto2] = (
		vtm.impuesto2
		+ISNULL((
			SELECT SUM(vtm1.impuesto2) 
			FROM 
				ew_ven_transacciones_mov AS vtm1
			WHERE 
				vtm1.no_imprimir = 1
				AND vtm1.idtran = vtm.idtran 
				AND vtm1.idr > vtm.idr
				AND vtm1.idr < ISNULL((
					SELECT TOP 1
						vtm2.idr
					FROM
						ew_ven_transacciones_mov AS vtm2
					WHERE
						vtm2.no_imprimir = 0
						AND vtm2.idtran = vtm.idtran
						AND vtm2.idr > vtm.idr
					ORDER BY
						vtm2.idr
				), 999999999)
		), 0)
	)
	, [idimpuesto1_ret] = vtm.idimpuesto1_ret
	, [impuesto1_ret] = (
		vtm.impuesto1_ret
		+ISNULL((
			SELECT SUM(vtm1.impuesto1_ret) 
			FROM 
				ew_ven_transacciones_mov AS vtm1
			WHERE 
				vtm1.no_imprimir = 1
				AND vtm1.idtran = vtm.idtran 
				AND vtm1.idr > vtm.idr
				AND vtm1.idr < ISNULL((
					SELECT TOP 1
						vtm2.idr
					FROM
						ew_ven_transacciones_mov AS vtm2
					WHERE
						vtm2.no_imprimir = 0
						AND vtm2.idtran = vtm.idtran
						AND vtm2.idr > vtm.idr
					ORDER BY
						vtm2.idr
				), 999999999)
		), 0)
	)
	, [idimpuesto2_ret] = vtm.idimpuesto2_ret
	, [impuesto2_ret] = (
		vtm.impuesto2_ret
		+ISNULL((
			SELECT SUM(vtm1.impuesto2_ret) 
			FROM 
				ew_ven_transacciones_mov AS vtm1
			WHERE 
				vtm1.no_imprimir = 1
				AND vtm1.idtran = vtm.idtran 
				AND vtm1.idr > vtm.idr
				AND vtm1.idr < ISNULL((
					SELECT TOP 1
						vtm2.idr
					FROM
						ew_ven_transacciones_mov AS vtm2
					WHERE
						vtm2.no_imprimir = 0
						AND vtm2.idtran = vtm.idtran
						AND vtm2.idr > vtm.idr
					ORDER BY
						vtm2.idr
				), 999999999)
		), 0)
	)
	, [idmov] = vtm.idmov
FROM
	dbo.ew_ven_transacciones_mov AS vtm
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vtm.idarticulo
	LEFT JOIN ew_ven_transacciones AS vt
		ON vt.idtran = vtm.idtran
	LEFT JOIN dbo.ew_cat_unidadesMedida AS um 
		ON um.idum = vtm.idum
WHERE
	vtm.importe <> 0
	AND vtm.no_imprimir = 0
	AND a.series = 0
	AND (
		vt.transaccion NOT IN ('EFA4')
		OR (
			vt.transaccion = 'EFA4'
			AND (
				SELECT COUNT(*) 
				FROM 
					ew_cxc_transacciones_rel AS ctr 
				WHERE 
					ctr.idtran = vt.idtran
			) = 1
		)
	)
	AND vtm.idtran = @idtran

-- ########################################################
-- # PREPARANDO AGRUPADOR DE SERIES ##

INSERT INTO #_tmp_venta_detalle (
	consecutivo
	, consecutivo_padre
	, idarticulo
	, cantidad
	, unidad
	, codigo
	, descripcion
	, precio_unitario
	, importe
	, idimpuesto1
	, impuesto1
	, idimpuesto2
	, impuesto2
	, idmov
)
SELECT
	[consecutivo] = m.consecutivo
	, [consecutivo_padre] = 0
	, [idarticulo] = m.idarticulo
	, [cantidad] = (CASE WHEN vt.transaccion = 'EDE1' THEN m.cantidad ELSE m.cantidad_facturada END)
	, [unidad] = um.nombre
	, [codigo] = a.codigo
	, [descripcion] = (
		a.nombre
		+ (
			CASE
				WHEN LEN(CONVERT(VARCHAR(MAX), m.comentario)) > 0 THEN
					' ' + CONVERT(VARCHAR(MAX), m.comentario)
				ELSE ''
			END
		)
	)
	, [precio_unitario] = (m.importe / (CASE WHEN vt.transaccion = 'EDE1' THEN m.cantidad ELSE m.cantidad_facturada END))
	, [importe] = m.importe
	, [idimpuesto1] = m.idimpuesto1
	, [impuesto1] = m.impuesto1
	, [idimpuesto2] = m.idimpuesto2
	, [impuesto2] = m.impuesto2
	, [idmov] = m.idmov
FROM
	dbo.ew_ven_transacciones_mov AS m 
	LEFT JOIN dbo.ew_cat_unidadesMedida AS um 
		ON um.idum = m.idum
	LEFT JOIN dbo.ew_articulos AS a 
		ON a.idarticulo = m.idarticulo
	LEFT JOIN dbo.ew_ven_transacciones AS vt 
		ON vt.idtran = m.idtran
WHERE
	a.series = 1
	AND m.importe <> 0
	AND vt.transaccion NOT IN ('EFA4')
	AND m.idtran = @idtran
ORDER BY 
	m.consecutivo

-- ########################################################
-- # PREPARANDO DETALLE CON SERIES ##

INSERT INTO #_tmp_venta_detalle (
	consecutivo
	, consecutivo_padre
	, idarticulo
	, cantidad
	, unidad
	, codigo
	, descripcion
	, precio_unitario
	, importe
	, idimpuesto1
	, impuesto1
	, idimpuesto2
	, impuesto2
	, idmov
)
SELECT
	[consecutivo] = ROW_NUMBER() OVER (PARTITION BY m.consecutivo ORDER BY m.consecutivo)
	, [consecutivo_padre] = m.consecutivo
	, [idarticulo] = m.idarticulo
	, [cantidad] = 1
	, [unidad] = um.nombre
	, [codigo] = s.valor
	, [descripcion] = 'No. de Serie:' + s.valor + ', ' + a.nombre
	, [precio_unitario] = (m.importe / (CASE WHEN vt.transaccion = 'EDE1' THEN m.cantidad ELSE m.cantidad_facturada END))
	, [importe] = (m.importe / (CASE WHEN vt.transaccion = 'EDE1' THEN m.cantidad ELSE m.cantidad_facturada END))
	, [idimpuesto1] = m.idimpuesto1
	, [impuesto1] = m.impuesto1
	, [idimpuesto2] = m.idimpuesto2
	, [impuesto2] = m.impuesto2
	, [idmov] = m.idmov
FROM
	dbo.ew_ven_transacciones_mov AS m 
	CROSS APPLY dbo.fn_sys_split(m.series, CHAR(9)) AS s 
	LEFT JOIN dbo.ew_cat_unidadesMedida AS um 
		ON um.idum = m.idum
	LEFT JOIN dbo.ew_articulos AS a 
		ON a.idarticulo = m.idarticulo
	LEFT JOIN dbo.ew_ven_transacciones AS vt 
		ON vt.idtran = m.idtran
WHERE
	a.series = 1
	AND m.importe <> 0
	AND vt.transaccion NOT IN ('EFA4')
	AND m.idtran = @idtran
ORDER BY 
	m.consecutivo

-- ########################################################
-- # PREPARANDO DETALLE NOTA DE CREDITO ##

INSERT INTO #_tmp_venta_detalle (
	consecutivo
	, consecutivo_padre
	, idarticulo
	, cantidad
	, unidad
	, codigo
	, descripcion
	, precio_unitario
	, importe
	, idimpuesto1
	, impuesto1
	, idimpuesto2
	, impuesto2
	, idmov
)
SELECT TOP 1
	[consecutivo] = 1
	, [consecutivo_padre] = 0
	, [idarticulo] = (SELECT a.idarticulo FROM ew_articulos AS a WHERE a.codigo = dbo._sys_fnc_parametroTexto('CXC_CONCEPTOPAGO'))
	, [cfd_cantidad] = 1
	, [cfd_unidad] = 'ACT'
	, [cfd_noIdentificacion] = ''
	, [cfd_descripcion] = 'Nota de Credito por ' + ISNULL(c.nombre, 'credito') + ' en el comprobante ' + m2.folio + ' del ' + CONVERT(VARCHAR(8), m2.fecha, 3)
	, [cfd_valorUnitario] = ct.subtotal
	, [cfd_importe] = ct.subtotal

	, [idimpuesto1] = m2.idimpuesto1
	, [impuesto1] = ct.impuesto1
	, [idimpuesto2] = 11 --m2.idimpuesto2
	, [impuesto2] = ct.impuesto2
	, [idmov] = ct.idmov
FROM	
	dbo.ew_cxc_transacciones AS ct
	LEFT JOIN dbo.ew_sys_transacciones AS t 
		ON t.idtran = ct.idtran
	LEFT JOIN dbo.ew_cxc_transacciones_mov AS ctm
		ON ctm.idtran = ct.idtran
	LEFT JOIN dbo.ew_cxc_transacciones AS m2 
		ON m2.idtran = ctm.idtran2
	LEFT JOIN conceptos As c
		ON c.idconcepto = ct.idconcepto
WHERE
	ct.transaccion = 'FDA2'
	AND ct.idtran = @idtran

-- ########################################################
-- # PREPARANDO DETALLE FACTURA GLOBAL ##

INSERT INTO #_tmp_venta_detalle (
	consecutivo
	, consecutivo_padre
	, idarticulo
	, cantidad
	, unidad
	, codigo
	, descripcion
	, precio_unitario
	, importe
	, idimpuesto1
	, impuesto1
	, idimpuesto2
	, impuesto2
	, idmov
)

SELECT
	[consecutivo] = ROW_NUMBER() OVER (ORDER BY ctr.idr)
	, [consecutivo_padre] = 0
	, [idarticulo] = (SELECT a.idarticulo FROM ew_articulos AS a WHERE a.codigo = 'EWACT')
	, [cfd_cantidad] = 1
	, [cfd_unidad] = 'ACT'
	, [cfd_noIdentificacion] = efa3.folio
	, [cfd_descripcion] = o.nombre + ' ' + efa3.folio + ', del ' + CONVERT(VARCHAR(8), efa3.fecha, 3)
	, [cfd_valorUnitario] = efa3.subtotal + efa3.redondeo
	, [cfd_importe] = efa3.subtotal + efa3.redondeo

	, [idimpuesto1] = efa4.idimpuesto1
	, [impuesto1] = efa3.impuesto1
	, [idimpuesto2] = 11
	, [impuesto2] = efa3.impuesto2
	, [idmov] = ctr.idmov
FROM
	ew_cxc_transacciones AS efa4
	LEFT JOIN ew_cxc_transacciones_rel AS ctr
		ON ctr.idtran = efa4.idtran
	LEFT JOIN ew_cxc_transacciones AS efa3
		ON efa3.idtran = ctr.idtran2
	LEFT JOIN objetos AS o
		ON o.codigo = efa3.transaccion
WHERE
	efa4.transaccion = 'EFA4'
	AND (
		SELECT COUNT(*) 
		FROM 
			ew_cxc_transacciones_rel AS ctr 
		WHERE 
			ctr.idtran = efa4.idtran
	) > 1
	AND efa4.idtran = @idtran

-- ########################################################
-- ### INSERTANDO DETALLE DE COMPROBANTE ###

INSERT INTO dbo.ew_cfd_comprobantes_mov (
	idtran
	, consecutivo_padre
	, consecutivo
	, idarticulo
	, cfd_cantidad
	, cfd_unidad
	, cfd_noIdentificacion
	, cfd_descripcion
	, cfd_valorUnitario
	, cfd_importe
	, idmov2
)
SELECT
	[idtran] = @idtran
	, [consecutivo_padre] = tvd.consecutivo_padre
	, [consecutivo] = tvd.consecutivo
	, [idarticulo] = tvd.idarticulo
	, [cfd_cantidad] = tvd.cantidad
	, [cfd_unidad] = tvd.unidad
	, [cfd_noIdentificacion] = tvd.codigo
	, [cfd_descripcion] = tvd.descripcion
	, [cfd_valorUnitario] = tvd.precio_unitario
	, [cfd_importe] = tvd.importe
	, [idmov2] = tvd.idmov
FROM
	#_tmp_venta_detalle AS tvd
ORDER BY
	tvd.idr

-- ########################################################
-- Pagos

INSERT INTO dbo.ew_cfd_comprobantes_mov (
	idtran
	, consecutivo_padre
	, consecutivo
	, idarticulo
	, cfd_cantidad
	, cfd_unidad
	, cfd_noIdentificacion
	, cfd_descripcion
	, cfd_valorUnitario
	, cfd_importe
	, idmov2
)
SELECT
	[idtran] = @idtran
	, [consecutivo_padre] = 0
	, [consecutivo] = 1
	, [idarticulo] = (
		SELECT a.idarticulo 
		FROM 
			ew_articulos AS a 
		WHERE 
			a.codigo = dbo._sys_fnc_parametroTexto('CXC_CONCEPTOPAGO')
	)
	, [cfd_cantidad] = 1
	, [cfd_unidad] = 'ACT'
	, [cfd_noIdentificacion] = dbo._sys_fnc_parametroTexto('CXC_CONCEPTOPAGO')
	, [cfd_descripcion] = 'Pago'
	, [cfd_valorUnitario] = 0
	, [cfd_importe] = 0
	, [idmov2] = ct.idmov
FROM
	ew_cxc_transacciones AS ct
WHERE
	ct.transaccion = 'BDC2'
	AND ct.idtran = @idtran

-- ########################################################
-- Insertando los conceptos en EW_CFD_COMPROBANTES_MOV_IMPUESTO

INSERT INTO ew_cfd_comprobantes_mov_impuesto (
	idtran
	, idmov2
	, idimpuesto
	, idtasa
	, base
	, importe
)
SELECT
	[idtran] = citr.idtran
	, [idmov2] = vtm.idmov
	, [idimpuesto] = cit.idimpuesto
	, [idtasa] = citr.idtasa
	, [base] = citr.base
	, [importe] = (
		citr.importe
		+ ISNULL((
			SELECT SUM(citr1.importe)
			FROM
				ew_ct_impuestos_transacciones AS citr1
				LEFT JOIN ew_ven_transacciones_mov AS vtm1
					ON vtm1.idmov = citr1.idmov
			WHERE
				vtm1.no_imprimir = 1
				AND citr1.idtran = citr.idtran
				AND vtm1.idr > vtm.idr
				AND vtm1.idr < ISNULL((
					SELECT TOP 1
						vtm2.idr
					FROM
						ew_ven_transacciones_mov AS vtm2
					WHERE
						vtm2.no_imprimir = 0
						AND vtm2.idtran = vtm.idtran
						AND vtm2.idr > vtm.idr
					ORDER BY
						vtm2.idr
				), 999999999)
		), 0)
	)
FROM
	ew_ct_impuestos_transacciones AS citr
	LEFT JOIN ew_ven_transacciones_mov AS vtm
		ON vtm.idmov = citr.idmov
	LEFT JOIN ew_cat_impuestos_tasas AS cit
		ON cit.idtasa = citr.idtasa
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = citr.idtran
WHERE
	(
		ct.transaccion NOT IN ('EFA4')
		OR (
			ct.transaccion IN ('EFA4')
			AND (
				SELECT COUNT(*) 
				FROM ew_cxc_transacciones_rel AS ctr1 
				WHERE ctr1.idtran = @idtran
			) = 1
		)
	)
	AND ISNULL(vtm.no_imprimir, 0) = 0
	AND citr.idtran = @idtran
	
INSERT INTO ew_cfd_comprobantes_mov_impuesto (
	idtran
	, idmov2
	, idimpuesto
	, idtasa
	, base
	, importe
)
SELECT
	[idtran] = ctr.idtran
	, [idmov2] = ctr.idmov
	, [idimpuesto] = cit.idimpuesto
	, [idtasa] = citr.idtasa
	, [base] = SUM(citr.base)
	, [importe] = SUM(citr.importe)
FROM
	ew_cxc_transacciones_rel AS ctr
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = ctr.idtran
	LEFT JOIN ew_ct_impuestos_transacciones AS citr
		ON citr.idtran = ctr.idtran2
	LEFT JOIN ew_cat_impuestos_tasas AS cit
		ON cit.idtasa = citr.idtasa
WHERE
	ct.transaccion IN ('EFA4')
	AND (
		SELECT COUNT(*) 
		FROM ew_cxc_transacciones_rel AS ctr1 
		WHERE ctr1.idtran = @idtran
	) > 1
	AND ctr.idtran = @idtran
GROUP BY
	ctr.idtran
	, ctr.idmov
	, cit.idimpuesto
	, citr.idtasa

INSERT INTO ew_cfd_comprobantes_mov_impuesto (
	idtran
	, idmov2
	, idimpuesto
	, idtasa
	, base
	, importe
)
SELECT
	[idtran] = @idtran
	, [idmov2] = tvd.idmov
	, [idimpuesto] = tvd.idimpuesto1
	, [idtasa] = 0
	, [base] = SUM(tvd.importe)
	, [importe] = SUM(tvd.impuesto1)
FROM
	#_tmp_venta_detalle AS tvd
WHERE
	tvd.consecutivo_padre = 0
	AND tvd.idimpuesto1 > 0
	AND (SELECT COUNT(*) FROM ew_ct_impuestos_transacciones AS citr WHERE citr.idtran = @idtran) = 0
GROUP BY
	tvd.idmov
	,tvd.idimpuesto1
HAVING
	ABS(SUM(tvd.impuesto1)) <> 0

INSERT INTO ew_cfd_comprobantes_mov_impuesto (
	idtran
	, idmov2
	, idimpuesto
	, idtasa
	, base
	, importe
)
SELECT
	[idtran] = @idtran
	, [idmov2] = tvd.idmov
	, [idimpuesto] = tvd.idimpuesto2
	, [idtasa] = 0
	, [base] = SUM(tvd.importe)
	, [importe] = SUM(tvd.impuesto2)
FROM
	#_tmp_venta_detalle AS tvd
WHERE
	tvd.consecutivo_padre = 0
	AND (SELECT COUNT(*) FROM ew_ct_impuestos_transacciones AS citr WHERE citr.idtran = @idtran) = 0
GROUP BY
	tvd.idmov
	,tvd.idimpuesto2
HAVING
	ABS(SUM(tvd.impuesto2)) > 0.0

UPDATE ccmi SET
	ccmi.idtasa = ISNULL(cit.idtasa, 0)
FROM
	ew_cfd_comprobantes_mov_impuesto AS ccmi
	LEFT JOIN ew_cat_impuestos_tasas AS cit
		ON cit.idimpuesto = ccmi.idimpuesto
		AND cit.tasa = CONVERT(DECIMAL(18,6), CONVERT(DECIMAL(18,2), (ccmi.importe / ccmi.base)))
WHERE
	ccmi.idtasa = 0
	AND ccmi.idimpuesto > 1
	AND ccmi.idtran = @idtran

DROP TABLE #_tmp_venta_detalle

-- ########################################################
-- Insertando los impuestos en EW_CFD_COMPROBANTES_IMPUESTO

INSERT INTO ew_cfd_comprobantes_impuesto (
	idtran
	, idtipo
	, cfd_impuesto
	, cfd_tasa
	, cfd_importe
)

SELECT
	[idtran] = ccmi.idtran
	, [idtipo] = ISNULL(cit.tipo, ci.tipo)
	, [cfd_impuesto] = ci.grupo
	, [cfd_tasa] = CONVERT(DECIMAL(18,6), ABS(ISNULL(cit.tasa, ci.valor) * 100))
	, [cfd_importe] = SUM(ccmi.importe)
FROM 
	ew_cfd_comprobantes_mov_impuesto AS ccmi
	LEFT JOIN ew_cat_impuestos_tasas AS cit
		ON cit.idtasa = ccmi.idtasa
	LEFT JOIN ew_cat_impuestos AS ci
		ON ci.idimpuesto = ccmi.idimpuesto
WHERE
	ci.grupo IS NOT NULL
	AND ccmi.idtran = @idtran
GROUP BY
	ccmi.idtran
	, ISNULL(cit.tipo, ci.tipo)
	, ci.grupo
	, CONVERT(DECIMAL(18,6), ABS(ISNULL(cit.tasa, ci.valor) * 100))

-- ########################################################
-- Generar XML y Sellar

EXEC [dbo].[_cfdi_prc_sellarComprobante] @idtran, ''
GO
