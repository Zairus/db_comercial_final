USE db_comercial_final
GO
-- SP: 	Inserta un nuevo comprobante fiscal desde las tablas de CXC
-- 		Elaborado por Laurence Saavedra
-- 		Creado en Septiembre del 2010
--		Modificado en Junio del 2012
--
--		SELECT @idtran=999, @cfd_idfolio=2, @cfd_folio=2
ALTER PROCEDURE [dbo].[_cfdi_prc_insertarCXC]
	 @idtran AS INT 
	,@tipo AS TINYINT
	,@cfd_idfolio AS SMALLINT
	,@cfd_folio AS SMALLINT
AS

SET NOCOUNT ON

DECLARE
	@rfc AS VARCHAR(13)
	,@razon_social AS VARCHAR(250)
	,@idtran2 AS INT

------------------------------------------------------------------
-- Insertar en EW_CFD_RFC
------------------------------------------------------------------
SELECT 
	@rfc = RTRIM(REPLACE(f.rfc,'-',''))
	,@razon_social = f.razon_social 
FROM 
	dbo.ew_cxc_transacciones AS v 
	LEFT JOIN dbo.ew_clientes_facturacion AS f 
		ON f.idcliente = v.idcliente 
		AND f.idfacturacion = ISNULL(v.idfacturacion, 0) 
WHERE 
	v.idtran = @idtran

SELECT @rfc = REPLACE(REPLACE(@rfc,' ',''), '-', '')

IF NOT EXISTS(SELECT cfd_nombre FROM dbo.ew_cfd_rfc WHERE cfd_rfc = @rfc)
BEGIN
	INSERT INTO dbo.ew_cfd_rfc (
		cfd_rfc
		,cfd_nombre
	) 
	SELECT 
		@rfc
		,f.razon_social 
	FROM 
		dbo.ew_cxc_transacciones AS v 
		LEFT JOIN dbo.ew_clientes_facturacion AS f 
			ON f.idcliente = v.idcliente 
			AND f.idfacturacion = ISNULL(v.idfacturacion, 0) 
	WHERE
		v.idtran = @idtran
END
	ELSE
BEGIN
	UPDATE dbo.ew_cfd_rfc SET 
		cfd_nombre = @razon_social 
	WHERE 
		cfd_rfc = @rfc
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
	,[cfd_TipoCambio])
SELECT
	 [idtran] = @idtran
	,[idsucursal] = v.idsucursal
	,[idestado] = 0
	,[idfolio] = @cfd_idfolio
	,[cfd_version] = '3.2'
	,[cfd_fecha] = v.fechahora
	,[cfd_folio] = @cfd_folio
	,[cfd_serie] = f.serie
	,[cfd_noCertificado] = ''
	,[cfd_formaDePago] = 'Pago en una sola exhibición'
	,[cdf_condicionesDePago] = 'CONTADO'
	,[cfd_subTotal] = v.subtotal
	,[cfd_descuento] = 0
	,[cfd_motivoDescuento] = ''
	,[cfd_total] = v.total
	,[cfd_tipoDeComprobante] = (CASE @tipo WHEN 2 THEN 'egreso' ELSE 'ingreso' END)
	,[rfc_emisor] = dbo.fn_sys_parametro('RFC')
	,[rfc_receptor] = cf.rfc
	,[comentario] = ''
	,[cfd_metodoDePago] = 'No Identificado'
	,[cfd_NumCtaPago] = 'No Identificado'
	,[cfd_Moneda] = RTRIM(bm.nombre)
	,[cfd_TipoCambio] = CONVERT(VARCHAR(12),v.tipocambio)
FROM
	dbo.ew_cxc_transacciones AS v
	LEFT JOIN dbo.ew_cfd_folios AS f 
		ON f.idfolio = @cfd_idfolio
	LEFT JOIN dbo.ew_clientes_facturacion AS cf 
		ON cf.idcliente = v.idcliente 
		AND cf.idfacturacion = ISNULL(v.idfacturacion, 0)
	LEFT JOIN dbo.ew_ban_monedas AS bm 
		ON bm.idmoneda = v.idmoneda
WHERE
	idtran = @idtran
	
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
	dbo.ew_cxc_transacciones AS v
	LEFT JOIN dbo.ew_clientes_facturacion AS f 
		ON f.idcliente = 0 
		AND f.idfacturacion = ISNULL(v.idsucursal, 0)
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
	dbo.ew_cxc_transacciones AS v
	LEFT JOIN dbo.ew_clientes_facturacion AS f 
		ON f.idcliente = v.idcliente 
		AND f.idfacturacion = ISNULL(v.idfacturacion,0)
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
INSERT INTO dbo.ew_cfd_comprobantes_impuesto (
	idtran
	, idtipo
	, cfd_impuesto
	, cfd_tasa
	, cfd_importe
)
SELECT 
	[idtran] = @idtran
	,[idtipo] = 1
	,[cfd_impuesto] = 'IEPS'
	,[cfd_tasa] = CONVERT(DECIMAL(12,2), (ABS(m.impuesto2 / m.subtotal) * 100))
	,[cfd_importe] = (m.impuesto2)
FROM
	dbo.ew_cxc_transacciones AS m
	LEFT JOIN dbo.ew_cat_impuestos AS i 
		ON i.idimpuesto = m.idimpuesto2
WHERE
	m.idtran = @idtran
	AND m.impuesto2 <> 0

INSERT INTO dbo.ew_cfd_comprobantes_impuesto (
	idtran
	, idtipo
	, cfd_impuesto
	, cfd_tasa
	, cfd_importe
)
SELECT 
	[idtran] = @idtran
	,[idtipo] = 1
	,[cfd_impuesto] = 'IVA'
	,[cfd_tasa] = ABS(i.valor) * 100
	,[cfd_importe] = SUM(m.impuesto1)
FROM
	dbo.ew_cxc_transacciones AS m
	LEFT JOIN dbo.ew_cat_impuestos AS i 
		ON i.idimpuesto = m.idimpuesto1
WHERE
	m.idtran = @idtran
	AND m.idimpuesto1 != 0
GROUP BY
	i.valor

INSERT INTO dbo.ew_cfd_comprobantes_impuesto (
	idtran
	, idtipo
	, cfd_impuesto
	, cfd_tasa
	, cfd_importe
)
SELECT 
	[idtran] = @idtran
	,[idtipo] = 2
	,[cfd_impuesto] = 'IVA'
	,[cfd_tasa] = ABS(i.valor) * 100
	,[cfd_importe] = SUM(m.impuesto1_ret)
FROM
	dbo.ew_cxc_transacciones AS m
	LEFT JOIN dbo.ew_cat_impuestos AS i 
		ON i.idimpuesto = m.idimpuesto1_ret
WHERE
	m.idtran = @idtran
	AND m.idimpuesto1_ret != 0
GROUP BY
	i.valor

INSERT INTO dbo.ew_cfd_comprobantes_impuesto (
	idtran
	, idtipo
	, cfd_impuesto
	, cfd_tasa
	, cfd_importe
)
SELECT 
	[idtran] = @idtran
	,[idtipo] = 2
	,[cfd_impuesto] = 'ISR'
	,[cfd_tasa] = ABS(i.valor) * 100
	,[cfd_importe] = SUM(m.impuesto2_ret)
FROM
	dbo.ew_cxc_transacciones AS m
	LEFT JOIN dbo.ew_cat_impuestos AS i	
		ON i.idimpuesto = m.idimpuesto2_ret
WHERE
	m.idtran = @idtran
	AND m.idimpuesto2_ret != 0
GROUP BY
	i.valor

-----------------------------------------------------------------------
-- Insertando los conceptos en EW_CFD_COMPROBANTES_MOV
-----------------------------------------------------------------------	
DECLARE 
	@concepto AS VARCHAR(200)

SELECT
	@concepto = ISNULL(nombre, 'Descuento')
FROM
	conceptos 
WHERE
	idconcepto = (
		SELECT idconcepto 
		FROM dbo.ew_cxc_transacciones 
		WHERE idtran = @idtran
	)

SELECT 
	@idtran2 = ISNULL(idtran2, 0) 
FROM 
	dbo.ew_cxc_transacciones 
WHERE 
	idtran = @idtran

IF @idtran2 > 0
BEGIN
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
		,[consecutivo] = 1
		,[idarticulo] = 0
		,[cantidad] = 1
		,[unidad] = 'Unidad'
		,[noIdentificacion] = ''
		,[nombre] = 'Nota de Credito por ' + @concepto + ' en el comprobante ' + m2.folio + ' del ' + CONVERT(VARCHAR(8), m2.fecha, 3)
		,[valorUnitario] = m.subtotal
		,[importe] = m.subtotal
	FROM	
		dbo.ew_cxc_transacciones AS m
		LEFT JOIN dbo.ew_sys_transacciones AS t 
			ON t.idtran = m.idtran
		LEFT JOIN dbo.ew_cxc_transacciones AS m2 
			ON m2.idtran = m.idtran2
	WHERE
		m.idtran = @idtran
END
	ELSE
BEGIN
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
		,m.consecutivo
		,[idarticulo] = 0
		,[cantidad] = 1
		,[unidad] = 'Unidad'
		,[noIdentificacion] = ''
		,[nombre] = 'Nota de Credito por ' + @concepto + ' en el comprobante ' + t.folio + ' del ' + CONVERT(VARCHAR(8), t.fecha, 3)
		,[valorUnitario] = m.importe
		,[importe] = m.importe
	FROM	
		dbo.ew_cxc_transacciones_mov AS m
		LEFT JOIN dbo.ew_cxc_transacciones AS t 
			ON t.idtran = m.idtran2
	WHERE
		m.idtran = @idtran
	ORDER BY 
		m.consecutivo
END

-----------------------------------------------------------------------
-- Sellamos el comprobante
-----------------------------------------------------------------------	
EXEC _cfdi_prc_sellarComprobante @idtran, ''
GO
