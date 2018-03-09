USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20171113
-- Description:	Insertar documento de cliente para comprobante fiscal
-- =============================================
ALTER PROCEDURE [dbo].[_cfdi_prc_insertarComprobanteCXC]
	@idtran AS INT 
AS

SET NOCOUNT ON

DECLARE
	@rfc AS VARCHAR(13)
	,@razon_social AS VARCHAR(250)
	,@cfd_version AS VARCHAR(10)
	,@idfolio AS INT
	,@folio AS INT
	,@formas_pago AS VARCHAR(500) = ''

SELECT
	@idfolio = ct.cfd_idfolio
	,@folio = ct.cfd_folio
FROM
	ew_cfd_transacciones AS ct
WHERE
	ct.idtran = @idtran

SELECT 
	@rfc = f.rfc 
	,@razon_social  = f.razon_social
FROM 
	dbo.ew_cxc_transacciones AS ct
	LEFT JOIN dbo.ew_clientes_facturacion AS f 
		ON f.idcliente = ct.idcliente
		AND f.idfacturacion = ct.idfacturacion
WHERE
	ct.idtran = @idtran

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

/*
IF EXISTS (
	SELECT * 
	FROM ew_ven_transacciones_pagos 
	WHERE idtran = @idtran
)
BEGIN
	IF EXISTS (
		SELECT * 
		FROM 
			ew_ven_transacciones_pagos  AS vtp
			LEFT JOIN ew_ban_formas AS bf
				ON bf.idforma = vtp.idforma
			LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_formapago AS csf
				ON csf.c_formapago = bf.codigo
		WHERE 
			vtp.clabe_origen = ''
			AND csf.bancarizado = 1
			AND vtp.idtran = @idtran
	)
	BEGIN
		RAISERROR('Error: Se ha seleccionado una forma de pago bancarizada sin CLABE interbancaria de cliente.', 16, 1)
		RETURN
	END
END
*/

IF @formas_pago = ''
BEGIN
	SELECT @formas_pago = NULL
END

SELECT @cfd_version = dbo._sys_fnc_parametroTexto('CFDI_VERSION')

------------------------------------------------------------------
-- Insertar en EW_CFD_COMPROBANTES
------------------------------------------------------------------
INSERT INTO [dbo].[ew_cfd_comprobantes] (
	[idtran]
	,[idsucursal]
	,[idestado]
	,[idfolio]
	,[cfd_version]
	,[cfd_fecha]
	,[cfd_folio]
	,[cfd_serie]
	,[cfd_noCertificado]
	,[cfd_formaDePago]
	,[cdf_condicionesDePago]
	,[cfd_subTotal]
	,[cfd_descuento]
	,[cfd_motivoDescuento]
	,[cfd_total]
	,[cfd_tipoDeComprobante]
	,[rfc_emisor]
	,[rfc_receptor]
	,[receptor_nombre]
	,[comentario]
	,[cfd_metodoDePago]
	,[cfd_NumCtaPago]
	,[cfd_Moneda]
	,[cfd_TipoCambio]
	,[cfd_uso]
)
SELECT
	[idtran] = ct.idtran
	,[idsucursal] = ct.idsucursal
	,[idestado] = 0
	,[idfolio] = @idfolio
	,[cfd_version] = @cfd_version
	,[cfd_fecha] = ct.fecha
	,[cfd_folio] = @folio
	,[cfd_serie] = f.serie
	,[cfd_noCertificado] = cer.noCertificado
	,[cfd_formaDePago] = ISNULL((
		CASE 
			WHEN @cfd_version = '3.3' THEN ISNULL(csm.c_metodopago, 'PUE') 
			ELSE csm.descripcion 
		END
	), 'PUE')
	,[cdf_condicionesDePago] = (
		CASE WHEN ct.tipo = 1 
			THEN 
				(
					CASE 
						WHEN ABS(ct.saldo) < 0.01 THEN 'CONTADO' 
						ELSE 'CREDITO' 
					END
				)
			ELSE 
				'' 
		END
	)
	,[cfd_subTotal] = ct.subtotal
	,[cfd_descuento] = 0
	,[cfd_motivoDescuento] = ''
	,[cfd_total] = ct.total
	,[cfd_tipoDeComprobante] = (
		CASE
			WHEN ct.tipo = 1 THEN 'ingreso'
			ELSE
				CASE
					WHEN ct.transaccion = 'BDC2' THEN 'P'
					ELSE 'egreso'
				END
		END
	)
	,[rfc_emisor] = dbo.fn_sys_parametro('RFC')
	,[rfc_receptor] = @rfc
	,[receptor_nombre]=cf.razon_social
	,[comentario] = ''
	,[cfd_metodoDePago] = ISNULL(@formas_pago, ISNULL(bf.codigo, '99'))
	,[cfd_NumCtaPago] = '' --#####################
	,[cfd_Moneda] = bm.codigo
	,[cfd_TipoCambio] = ct.tipocambio
	,[cfd_uso] = ISNULL(csu.c_usocfdi, 'P01')
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
		ON bf.idforma = ct.idforma
	LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_uso AS csu
		ON csu.id = ct.cfd_iduso

	LEFT JOIN ew_clientes_facturacion cf
		ON cf.idcliente = ct.idcliente AND cf.idfacturacion=0
WHERE
	ct.idtran = @idtran
	
------------------------------------------------------------------
-- Insertar en EW_CFD_COMPROBANTES_UBICACION
------------------------------------------------------------------
INSERT INTO [dbo].[ew_cfd_comprobantes_ubicacion] (
	[idtran]
	,[idtipo]
	,[ubicacion]
	,[cfd_calle]
	,[cfd_noExterior]
	,[cfd_noInterior]
	,[cfd_colonia]
	,[cfd_localidad]
	,[cfd_referencia]
	,[cfd_municipio]
	,[cfd_estado]
	,[cfd_pais]
	,[cfd_codigoPostal]
)
SELECT
	[idtran] = @idtran
	,[idtipo] = 1
	,[ubicacion] = 'DomicilioFiscal'
	,f.calle
	,f.noExterior
	,f.noInterior
	,f.colonia
	,c.ciudad
	,f.referencia
	,c.municipio
	,c.estado
	,c.pais
	,f.codpostal
FROM
	dbo.ew_cxc_transacciones AS cxc
	LEFT JOIN dbo.ew_clientes_facturacion AS f 
		ON f.idcliente = 0 
		AND f.idfacturacion = ISNULL(cxc.idsucursal, 0)
	LEFT JOIN dbo.ew_sys_ciudades AS c 
		ON c.idciudad = f.idciudad
WHERE
	cxc.idtran = @idtran

UNION ALL

SELECT
	[idtran] = @idtran
	,[idtipo] = 2
	,[ubicacion] = 'Domicilio'
	,f.calle
	,f.noExterior
	,f.noInterior
	,f.colonia
	,c.ciudad
	,f.referencia
	,c.municipio
	,c.estado
	,c.pais
	,f.codpostal
FROM
	dbo.ew_cxc_transacciones AS cxc
	LEFT JOIN dbo.ew_clientes_facturacion AS f 
		ON f.idcliente = cxc.idcliente 
		AND f.idfacturacion = ISNULL(cxc.idfacturacion, 0)
	LEFT JOIN dbo.ew_sys_ciudades AS c 
		ON c.idciudad = f.idciudad
WHERE
	cxc.idtran = @idtran

-----------------------------------------------------------------------
-- Insertando el registro del Sello en EW_CFD_COMPROBANTES_SELLO
-----------------------------------------------------------------------	
INSERT INTO dbo.ew_cfd_comprobantes_sello
	(idtran)
VALUES
	(@idtran)

-----------------------------------------------------------------------
-- Insertando los impuestos en EW_CFD_COMPROBANTES_IMPUESTO
-----------------------------------------------------------------------
INSERT INTO ew_cfd_comprobantes_impuesto (
	idtran
	,idtipo
	,cfd_impuesto
	,cfd_tasa
	,cfd_importe
)

SELECT
	[idtran] = @idtran
	,[idtipo] = vtmi.idtipo
	,[cfd_impuesto] = vtmi.cfd_impuesto
	,[cfd_tasa] = vtmi.cfd_tasa
	,[cfd_importe] = vtmi.cfd_importe
FROM
	ew_ven_transacciones_mov_impuestos AS vtmi
	LEFT JOIN ew_ven_transacciones AS vt
		ON vt.idtran = vtmi.idtran
WHERE
	vt.transaccion NOT IN ('EFA4')
	AND vtmi.idtran = @idtran
	
INSERT INTO ew_cfd_comprobantes_impuesto (
	idtran
	,idtipo
	,cfd_impuesto
	,cfd_tasa
	,cfd_importe
)

SELECT
	[idtran] = @idtran
	,[idtipo] = vtmi.idtipo
	,[cfd_impuesto] = vtmi.cfd_impuesto
	,[cfd_tasa] = MIN(vtmi.cfd_tasa)
	,[cfd_importe] = SUM(vtmi.cfd_importe)
FROM
	ew_cxc_transacciones_rel AS ctr
	LEFT JOIN ew_ven_transacciones_mov_impuestos AS vtmi
		ON vtmi.idtran = ctr.idtran2
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = ctr.idtran
WHERE
	ct.transaccion = 'EFA4'
	AND ctr.idtran = @idtran
GROUP BY
	vtmi.idtipo
	,vtmi.cfd_impuesto

INSERT INTO ew_cfd_comprobantes_impuesto (
	idtran
	,idtipo
	,cfd_impuesto
	,cfd_tasa
	,cfd_importe
)
SELECT
	[idtran] = @idtran
	,[idtipo] = vtmi.idtipo
	,[cfd_impuesto] = vtmi.cfd_impuesto
	,[cfd_tasa] = vtmi.cfd_tasa
	,[cfd_importe] = SUM(CASE WHEN ci.idimpuesto = f.idimpuesto1 THEN ctm.impuesto1 ELSE ctm.impuesto2 END)
FROM
	ew_cxc_transacciones_mov AS ctm
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = ctm.idtran
	LEFT JOIN ew_cxc_transacciones AS f
		ON f.idtran = ctm.idtran2
	LEFT JOIN ew_ven_transacciones_mov_impuestos AS vtmi
		ON vtmi.idtran = f.idtran
	LEFT JOIN ew_cat_impuestos AS ci 
		ON ci.grupo = vtmi.cfd_impuesto
WHERE
	ct.tipo = 2
	AND ct.transaccion NOT IN ('EDE1')
	AND vtmi.idtran IS NOT NULL
	AND ctm.idtran = @idtran
GROUP BY
	vtmi.idtipo
	,vtmi.cfd_impuesto
	,vtmi.cfd_tasa
	
INSERT INTO ew_cfd_comprobantes_impuesto (
	idtran
	,idtipo
	,cfd_impuesto
	,cfd_tasa
	,cfd_importe
)
SELECT
	[idtran] = @idtran
	,[idtipo] = ci.tipo
	,[cfd_impuesto] = ci.nombre
	,[cfd_tasa] = (ci.valor * 100)
	,[cfd_importe] = ct.impuesto1
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_cat_impuestos AS ci
		ON ci.idimpuesto = ct.idimpuesto1
WHERE
	ct.tipo = 2
	AND ct.transaccion NOT IN ('EDE1')
	AND (SELECT COUNT(*) FROM ew_cxc_transacciones_mov AS ctm WHERE ctm.idtran = ct.idtran) = 0
	AND ct.idtran = @idtran

INSERT INTO ew_cfd_comprobantes_impuesto (
	idtran
	,idtipo
	,cfd_impuesto
	,cfd_tasa
	,cfd_importe
)
SELECT
	[idtran] = @idtran
	,[idtipo] = ci.tipo
	,[cfd_impuesto] = ci.nombre
	,[cfd_tasa] = (ci.valor * 100)
	,[cfd_importe] = ct.impuesto2
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_cat_impuestos AS ci
		ON ci.idimpuesto = ct.idimpuesto2
WHERE
	ct.tipo = 2
	AND ci.idimpuesto > 0
	AND ct.idtran = @idtran
	AND (SELECT COUNT(*) FROM ew_cxc_transacciones_mov AS ctm WHERE ctm.idtran = ct.idtran) = 0
	
-----------------------------------------------------------------------
-- Insertando los conceptos en EW_CFD_COMPROBANTES_MOV
-----------------------------------------------------------------------	

CREATE TABLE #_tmp_venta_detalle (
	idr INT IDENTITY
	,consecutivo INT
	,consecutivo_padre INT
	,idarticulo INT
	,cantidad DECIMAL(18,6)
	,unidad VARCHAR(100)
	,codigo VARCHAR(30)
	,descripcion VARCHAR(MAX)
	,precio_unitario DECIMAL(18,6)
	,importe DECIMAL(18,6)
	,idimpuesto1 INT
	,impuesto1 DECIMAL(18,6)
	,idimpuesto2 INT
	,impuesto2 DECIMAL(18,6)
	,idmov MONEY
) ON [PRIMARY]

INSERT INTO #_tmp_venta_detalle (
	consecutivo
	,consecutivo_padre
	,idarticulo
	,cantidad
	,unidad
	,codigo
	,descripcion
	,precio_unitario
	,importe
	,idimpuesto1
	,impuesto1
	,idimpuesto2
	,impuesto2
	,idmov
)
SELECT
	[consecutivo] = vtm.consecutivo
	,[consecutivo_padre] = 0
	,[idarticulo] = vtm.idarticulo
	,[cantidad] = (CASE WHEN vt.transaccion = 'EDE1' THEN vtm.cantidad ELSE vtm.cantidad_facturada END)
	,[unidad] = um.nombre
	,[codigo] = a.codigo
	,[descripcion] = (
		a.nombre
		+ (
			CASE
				WHEN LEN(CONVERT(VARCHAR(MAX), vtm.comentario)) > 0 THEN
					' ' + CONVERT(VARCHAR(MAX), vtm.comentario)
				ELSE ''
			END
		)
	)
	,[precio_unitario] = ROUND(
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
	, 4)
	,[importe] = (
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
	,[idimpuesto1] = vtm.idimpuesto1
	,[impuesto1] = (
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
	,[idimpuesto2] = vtm.idimpuesto2
	,[impuesto2] = (
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
	,[idmov] = vtm.idmov
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
	AND vt.transaccion NOT IN ('EFA4')
	AND vtm.idtran = @idtran

INSERT INTO #_tmp_venta_detalle (
	consecutivo
	,consecutivo_padre
	,idarticulo
	,cantidad
	,unidad
	,codigo
	,descripcion
	,precio_unitario
	,importe
	,idimpuesto1
	,impuesto1
	,idimpuesto2
	,impuesto2
	,idmov
)
SELECT
	[consecutivo] = m.consecutivo
	,[consecutivo_padre] = 0
	,[idarticulo] = m.idarticulo
	,[cantidad] = (CASE WHEN vt.transaccion = 'EDE1' THEN m.cantidad ELSE m.cantidad_facturada END)
	,[unidad] = um.nombre
	,[codigo] = a.codigo
	,[descripcion] = a.nombre
	,[precio_unitario] = (m.importe / (CASE WHEN vt.transaccion = 'EDE1' THEN m.cantidad ELSE m.cantidad_facturada END))
	,[importe] = m.importe
	,[idimpuesto1] = m.idimpuesto1
	,[impuesto1] = m.impuesto1
	,[idimpuesto2] = m.idimpuesto2
	,[impuesto2] = m.impuesto2
	,[idmov] = m.idmov
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
	AND vt.transaccion <> 'EFA4'
	AND m.idtran = @idtran
ORDER BY 
	m.consecutivo

INSERT INTO #_tmp_venta_detalle (
	consecutivo
	,consecutivo_padre
	,idarticulo
	,cantidad
	,unidad
	,codigo
	,descripcion
	,precio_unitario
	,importe
	,idimpuesto1
	,impuesto1
	,idimpuesto2
	,impuesto2
	,idmov
)
SELECT
	[consecutivo] = ROW_NUMBER() OVER (PARTITION BY m.consecutivo ORDER BY m.consecutivo)
	,[consecutivo_padre] = m.consecutivo
	,[idarticulo] = m.idarticulo
	,[cantidad] = 1
	,[unidad] = um.nombre
	,[codigo] = s.valor
	,[descripcion] = 'No. de Serie:' + s.valor + ', ' + a.nombre
	,[precio_unitario] = (m.importe / (CASE WHEN vt.transaccion = 'EDE1' THEN m.cantidad ELSE m.cantidad_facturada END))
	,[importe] = (m.importe / (CASE WHEN vt.transaccion = 'EDE1' THEN m.cantidad ELSE m.cantidad_facturada END))
	,[idimpuesto1] = m.idimpuesto1
	,[impuesto1] = m.impuesto1
	,[idimpuesto2] = m.idimpuesto2
	,[impuesto2] = m.impuesto2
	,[idmov] = m.idmov
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
	AND vt.transaccion <> 'EFA4'
	AND m.idtran = @idtran
ORDER BY 
	m.consecutivo

INSERT INTO #_tmp_venta_detalle (
	consecutivo
	,consecutivo_padre
	,idarticulo
	,cantidad
	,unidad
	,codigo
	,descripcion
	,precio_unitario
	,importe
	,idimpuesto1
	,impuesto1
	,idimpuesto2
	,impuesto2
	,idmov
)
SELECT TOP 1
	[consecutivo] = 1
	,[consecutivo_padre] = 0
	,[idarticulo] = (SELECT a.idarticulo FROM ew_articulos AS a WHERE a.codigo = dbo._sys_fnc_parametroTexto('CXC_CONCEPTOPAGO'))
	,[cfd_cantidad] = 1
	,[cfd_unidad] = 'ACT'
	,[cfd_noIdentificacion] = ''
	,[cfd_descripcion] = 'Nota de Credito por ' + ISNULL(c.nombre, 'credito') + ' en el comprobante ' + m2.folio + ' del ' + CONVERT(VARCHAR(8), m2.fecha, 3)
	,[cfd_valorUnitario] = ct.subtotal
	,[cfd_importe] = ct.subtotal

	,[idimpuesto1] = m2.idimpuesto1
	,[impuesto1] = ct.impuesto1
	,[idimpuesto2] = 11 --m2.idimpuesto2
	,[impuesto2] = ct.impuesto2
	,[idmov] = ct.idmov
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

--Detalle de venta
INSERT INTO dbo.ew_cfd_comprobantes_mov (
	 idtran
	,consecutivo_padre
	,consecutivo
	,idarticulo
	,cfd_cantidad
	,cfd_unidad
	,cfd_noIdentificacion
	,cfd_descripcion
	,cfd_valorUnitario
	,cfd_importe
	,idmov2
)
SELECT
	[idtran] = @idtran
	,[consecutivo_padre] = tvd.consecutivo_padre
	,[consecutivo] = tvd.consecutivo
	,[idarticulo] = tvd.idarticulo
	,[cfd_cantidad] = tvd.cantidad
	,[cfd_unidad] = tvd.unidad
	,[cfd_noIdentificacion] = tvd.codigo
	,[cfd_descripcion] = tvd.descripcion
	,[cfd_valorUnitario] = tvd.precio_unitario
	,[cfd_importe] = tvd.importe
	,[idmov2] = tvd.idmov
FROM
	#_tmp_venta_detalle AS tvd
ORDER BY
	tvd.idr

--Factura de tickets
INSERT INTO dbo.ew_cfd_comprobantes_mov (
	idtran
	,consecutivo_padre
	,consecutivo
	,idarticulo
	,cfd_cantidad
	,cfd_unidad
	,cfd_noIdentificacion
	,cfd_descripcion
	,cfd_valorUnitario
	,cfd_importe
	,idmov2
)
SELECT
	[idtran] = @idtran
	,[consecutivo_padre] = 0
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY ctr.idr)
	,[idarticulo] = 0
	,[cfd_cantidad] = 1
	,[cfd_unidad] = 'NA'
	,[cfd_noIdentificacion] = 'NOTAV'
	,[cfd_descripcion] = 'Nota de venta folio: ' + f.folio
	,[cfd_valorUnitario] = f.subtotal
	,[cfd_importe] = f.subtotal
	,[idmov2] = f.idmov
FROM 
	ew_cxc_transacciones_rel AS ctr
	LEFT JOIN ew_cxc_transacciones AS f
		ON f.idtran = ctr.idtran2
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = ctr.idtran
WHERE 
	ct.transaccion = 'EFA4'
	AND ctr.idtran = @idtran

--Pagos
INSERT INTO dbo.ew_cfd_comprobantes_mov (
	idtran
	,consecutivo_padre
	,consecutivo
	,idarticulo
	,cfd_cantidad
	,cfd_unidad
	,cfd_noIdentificacion
	,cfd_descripcion
	,cfd_valorUnitario
	,cfd_importe
	,idmov2
)
SELECT
	[idtran] = @idtran
	,[consecutivo_padre] = 0
	,[consecutivo] = 1
	,[idarticulo] = (SELECT a.idarticulo FROM ew_articulos AS a WHERE a.codigo = dbo._sys_fnc_parametroTexto('CXC_CONCEPTOPAGO'))
	,[cfd_cantidad] = 1
	,[cfd_unidad] = 'ACT'
	,[cfd_noIdentificacion] = dbo._sys_fnc_parametroTexto('CXC_CONCEPTOPAGO')
	,[cfd_descripcion] = 'Pago'
	,[cfd_valorUnitario] = 0
	,[cfd_importe] = 0
	,[idmov2] = ct.idmov
FROM
	ew_cxc_transacciones AS ct
WHERE
	ct.transaccion = 'BDC2'
	AND ct.idtran = @idtran
-----------------------------------------------------------------------
-- Insertando los conceptos en EW_CFD_COMPROBANTES_MOV_IMPUESTO
-----------------------------------------------------------------------	
INSERT INTO ew_cfd_comprobantes_mov_impuesto (
	idtran
	,idmov2
	,idimpuesto
	,idtasa
	,base
	,importe
)
SELECT
	[idtran] = @idtran
	,[idmov2] = tvd.idmov
	,[idimpuesto] = tvd.idimpuesto1
	,[idtasa] = 0
	,[base] = SUM(tvd.importe)
	,[importe] = SUM(tvd.impuesto1)
FROM
	#_tmp_venta_detalle AS tvd
WHERE
	tvd.consecutivo_padre = 0
	AND tvd.idimpuesto1 > 0
GROUP BY
	tvd.idmov
	,tvd.idimpuesto1
--HAVING
	--ABS(SUM(tvd.impuesto1)) > 0.0

INSERT INTO ew_cfd_comprobantes_mov_impuesto (
	idtran
	,idmov2
	,idimpuesto
	,idtasa
	,base
	,importe
)
SELECT
	[idtran] = @idtran
	,[idmov2] = tvd.idmov
	,[idimpuesto] = tvd.idimpuesto2
	,[idtasa] = 0
	,[base] = SUM(tvd.importe)
	,[importe] = SUM(tvd.impuesto2)
FROM
	#_tmp_venta_detalle AS tvd
WHERE
	tvd.consecutivo_padre = 0
GROUP BY
	tvd.idmov
	,tvd.idimpuesto2
HAVING
	ABS(SUM(tvd.impuesto2)) > 0.0

DROP TABLE #_tmp_venta_detalle

-----------------------------------------------------------------------
-- Generar XML y Sellar
-----------------------------------------------------------------------	
EXEC [dbo].[_cfdi_prc_sellarComprobante] @idtran, ''
GO
