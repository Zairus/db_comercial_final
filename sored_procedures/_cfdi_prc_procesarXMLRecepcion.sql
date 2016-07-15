USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20141028
-- Description:	Procesar documento XML para validacion e importacion
-- =============================================
ALTER PROCEDURE [dbo].[_cfdi_prc_procesarXMLRecepcion]
	@ruta AS VARCHAR(200)
	,@presentar_resultado AS BIT = 1
AS
SET NOCOUNT ON

DECLARE
	@idcomprobante AS INT

DECLARE
	@xml AS XML
	,@hDoc AS INT
	,@SQL NVARCHAR (MAX)
	,@schema VARCHAR(MAX)

DECLARE
	@uuid AS VARCHAR(50)
	,@error_mensaje AS VARCHAR(500)

SELECT @schema = '
<cfdi:Comprobante xsi:schemaLocation="http://www.sat.gob.mx/cfd/3 http://www.sat.gob.mx/sitio_internet/cfd/3/cfdv32.xsd http://www.sat.gob.mx/TimbreFiscalDigital http://www.sat.gob.mx/sitio_internet/timbrefiscaldigital/TimbreFiscalDigital.xsd" xmlns:cfdi="http://www.sat.gob.mx/cfd/3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:tfd="http://www.sat.gob.mx/TimbreFiscalDigital" />'

SELECT @SQL = '
CREATE TABLE ##_tmp_xmlData (raw_data XML)

INSERT INTO ##_tmp_xmlData (raw_data)
SELECT raw_data = CONVERT(XML, BulkColumn) FROM OPENROWSET(BULK ''' + @ruta + ''', SINGLE_BLOB) AS x
'

EXEC (@SQL)

SELECT @xml = raw_data FROM ##_tmp_xmlData

DROP TABLE ##_tmp_xmlData

EXEC sp_xml_preparedocument @hDoc OUTPUT, @xml, @schema;

IF (SELECT COUNT(*) FROM OPENXML(@hDoc, '/cfdi:Comprobante')) = 0
BEGIN
	SELECT @error_mensaje = 'Error: No se pudo obtener informacion de este documento, favor de verificar el archivo.'
	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

IF (SELECT COUNT(*) FROM OPENXML(@hDoc, '/cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital')) = 0
BEGIN
	SELECT @error_mensaje = 'Error: El documento no contiene Timbre Fiscal.'
	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

SELECT @uuid = ISNULL(UUID, '')
FROM OPENXML(@hDoc, '/cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital')
WITH 
	(
		FechaTimbrado [varchar](200) '@FechaTimbrado',
		UUID [varchar](50) '@UUID',
		noCertificadoSAT [varchar](50) '@noCertificadoSAT',
		selloCFD [varchar](1000) '@selloCFD',
		selloSAT [varchar](1000) '@selloSAT',
		[version] [varchar](5) '@version'
	)

IF EXISTS(SELECT * FROM ew_cfd_comprobantes_recepcion WHERE Timbre_UUID = @uuid)
BEGIN
	SELECT @idcomprobante = idcomprobante FROM ew_cfd_comprobantes_recepcion

	SELECT
		[m_code] = 10
		,[mensaje] = 'ADVERTENCIA: El comprobante ya existe, UUID: ' + @uuid

	GOTO presentar

	--SELECT @error_mensaje = 'Error: El compronante con UUID:' + @uuid + ' ya existe.'
	--RAISERROR(@error_mensaje, 16, 1)
	--RETURN
END

IF LEN(@uuid) <> 36
BEGIN
	SELECT @error_mensaje = 'Error: El UUID: ' + @uuid + ', es incorrecto.'
	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

SELECT
	@idcomprobante = MAX(idcomprobante)
FROM
	ew_cfd_comprobantes_recepcion

SELECT @idcomprobante = ISNULL(@idcomprobante, 0) + 1

INSERT INTO ew_cfd_comprobantes_recepcion
	(idcomprobante)
VALUES
	(@idcomprobante)

UPDATE ccr SET
	ruta_archivo = @ruta
	,fecha = ISNULL(doc.fecha, '')
	,serie = ISNULL(doc.serie, '')
	,folio = ISNULL(doc.folio, '')
	,LugarExpedicion = ISNULL(doc.LugarExpedicion, '')
	,Moneda = ISNULL(doc.Moneda, '')
	,NumCtaPago = ISNULL(doc.NumCtaPago, '')
	,TipoCambio = ISNULL(doc.TipoCambio, 1)
	,certificado = ISNULL(doc.certificado, '')
	,condicionesDePago = ISNULL(doc.condicionesDePago, '')
	,formaDePago = ISNULL(doc.formaDePAgo, '')
	,metodoDePago = ISNULL(doc.metodoDePAgo, '')
	,noCertificado = ISNULL(doc.noCertificado, '')
	,sello = doc.sello
	,tipoDeComprobante = doc.tipoDeComprobante
	,[version] = doc.[version]
	,subTotal = doc.subTotal
	,total = doc.total
FROM
	(
		SELECT *
		FROM 
			OPENXML(@hDoc, '/cfdi:Comprobante')
				WITH 
				(
					LugarExpedicion [varchar](500) '@LugarExpedicion',
					Moneda [varchar](10) '@Moneda',
					NumCtaPago [varchar](50) '@NumCtaPago',
					TipoCambio [decimal](18,6) '@TipoCambio',
					certificado [varchar](1000) '@certificado',
					condicionesDePago [varchar](100) '@condicionesDePago',
					fecha [varchar](200) '@fecha',
					formaDePago [varchar](100) '@formaDePago',
					metodoDePago [varchar](100) '@metodoDePago',
					noCertificado [varchar](100) '@noCertificado',
					sello [varchar](1000) '@sello',
					serie [varchar](25) '@serie',
					folio [varchar](30) '@folio',
					tipoDeComprobante [varchar](50) '@tipoDeComprobante',
					[version] [varchar](5) '@version',
					subTotal [decimal](18,6) '@subTotal',
					total [decimal](18,6) '@total'
				)
	) AS doc
	LEFT JOIN ew_cfd_comprobantes_recepcion AS ccr
		ON ccr.idcomprobante = @idcomprobante

UPDATE ccr SET
	ccr.Emisor_nombre = doc.nombre
	,ccr.Emisor_rfc = doc.rfc
FROM
	(
		SELECT *
		FROM OPENXML(@hDoc, '/cfdi:Comprobante/cfdi:Emisor')
			WITH 
			(
				nombre [varchar](500) '@nombre',
				rfc [varchar](20) '@rfc'
			)
	) AS doc
	LEFT JOIN ew_cfd_comprobantes_recepcion AS ccr
		ON ccr.idcomprobante = @idcomprobante

UPDAtE ccr SET
	ccr.Emisor_calle = ISNULL(doc.calle, '')
	,ccr.Emisor_noExterior = ISNULL(doc.noExterior, '')
	,ccr.Emisor_noInterior = ISNULL(doc.noInterior, '')
	,ccr.Emisor_codigoPostal = ISNULL(doc.codigoPostal, '')
	,ccr.Emisor_colonia = ISNULL(doc.colonia, '')
	,ccr.Emisor_estado = ISNULL(doc.estado, '')
	,ccr.Emisor_localidad = ISNULL(doc.localidad, '')
	,ccr.Emisor_municipio = ISNULL(doc.municipio, '')
	,ccr.Emisor_pais = ISNULL(doc.pais, '')
FROM
	(
		SELECT *
		FROM OPENXML(@hDoc, '/cfdi:Comprobante/cfdi:Emisor/cfdi:DomicilioFiscal')
		WITH 
			(
				calle [varchar](200) '@calle',
				noExterior [varchar](20) '@noExterior',
				noInterior [varchar](20) '@noInterior',
				codigoPostal [varchar](20) '@codigoPostal',
				colonia [varchar](200) '@colonia',
				estado [varchar](200) '@estado',
				localidad [varchar](200) '@localidad',
				municipio [varchar](200) '@municipio',
				pais [varchar](200) '@pais'
			)
	) AS doc
	LEFT JOIN ew_cfd_comprobantes_recepcion AS ccr
		ON ccr.idcomprobante = @idcomprobante

UPDATE ccr SET
	ccr.regimen = ISNULL(doc.Regimen, '')
FROM
	(
		SELECT *
		FROM OPENXML(@hDoc, '/cfdi:Comprobante/cfdi:Emisor/cfdi:RegimenFiscal')
		WITH 
			(
				Regimen [varchar](200) '@Regimen'
			)
	) AS doc
	LEFT JOIN ew_cfd_comprobantes_recepcion AS ccr
		ON ccr.idcomprobante = @idcomprobante

UPDATE ccr SET
	ccr.Receptor_nombre = ISNULL(doc.nombre, '')
	,ccr.Receptor_rfc = ISNULL(doc.rfc, '')
FROM
	(
		SELECT *
		FROM OPENXML(@hDoc, '/cfdi:Comprobante/cfdi:Receptor')
		WITH 
		(
			nombre [varchar](200) '@nombre',
			rfc [varchar](20) '@rfc'
		)
	) AS doc
	LEFT JOIN ew_cfd_comprobantes_recepcion AS ccr
		ON ccr.idcomprobante = @idcomprobante

UPDATE ccr SET
	ccr.Receptor_calle = ISNULL(doc.calle, '')
	,ccr.Receptor_noExterior = ISNULL(doc.noExterior, '')
	,ccr.Receptor_codigoPostal = ISNULL(doc.codigoPostal, '')
	,ccr.Receptor_colonia = ISNULL(doc.colonia, '')
	,ccr.Receptor_estado = ISNULL(doc.estado, '')
	,ccr.Receptor_localidad = ISNULL(doc.localidad, '')
	,ccr.Receptor_pais = ISNULL(doc.pais, '')
FROM
	(
		SELECT *
		FROM OPENXML(@hDoc, '/cfdi:Comprobante/cfdi:Receptor/cfdi:Domicilio')
		WITH 
			(
				calle [varchar](200) '@calle',
				noExterior [varchar](20) '@noExterior',
				noInterior [varchar](20) '@noInterior',
				codigoPostal [varchar](20) '@codigoPostal',
				colonia [varchar](200) '@colonia',
				estado [varchar](200) '@estado',
				localidad [varchar](200) '@localidad',
				pais [varchar](100) '@pais'
			)
	) AS doc
	LEFT JOIN ew_cfd_comprobantes_recepcion AS ccr
		ON ccr.idcomprobante = @idcomprobante

INSERT INTO ew_cfd_comprobantes_recepcion_mov (
	idcomprobante
	,cantidad
	,noIdentificacion
	,descripcion
	,importe
	,unidad
	,valorUnitario
)

SELECT 
	[idcomprobante] = @idcomprobante
	,cantidad = ISNULL(doc.cantidad, 0)
	,noIdentificacion = ISNULL(doc.noIdentificacion, '')
	,descripcion = ISNULL(doc.descripcion, '')
	,importe = ISNULL(doc.importe, 0)
	,unidad = ISNULL(doc.unidad, '')
	,valorUnitario = ISNULL(doc.valorUnitario, 0)
FROM
	(
		SELECT *
		FROM OPENXML(@hDoc, '/cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto')
		WITH 
			(
				cantidad [decimal](18,6) '@cantidad',
				noIdentificacion [varchar](200) '@noIdentificacion',
				descripcion [varchar](200) '@descripcion',
				importe [decimal](18,6) '@importe',
				unidad [varchar](50) '@unidad',
				valorUnitario [decimal](18,6) '@valorUnitario'
			)
	) AS doc

INSERT INTO ew_cfd_comprobantes_recepcion_impuestos (
	idcomprobante
	,tipo
	,importe
	,impuesto
	,tasa
)

SELECT
	[idcomprobante] = @idcomprobante
	,[tipo] = 0
	,doc.importe
	,doc.impuesto
	,doc.tasa
FROM
	(
		SELECT *
		FROM OPENXML(@hDoc, '/cfdi:Comprobante/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado')
		WITH 
			(
				importe [decimal](18,6) '@importe',
				impuesto [varchar](50) '@impuesto',
				tasa [decimal](18,6) '@tasa'
			)
	) AS doc

INSERT INTO ew_cfd_comprobantes_recepcion_impuestos (
	idcomprobante
	,tipo
	,importe
	,impuesto
	,tasa
)

SELECT
	[idcomprobante] = @idcomprobante
	,[tipo] = 1
	,doc.importe
	,doc.impuesto
	,doc.tasa
FROM
	(
		SELECT *
		FROM OPENXML(@hDoc, '/cfdi:Comprobante/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion')
		WITH 
			(
				importe [decimal](18,6) '@importe',
				impuesto [varchar](50) '@impuesto',
				tasa [decimal](18,6) '@tasa'
			)
	) AS doc

UPDATE ccr SET
	ccr.Timbre_FechaTimbrado = ISNULL(doc.FechaTimbrado, '')
	,ccr.Timbre_UUID = ISNULL(doc.UUID, '')
	,ccr.Timbre_noCertificadoSAT = ISNULL(doc.noCertificadoSAT, '')
	,ccr.Timbre_selloCFD = ISNULL(doc.selloCFD, '')
	,ccr.Timbre_selloSAT = ISNULL(doc.selloSAT, '')
	,ccr.Timbre_version = ISNULL(doc.[version], '')
FROM
	(
		SELECT *
		FROM OPENXML(@hDoc, '/cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital')
		WITH 
			(
				FechaTimbrado [varchar](200) '@FechaTimbrado',
				UUID [varchar](50) '@UUID',
				noCertificadoSAT [varchar](50) '@noCertificadoSAT',
				selloCFD [varchar](1000) '@selloCFD',
				selloSAT [varchar](1000) '@selloSAT',
				[version] [varchar](5) '@version'
			)
	) AS doc
	LEFT JOIN ew_cfd_comprobantes_recepcion AS ccr
		ON ccr.idcomprobante = @idcomprobante

EXEC sp_xml_removedocument @hDoc

SELECT
		[m_code] = 0
		,[mensaje] = 'Se importó documento, UUID: ' + @uuid

presentar:

IF @presentar_resultado = 1
BEGIN
	SELECT * FROM ew_cfd_comprobantes_recepcion WHERE idcomprobante =  @idcomprobante
	SELECT * FROM ew_cfd_comprobantes_recepcion_mov WHERE idcomprobante =  @idcomprobante
	SELECT * FROM ew_cfd_comprobantes_recepcion_impuestos WHERE idcomprobante =  @idcomprobante
END
GO
