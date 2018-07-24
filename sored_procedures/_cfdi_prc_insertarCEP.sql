USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180630
-- Description:	Insertar un CEP desde XML
-- =============================================
ALTER PROCEDURE [dbo].[_cfdi_prc_insertarCEP]
	@xml AS VARCHAR(MAX)
AS

SET NOCOUNT ON
SET DATEFORMAT DMY

DECLARE
	@cep_xml AS XML

DECLARE
	@fecha_operacion AS DATETIME
	,@referencia AS VARCHAR(50)

DECLARE
	@banco AS VARCHAR(MAX)
	,@tipo_cuenta AS VARCHAR(10)
	,@cuenta AS VARCHAR(50)
	,@rfc AS VARCHAR(20)
	,@concepto AS VARCHAR(MAX)
	,@iva AS DECIMAL(18,6)
	,@monto AS DECIMAL(18,6)

DECLARE
	@cliente_banco AS VARCHAR(MAX)
	,@cliente_nombre AS VARCHAR(MAX)
	,@cliente_tipo_cuenta AS VARCHAR(10)
	,@cliente_cuenta AS VARCHAR(50)
	,@cliente_rfc AS VARCHAR(20)

DECLARE
	@idcomprobante AS INT

SELECT @cep_xml = @xml

SELECT @fecha_operacion = (
	RIGHT(@cep_xml.value('(/SPEI_Tercero/@FechaOperacion)[1]', 'VARCHAR(MAX)'), 2)
	+ '/'
	+ LEFT(RIGHT(@cep_xml.value('(/SPEI_Tercero/@FechaOperacion)[1]', 'VARCHAR(MAX)'), 5), 2)
	+ '/'
	+ LEFT(@cep_xml.value('(/SPEI_Tercero/@FechaOperacion)[1]', 'VARCHAR(MAX)'), 4)
	+ ' '
	+ @cep_xml.value('(/SPEI_Tercero/@Hora)[1]', 'VARCHAR(MAX)')
)

SELECT @referencia = @cep_xml.value('(/SPEI_Tercero/@ClaveSPEI)[1]', 'VARCHAR(MAX)')

SELECT @banco = @cep_xml.value('(/SPEI_Tercero/Beneficiario/@BancoReceptor)[1]', 'VARCHAR(MAX)')
SELECT @tipo_cuenta = @cep_xml.value('(/SPEI_Tercero/Beneficiario/@TipoCuenta)[1]', 'VARCHAR(10)')
SELECT @cuenta = @cep_xml.value('(/SPEI_Tercero/Beneficiario/@Cuenta)[1]', 'VARCHAR(MAX)')
SELECT @rfc = @cep_xml.value('(/SPEI_Tercero/Beneficiario/@RFC)[1]', 'VARCHAR(20)')
SELECT @concepto = @cep_xml.value('(/SPEI_Tercero/Beneficiario/@Concepto)[1]', 'VARCHAR(MAX)')
SELECT @iva = @cep_xml.value('(/SPEI_Tercero/Beneficiario/@IVA)[1]', 'DECIMAL(18,6)')
SELECT @monto = @cep_xml.value('(/SPEI_Tercero/Beneficiario/@MontoPago)[1]', 'DECIMAL(18,6)')

SELECT @cliente_banco = @cep_xml.value('(/SPEI_Tercero/Ordenante/@BancoEmisor)[1]', 'VARCHAR(MAX)')
SELECT @cliente_nombre = @cep_xml.value('(/SPEI_Tercero/Ordenante/@Nombre)[1]', 'VARCHAR(MAX)')
SELECT @cliente_tipo_cuenta = @cep_xml.value('(/SPEI_Tercero/Ordenante/@TipoCuenta)[1]', 'VARCHAR(MAX)')
SELECT @cliente_cuenta = @cep_xml.value('(/SPEI_Tercero/Ordenante/@Cuenta)[1]', 'VARCHAR(MAX)')
SELECT @cliente_rfc = @cep_xml.value('(/SPEI_Tercero/Ordenante/@RFC)[1]', 'VARCHAR(MAX)')

SELECT @idcomprobante = MAX(idcomprobante) FROM ew_cfd_cep
SELECT @idcomprobante = ISNULL(@idcomprobante, 0) + 1

IF EXISTS (
	SELECT *
	FROM
		ew_cfd_cep AS cep
	WHERE
		cep.emisor_rfc = @cliente_rfc
		AND cep.fecha_operacion = @fecha_operacion
		AND cep.receptor_monto = @monto
)
BEGIN
	RAISERROR('Error: El comprobante CEP ya se ha importado previamente.', 16, 1)
	RETURN
END

INSERT INTO ew_cfd_cep (
	idcomprobante
	,fecha_operacion
	,referencia
	,idcliente
	,receptor_banco
	,receptor_tipo_cuenta
	,receptor_cuenta
	,receptor_rfc
	,receptor_concepto
	,receptor_iva
	,receptor_monto
	,emisor_banco
	,emisor_nombre
	,emisor_tipo_cuenta
	,emisor_cuenta
	,emisor_rfc
	,cep_archivo
	,cep_xml
)
SELECT
	[idcomprobante] = @idcomprobante
	, [fecha_operacion] = @fecha_operacion
	, [referencia] = @referencia
	, [idcliente] = ISNULL((SELECT TOP 1 cfa.idcliente FROM ew_clientes_facturacion AS cfa WHERE cfa.rfc = @cliente_rfc), 0)
	, [receptor_banco] = @banco
	, [receptor_tipo_cuenta] = @tipo_cuenta
	, [receptor_cuenta] = @cuenta
	, [receptor_rfc] = @rfc
	, [receptor_concepto] = @concepto
	, [receptor_iva] = @iva
	, [receptor_monto] = @monto
	, [emisor_banco] = @cliente_banco
	, [emisor_nombre] = @cliente_nombre
	, [emisor_tipo_cuenta] = @cliente_tipo_cuenta
	, [emisor_cuenta] = @cliente_cuenta
	, [emisor_rfc] = @cliente_rfc
	, [cep_archivo] = ''
	, [cep_xml] = @cep_xml

SELECT [importado] = CONVERT(BIT, 1)
GO
