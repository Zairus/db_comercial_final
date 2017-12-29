USE db_comercial_final
GO
-- SP: 	Genera una cadena XML partiendo de un Comprobante Fiscal Digital
-- 		Elaborado por Laurence Saavedra
-- 		Creado en Septiembre del 2010
--		Modificado en Junio del 2012
--
--		DECLARE @com VARCHAR(MAX);EXEC dbo._cfdi_prc_generarCadenaXML2 100253,@com OUTPUT;PRINT @com
ALTER PROCEDURE [dbo].[_cfdi_prc_generarCadenaXML]
	 @idtran AS INT
	,@comprobante AS VARCHAR(MAX) OUTPUT
AS

SET NOCOUNT ON

---------------------------------------------------------------
-- El Regimen Fiscal es OBLIGATORIO
---------------------------------------------------------------
DECLARE 
	@regimen VARCHAR(500)

SELECT TOP 1 
	@regimen = ISNULL(RegimenFiscal, '') 
FROM 
	dbo.ew_cfd_parametros 	

IF @regimen = ''
BEGIN
	RAISERROR('El REGIMEN FISCAL es obligatorio para los comprobantes Fiscales v3.2', 16, 1)
	RETURN
END

DECLARE 
	 @sql AS VARCHAR(MAX)
	,@tmp AS VARCHAR(8000)
	,@rfc_emisor AS VARCHAR(13)
	,@rfc_receptor AS VARCHAR(13)
	,@resultado AS VARCHAR(MAX)
	,@qr_string AS VARCHAR(200)

SELECT 
	@rfc_emisor = rfc_emisor
	, @rfc_receptor = rfc_receptor 
FROM 
	dbo.ew_cfd_comprobantes 
WHERE 
	idtran=@idtran

---------------------------------------------------------------
-- 1) Encabezado del Documento XML
---------------------------------------------------------------
SELECT @comprobante = '<?xml version="1.0" encoding="utf-8"?>
<cfdi:Comprobante 
	xmlns:cfdi="http://www.sat.gob.mx/cfd/3"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://www.sat.gob.mx/cfd/3 http://www.sat.gob.mx/sitio_internet/cfd/3/cfdv32.xsd"
	version="3.2" '

---------------------------------------------------------------
-- 2) Atributos
---------------------------------------------------------------
SELECT TOP 1 
	@comprobante = @comprobante + 
	(CASE WHEN c.cfd_serie!='' THEN 'serie="' + c.cfd_serie + '" ' ELSE '' END) +
	'folio="' + CONVERT(VARCHAR(15),c.cfd_folio) + '" ' +
	'fecha="' + CONVERT(VARCHAR(19),c.cfd_fecha,126) + '" ' +
	'sello="" ' + --+ CONVERT(VARCHAR(10),c.cfd_folio) + '" ' +
	'formaDePago="' + c.cfd_formaDePago + '" ' +
	'noCertificado="' + c.cfd_noCertificado + '" ' +
	'certificado="" ' + 
	'condicionesDePago="' + c.cdf_condicionesDePago + '" ' +
	'subTotal="' + CONVERT(VARCHAR(15),c.cfd_subtotal) + '" ' +
	(CASE WHEN c.cfd_descuento!=0 THEN 'descuento="' + CONVERT(VARCHAR(15),c.cfd_descuento) + '" ' ELSE '' END) +
	(CASE WHEN c.cfd_motivoDescuento!='' THEN 'motivoDescuento="' + c.cfd_motivoDescuento + '" ' ELSE '' END) +
	(CASE WHEN c.cfd_TipoCambio!='' THEN 'TipoCambio="' + c.cfd_TipoCambio + '" ' ELSE '' END) +
	(CASE WHEN c.cfd_Moneda!='' THEN 'Moneda="' + c.cfd_Moneda + '" ' ELSE '' END) +
	'total="' + CONVERT(VARCHAR(15),c.cfd_total) + '" ' +
	'tipoDeComprobante="' + c.cfd_tipoDeComprobante + '" ' +
	'metodoDePago="' + (CASE WHEN c.cfd_metodoDePago='' THEN '99' ELSE c.cfd_metodoDePago END) + '" ' +
	'LugarExpedicion="' + RTRIM(ISNULL(sc.ciudad,'MEXICO') + ' ' + ISNULL(sc.estado,'')) + '" ' +
	'NumCtaPago="' + (CASE WHEN c.cfd_NumCtaPago='' THEN 'No Identificado' ELSE c.cfd_NumCtaPago END) + '" ' +
	(CASE WHEN c.idtran2!=0 THEN 'FolioFiscalOrig="' + CONVERT(VARCHAR(15),orig.cfd_folio) + '" ' ELSE '' END) +
	(CASE WHEN c.idtran2!=0 THEN 'SerieFolioFiscalOrig="' + orig.cfd_serie + '" ' ELSE '' END) +
	(CASE WHEN c.idtran2!=0 THEN 'FechaFolioFiscalOrig="' + CONVERT(VARCHAR(19),orig.cfd_fecha,126) + '" ' ELSE '' END) +
	(CASE WHEN c.idtran2!=0 THEN 'MontoFolioFiscalOrig="' + CONVERT(VARCHAR(15),orig.cfd_total) + '" ' ELSE '' END) +
	'>'
FROM
	dbo.ew_cfd_comprobantes c
	LEFT JOIN dbo.ew_sys_sucursales ss ON ss.idsucursal=c.idsucursal
	LEFT JOIN dbo.ew_sys_ciudades sc ON sc.idciudad=ss.idciudad
	LEFT JOIN dbo.ew_cfd_comprobantes orig ON orig.idtran=c.idtran2
	LEFT JOIN dbo.ew_cfd_rfc r ON r.cfd_rfc=c.rfc_emisor
WHERE
	c.idtran = @idtran

---------------------------------------------------------------
-- 3) Emisor
---------------------------------------------------------------
SELECT TOP 1 @comprobante=@comprobante + '
	<cfdi:Emisor rfc="' + c.rfc_emisor + '" ' +
	(CASE WHEN r.cfd_nombre IS NULL THEN '' ELSE 'nombre="' + dbo.fn_cfd_xmlChr(r.cfd_nombre) + '" ' END) +
	'>
		<cfdi:DomicilioFiscal ' + 
		'calle="' + cu.cfd_calle + '" ' + 
		(CASE WHEN cu.cfd_noExterior!='' THEN 'noExterior="' + cu.cfd_noexterior + '" ' ELSE '' END) +
		(CASE WHEN cu.cfd_noInterior!='' THEN 'noInterior="' + cu.cfd_noInterior + '" ' ELSE '' END) +
		(CASE WHEN cu.cfd_colonia!='' THEN 'colonia="' + dbo.fn_cfd_xmlChr(cu.cfd_colonia) + '" ' ELSE '' END) +
		(CASE WHEN cu.cfd_localidad!='' THEN 'localidad="' + dbo.fn_cfd_xmlChr(cu.cfd_localidad) + '" ' ELSE '' END) +
		(CASE WHEN cu.cfd_referencia!='' THEN 'referencia="' + dbo.fn_cfd_xmlChr(cu.cfd_referencia) + '" ' ELSE '' END) +
		(CASE WHEN cu.cfd_municipio!='' THEN 'municipio="' + dbo.fn_cfd_xmlChr(cu.cfd_municipio) + '" ' ELSE '' END) +
		'estado="' + cu.cfd_estado + '" ' + 
		'pais="' + cu.cfd_pais + '" ' + 
		'codigoPostal="' + cu.cfd_codigoPostal + '" ' + 
		'/>
		' +
		REPLACE(REPLACE(node.text,'88888','<'),'99999','/>') + '
	</cfdi:Emisor>'		
FROM
	dbo.ew_cfd_comprobantes c
	LEFT JOIN dbo.ew_cfd_rfc r ON r.cfd_rfc=c.rfc_emisor
	LEFT JOIN dbo.ew_cfd_comprobantes_ubicacion cu ON cu.idtran=c.idtran AND idtipo=1 AND ubicacion='DomicilioFiscal'
	CROSS APPLY
	(
		SELECT 
			'88888' + 'cfdi:RegimenFiscal Regimen="' + valor + '" 99999'  
		FROM 
			dbo.fn_sys_split(@regimen,',')
		FOR XML PATH('')
	) AS node(text)	
WHERE
	c.idtran=@idtran

---------------------------------------------------------------
-- 4) Receptor
---------------------------------------------------------------
SELECT TOP 1 @comprobante=@comprobante + '
	<cfdi:Receptor rfc="' + dbo.fn_cfd_xmlChr(c.rfc_receptor) + '" ' +
	(CASE WHEN r.cfd_nombre IS NULL THEN '' ELSE 'nombre="' + dbo.fn_cfd_xmlChr(r.cfd_nombre) + '" ' END) +
	'>
		<cfdi:Domicilio ' + 
		'calle="' + cu.cfd_calle + '" ' + 
		(CASE WHEN cu.cfd_noExterior!='' THEN 'noExterior="' + cu.cfd_noexterior + '" ' ELSE '' END) +
		(CASE WHEN cu.cfd_noInterior!='' THEN 'noInterior="' + cu.cfd_noInterior + '" ' ELSE '' END) +
		(CASE WHEN cu.cfd_colonia!='' THEN 'colonia="' + dbo.fn_cfd_xmlChr(cu.cfd_colonia) + '" ' ELSE '' END) +
		(CASE WHEN cu.cfd_localidad!='' THEN 'localidad="' + dbo.fn_cfd_xmlChr(cu.cfd_localidad) + '" ' ELSE '' END) +
		(CASE WHEN cu.cfd_referencia!='' THEN 'referencia="' + dbo.fn_cfd_xmlChr(cu.cfd_referencia) + '" ' ELSE '' END) +
		(CASE WHEN cu.cfd_municipio!='' THEN 'municipio="' + dbo.fn_cfd_xmlChr(cu.cfd_municipio) + '" ' ELSE '' END) +
		'estado="' + cu.cfd_estado + '" ' + 
		'pais="' + cu.cfd_pais + '" ' + 
		'codigoPostal="' + cu.cfd_codigoPostal + '" ' + 
		'/>
	</cfdi:Receptor>'
FROM
	dbo.ew_cfd_comprobantes c
	LEFT JOIN dbo.ew_cfd_rfc r ON r.cfd_rfc=c.rfc_receptor
	LEFT JOIN dbo.ew_cfd_comprobantes_ubicacion cu ON cu.idtran=c.idtran AND idtipo=2 AND ubicacion='Domicilio'
WHERE
	c.idtran=@idtran

---------------------------------------------------------------
-- 5) Conceptos
---------------------------------------------------------------
SELECT 
	@sql=g.text
FROM
	(
	SELECT 
		cfd_cantidad AS '@cantidad'
		,(CASE WHEN cfd_unidad = '' THEN NULL ELSE cfd_unidad END) AS '@unidad'
		,(CASE WHEN cfd_noIdentificacion = '' THEN NULL ELSE cfd_noIdentificacion END) AS '@noIdentificacion'
		,(CASE WHEN cfd_descripcion = '' THEN NULL ELSE dbo.fn_cfd_xmlChr(cfd_descripcion) END) AS '@descripcion'
		,cfd_valorUnitario AS '@valorUnitario'
		,cfd_importe AS '@importe'
		,(
			SELECT
				ip.aduana AS '@aduana'
				,ip.folio AS '@numero'
				,(dbo.fnRellenar(YEAR(ip.fecha), 4, '0') + '-' + dbo.fnRellenar(MONTH(ip.fecha), 2, '0') + '-' + dbo.fnRellenar(DAY(ip.fecha), 2, '0')) AS '@fecha'
			FROM
				ew_ven_transacciones_mov AS vtm
				LEFT JOIN ew_inv_transacciones_mov AS itm
					ON itm.idmov2 = vtm.idmov
				LEFT JOIN ew_inv_movimientos As im
					ON im.idmov2 = itm.idmov
				LEFT JOIN ew_inv_capas_mov AS icm
					ON icm.idinv = im.idr
				LEFT JOIN ew_inv_pedimentos AS ip
					ON ip.idpedimento = (
						SELECT TOP 1 icm_ped.idpedimento 
						FROM ew_inv_capas_mov AS icm_ped 
						WHERE 
							icm_ped.idpedimento <> 0
							AND icm_ped.idcapa = icm.idcapa
					) --icm.idpedimento
			WHERE
				vtm.idtran = m.idtran
				AND vtm.consecutivo = m.consecutivo
				AND ip.idpedimento IS NOT NULL				
			FOR XML PATH('InformacionAduanera')
		)
		,(
			SELECT 
				cfd_cantidad AS '@cantidad'
				,(CASE WHEN cfd_unidad = '' THEN NULL ELSE cfd_unidad END) AS '@unidad'
				,(CASE WHEN cfd_noIdentificacion = '' THEN NULL ELSE cfd_noIdentificacion END) AS '@noIdentificacion'
				,(CASE WHEN cfd_descripcion = '' THEN NULL ELSE cfd_descripcion END) AS '@descripcion'
				,cfd_valorUnitario AS '@valorUnitario'
				,cfd_importe AS '@importe'
			FROM	
				dbo.ew_cfd_comprobantes_mov mm
			WHERE
				mm.consecutivo_padre = m.consecutivo
				AND mm.idtran = m.idtran
			ORDER BY
				mm.consecutivo
			FOR XML PATH('Parte')
		)
	FROM	
		dbo.ew_cfd_comprobantes_mov AS m
	WHERE
		m.consecutivo_padre = 0
		AND m.idtran = @idtran
	ORDER BY
		m.consecutivo
	FOR XML PATH('Concepto'), Root('Conceptos')
	) AS g(text)

SELECT @sql = REPLACE(@sql,'&amp;','')
SELECT @sql = REPLACE(@sql,'&amp;lt;','<')
SELECT @sql = REPLACE(@sql,'&amp;gt;','>')
SELECT @sql = REPLACE(@sql,'&lt;','<')
SELECT @sql = REPLACE(@sql,'&gt;','>')
SELECT @sql = REPLACE(@sql,'<InformacionAduanera','
			<cfdi:InformacionAduanera')
SELECT @sql = REPLACE(@sql,'<Parte','
			<cfdi:Parte')
SELECT @sql = REPLACE(@sql,'</Parte>','
			</cfdi:Parte>')
SELECT @sql = REPLACE(@sql,'<InformacionAduanera2>','')
SELECT @sql = REPLACE(@sql,'</InformacionAduanera2>','</cfdi:Parte>')
SELECT @sql = REPLACE(@sql,'<Conceptos>','<cfdi:Conceptos>')
SELECT @sql = REPLACE(@sql,'<Concepto ','
		<cfdi:Concepto ')
SELECT @sql = REPLACE(@sql,'</Conceptos>','
	</cfdi:Conceptos>')		
SELECT @sql = REPLACE(@sql,'</Concepto>','
		</cfdi:Concepto>')		

SELECT 
	@comprobante = (
		@comprobante 
		+ '
' 
		+ @sql
	)

---------------------------------------------------------------
-- 6) Impuestos
---------------------------------------------------------------
SELECT
	@comprobante = (
		@comprobante + '
	<cfdi:Impuestos '
		+'totalImpuestosTrasladados="' + REPLACE(CONVERT(VARCHAR(20), CONVERT(MONEY, ISNULL((SELECT SUM(cci.cfd_importe) FROM dbo.ew_cfd_comprobantes_impuesto AS cci WHERE cci.idtipo = 1 AND cci.idtran = @idtran), 0)), 1), ',', '') + '" '
		+'totalImpuestosRetenidos="'+ REPLACE(CONVERT(VARCHAR(20), CONVERT(MONEY, ISNULL((SELECT SUM(cci.cfd_importe) FROM dbo.ew_cfd_comprobantes_impuesto AS cci WHERE cci.idtipo = 2 AND cci.idtran = @idtran), 0)), 1), ',', '') +'">'
	)
	
IF EXISTS(SELECT * FROM dbo.ew_cfd_comprobantes_impuesto WHERE idtran=@idtran AND idtipo=2)
BEGIN
	SELECT @comprobante=@comprobante + '
		<cfdi:Retenciones>'
	SELECT
		@sql=REPLACE(REPLACE(node.text,'<Retencion>','<cfdi:Retencion '),'</Retencion>',' />')
	FROM
		(
			SELECT
				'importe="' + REPLACE(CONVERT(VARCHAR(15),cfd_importe),'.00','') + '" impuesto="' + cfd_impuesto + '"' AS '*'
			FROM	
				dbo.ew_cfd_comprobantes_impuesto m1
			WHERE
				m1.idtran =@idtran
				AND m1.idtipo=1
			ORDER BY
				m1.idtipo				
			FOR XML PATH('Retencion')
		) AS node(text)
	SELECT @comprobante = @comprobante + '
			' + @sql + '
		</cfdi:Retenciones>'
END

IF EXISTS(SELECT * FROM dbo.ew_cfd_comprobantes_impuesto WHERE idtran=@idtran AND idtipo=1)
BEGIN
	SELECT @comprobante=@comprobante + '
		<cfdi:Traslados>'
	SELECT
		@sql=REPLACE(REPLACE(node.text,'<Traslado>','<cfdi:Traslado '),'</Traslado>',' />')
	FROM
		(
			SELECT
				--'importe="' + REPLACE(CONVERT(VARCHAR(15),cfd_importe),'.00','') + '" impuesto="' + cfd_impuesto + '" tasa="' + CONVERT(VARCHAR(12),cfd_tasa) +  '"'  AS '*'
				'importe="' + CONVERT(VARCHAR(15), cfd_importe) + '" impuesto="' + cfd_impuesto + '" tasa="' + CONVERT(VARCHAR(12),cfd_tasa) +  '"'  AS '*'
			FROM	
				dbo.ew_cfd_comprobantes_impuesto m1
			WHERE
				m1.idtran = @idtran
				AND m1.idtipo=1
			ORDER BY
				m1.idtipo				
			FOR XML PATH('Traslado')
	) AS node(text)
	SELECT @comprobante = @comprobante + '
			' + @sql + '
		</cfdi:Traslados>'
END
SELECT @comprobante=@comprobante + '
	</cfdi:Impuestos>'

---------------------------------------------------------------
-- 10) Pie del Documento XML
---------------------------------------------------------------	
SELECT @comprobante = @comprobante + '
	<cfdi:Complemento>
	</cfdi:Complemento>
</cfdi:Comprobante>'

--PRINT @comprobante
GO
