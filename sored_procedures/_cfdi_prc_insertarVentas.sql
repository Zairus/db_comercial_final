USE db_comercial_final
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 20100901
-- Update date: 20120601
-- Description:	Inserta un nuevo comprobante fiscal desde las tablas de Ventas
--              SELECT @idtran=999, @cfd_idfolio=2, @cfd_folio=2
-- =============================================
ALTER PROCEDURE [dbo].[_cfdi_prc_insertarVentas]
	 @idtran AS INT 
	,@tipo AS TINYINT
	,@cfd_idfolio AS SMALLINT
	,@cfd_folio AS INT
AS

SET NOCOUNT ON

DECLARE
	@rfc AS VARCHAR(13)
	,@razon_social AS VARCHAR(250)

DECLARE
	@metodoDePago AS VARCHAR(50)
	,@NumCtaPago AS VARCHAR(50)

------------------------------------------------------------------
-- Insertar en EW_CFD_RFC
------------------------------------------------------------------
SELECT 
	@rfc = f.rfc 
FROM 
	dbo.ew_ven_transacciones AS v 
	LEFT JOIN dbo.ew_clientes_facturacion AS f 
		ON f.idcliente = 0
		AND f.idfacturacion = 0
WHERE
	v.idtran = @idtran

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
		,f.razon_social
	FROM 
		dbo.ew_ven_transacciones AS v
		LEFT JOIN dbo.ew_clientes_facturacion AS f
			ON f.idcliente = 0 
			AND f.idfacturacion = 0 
	WHERE
		v.idtran = @idtran
END

SELECT
	@rfc = LTRIM(RTRIM(REPLACE(REPLACE(f.rfc, ' ', ''), '-', '')))
	,@razon_social = f.razon_social
FROM
	dbo.ew_ven_transacciones AS v
	LEFT JOIN dbo.ew_clientes_facturacion AS f
		ON f.idcliente = v.idcliente 
		AND f.idfacturacion = ISNULL(v.idfacturacion, 0)
WHERE
	v.idtran = @idtran

SELECT @rfc = REPLACE(REPLACE(@rfc,' ', ''), '-', '')

IF NOT EXISTS(
	SELECT cfd_nombre 
	FROM dbo.ew_cfd_rfc 
	WHERE cfd_rfc = @rfc
)
BEGIN
	INSERT INTO dbo.ew_cfd_rfc (
		cfd_rfc
		, cfd_nombre
	) 
	SELECT
		@rfc
		,f.razon_social 
	FROM 
		dbo.ew_ven_transacciones AS v 
		LEFT JOIN dbo.ew_clientes_facturacion AS f 
			ON f.idcliente = v.idcliente 
			AND f.idfacturacion = ISNULL(v.idfacturacion,0) 
	WHERE 
		v.idtran = @idtran
END
	ELSE
BEGIN
	UPDATE dbo.ew_cfd_rfc SET 
		cfd_nombre = @razon_social 
	WHERE cfd_rfc = @rfc
END

SELECT
	@metodoDePago = node.[text]
FROM
	(
		SELECT 
			UPPER(ISNULL(bf.codigo, '')) + ',' AS '*'
		FROM
			dbo.ew_ven_transacciones_pagos AS pg
			LEFT JOIN dbo.ew_ban_formas AS bf
				ON bf.idforma = pg.idforma
		WHERE
			pg.idforma > 0
			AND pg.idtran = @idtran
		FOR XML PATH('')
	) AS node(text)

IF @metodoDePago IS NULL OR @metodoDePago = ''
BEGIN
	SELECT
		@metodoDePago = ISNULL(bf.codigo, '99') 
	FROM 
		ew_cxc_transacciones AS v
		LEFT JOIN ew_ban_formas AS bf
			ON bf.idforma = v.idforma 
	WHERE v.idtran = @idtran
END
	ELSE
BEGIN
	SELECT @metodoDePago = LEFT(@metodoDePago, LEN(@metodoDePago) - 1)
END

SELECT
	@NumCtaPago = node.[text]
FROM
	(
		SELECT 
			UPPER(ISNULL(pg.forma_referencia, '')) + ',' AS '*'
		FROM
			dbo.ew_ven_transacciones_pagos pg 
		WHERE
			pg.idforma > 1
			AND pg.idtran = @idtran
		FOR XML PATH('')
	) AS node(text)

IF @NumCtaPago IS NULL OR @NumCtaPago='' OR @NumCtaPago=','
BEGIN
	SELECT @NumCtaPago = ISNULL(c.cfd_numctapago,'') 
	FROM
		ew_ven_transacciones AS v 
		LEFT JOIN ew_clientes AS c 
			ON c.idcliente = v.idcliente 
	WHERE v.idtran = @idtran
END
	ELSE
BEGIN
	SELECT @NumCtaPago = LEFT(@NumCtaPago, LEN(@NumCtaPago) - 1)
END

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
	,[comentario]
	,[cfd_metodoDePago]
	,[cfd_NumCtaPago]
	,[cfd_Moneda]
	,[cfd_TipoCambio]
)
SELECT
	 [idtran] = @idtran
	,[idsucursal] = v.idsucursal
	,[idestado] = 0
	,[idfolio] = @cfd_idfolio
	,[cfd_version] = '3.2'
	,[cfd_fecha] = v.fecha_hora
	,[cfd_folio] = @cfd_folio
	,[cfd_serie] = f.serie
	,[cfd_noCertificado] = ''
	,[cfd_formaDePago] = 'Pago en una sola exhibición'
	,[cdf_condicionesDePago] = (CASE WHEN v.credito = 0 THEN 'CONTADO' ELSE CONVERT(VARCHAR(4), v.credito_plazo) + ' DIAS DE CREDITO' END)
	,[cfd_subTotal] = v.subtotal
	,[cfd_descuento] = 0
	,[cfd_motivoDescuento] = ''
	,[cfd_total] = v.total
	,[cfd_tipoDeComprobante] = (CASE @tipo WHEN 2 THEN 'egreso' ELSE 'ingreso' END)
	,[rfc_emisor] = dbo.fn_sys_parametro('RFC')
	,[rfc_receptor] = cf.rfc
	,[comentario] = ''
	,[cfd_metodoDePago] = (CASE WHEN @metodoDePago='' THEN 'No Identificado' ELSE @metodoDePago END)
	,[cfd_NumCtaPago] = (CASE WHEN @NumCtaPago='' THEN 'No Identificado' ELSE @NumCtaPago END)
	,[cfd_Moneda] = RTRIM(bm.nombre)
	,[cfd_TipoCambio] = CONVERT(VARCHAR(12),v.tipocambio)
FROM
	dbo.ew_ven_transacciones AS v
	LEFT JOIN dbo.ew_cfd_folios AS f 
		ON f.idfolio = @cfd_idfolio
	LEFT JOIN dbo.ew_clientes_facturacion AS cf 
		ON cf.idcliente = v.idcliente 
		AND cf.idfacturacion = v.idfacturacion
	LEFT JOIN dbo.ew_ban_monedas AS bm 
		ON bm.idmoneda = v.idmoneda
WHERE
	v.idtran = @idtran

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
	dbo.ew_ven_transacciones AS v
	LEFT JOIN dbo.ew_clientes_facturacion AS f 
		ON f.idcliente = 0 
		AND f.idfacturacion = ISNULL(v.idsucursal,0)
	LEFT JOIN dbo.ew_sys_ciudades AS c 
		ON c.idciudad = f.idciudad
WHERE
	v.idtran = @idtran

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
	dbo.ew_ven_transacciones AS v
	LEFT JOIN dbo.ew_clientes_facturacion AS f 
		ON f.idcliente = v.idcliente 
		AND f.idfacturacion = ISNULL(v.idfacturacion, 0)
	LEFT JOIN dbo.ew_sys_ciudades AS c 
		ON c.idciudad = f.idciudad
WHERE
	v.idtran = @idtran

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
	vt.transaccion <> 'EFA4'
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

-----------------------------------------------------------------------
-- Insertando los conceptos en EW_CFD_COMPROBANTES_MOV
-----------------------------------------------------------------------	
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
)
SELECT
	 [idtran] = @idtran
	,[consecutivo_padre] = 0
	,[consecutivo] = m.consecutivo
	,[idarticulo] = m.idarticulo
	,[cfd_cantidad] = (CASE WHEN vt.transaccion = 'EDE1' THEN m.cantidad ELSE m.cantidad_facturada END)
	,[cfd_unidad] = um.nombre
	,[cfd_noIdentificacion] = (CASE WHEN a.series = 1 AND m.cantidad_facturada = 1 THEN m.series ELSE '' END)
	,[cfd_descripcion] = a.nombre + ' ' + CONVERT(VARCHAR(MAX), m.comentario)
	,[cfd_valorUnitario] = ROUND(
		(
			m.importe
			+ISNULL((
				SELECT SUM(vtm.importe) 
				FROM 
					ew_ven_transacciones_mov AS vtm 
				WHERE 
					vtm.no_imprimir = 1
					AND vtm.idtran = m.idtran 
					AND vtm.idr > m.idr
					AND vtm.idr < ISNULL((
						SELECT TOP 1
							vtm1.idr
						FROM
							ew_ven_transacciones_mov AS vtm1
						WHERE
							vtm1.no_imprimir = 0
							AND vtm1.idtran = m.idtran
							AND vtm1.idr > m.idr
						ORDER BY
							vtm1.idr
					), 999999999)
			), 0)
		)
		/ (
			CASE 
				WHEN vt.transaccion = 'EDE1' THEN m.cantidad 
				ELSE m.cantidad_facturada 
			END
		)
	, 4)
	,[cfd_importe] = (
		m.importe
		+ISNULL((
			SELECT SUM(vtm.importe) 
			FROM 
				ew_ven_transacciones_mov AS vtm 
			WHERE 
				vtm.no_imprimir = 1
				AND vtm.idtran = m.idtran 
				AND vtm.idr > m.idr
				AND vtm.idr < ISNULL((
					SELECT TOP 1
						vtm1.idr
					FROM
						ew_ven_transacciones_mov AS vtm1
					WHERE
						vtm1.no_imprimir = 0
						AND vtm1.idtran = m.idtran
						AND vtm1.idr > m.idr
					ORDER BY
						vtm1.idr
				), 999999999)
		), 0)
	)
FROM
	dbo.ew_ven_transacciones_mov AS m
	LEFT JOIN dbo.ew_cat_unidadesMedida AS um 
		ON um.idum = m.idum
	LEFT JOIN dbo.ew_articulos AS a 
		ON a.idarticulo = m.idarticulo
	LEFT JOIN ew_ven_transacciones AS vt 
		ON vt.idtran = m.idtran
WHERE
	m.importe <> 0
	AND m.no_imprimir = 0
	AND a.series = 0
	AND vt.transaccion <> 'EFA4'
	AND m.idtran = @idtran
ORDER BY 
	m.idr

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
	)
SELECT
	 [idtran] = @idtran
	,[consecutivo_padre] = 0
	,[consecutivo] = m.consecutivo
	,[idarticulo] = m.idarticulo
	,[cfd_cantidad] = (CASE WHEN vt.transaccion = 'EDE1' THEN m.cantidad ELSE m.cantidad_facturada END)
	,[cfd_unidad] = um.nombre
	,[cfd_noIdentificacion] = a.codigo
	,[cfd_descripcion] = a.nombre + ' ' + CONVERT(VARCHAR(MAX), m.comentario)
	,[cfd_valorUnitario] = CONVERT(DECIMAL(15,2), m.importe / (CASE WHEN vt.transaccion = 'EDE1' THEN m.cantidad ELSE m.cantidad_facturada END))
	,[cfd_importe] = CONVERT(DECIMAL(15,2), m.importe)
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
	)
SELECT
	 [idtran] = @idtran
	,[consecutivo_padre] = m.consecutivo
	,[consecutivo] = ROW_NUMBER() OVER (PARTITION BY m.consecutivo ORDER BY m.consecutivo)
	,[idarticulo] = m.idarticulo
	,[cfd_cantidad] = 1
	,[cfd_unidad] = um.nombre
	,[cfd_noIdentificacion] = s.valor
	,[cfd_descripcion] = 'No. de Serie:' + s.valor + ', ' + a.nombre
	,[cfd_valorUnitario] = CONVERT(DECIMAL(15,2), m.importe / (CASE WHEN vt.transaccion = 'EDE1' THEN m.cantidad ELSE m.cantidad_facturada END))
	,[cfd_importe] = CONVERT(DECIMAL(15,2), m.importe / (CASE WHEN vt.transaccion = 'EDE1' THEN m.cantidad ELSE m.cantidad_facturada END))
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
FROM 
	ew_cxc_transacciones_rel AS ctr
	LEFT JOIN ew_cxc_transacciones AS f
		ON f.idtran = ctr.idtran2
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = ctr.idtran
WHERE 
	ct.transaccion = 'EFA4'
	AND ctr.idtran = @idtran
	
-----------------------------------------------------------------------
-- Sellamos el comprobante
-----------------------------------------------------------------------	
EXEC dbo._cfdi_prc_sellarComprobante @idtran,''
GO
