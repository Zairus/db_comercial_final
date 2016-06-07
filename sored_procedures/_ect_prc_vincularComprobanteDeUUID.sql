USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160606
-- Description:	Vincular comprobnante desde UUID
-- =============================================
ALTER PROCEDURE [dbo].[_ect_prc_vincularComprobanteDeUUID]
	@uuid AS VARCHAR(50)
AS

SET NOCOUNT ON

DECLARE
	@idcomprobante AS INT
	,@idtran AS INT
	,@rfc AS VARCHAR(15)

	,@idproveedor AS INT
	,@fecha AS SMALLDATETIME
	,@total AS DECIMAL(18,6)
	,@folio AS VARCHAR(15)

	,@output_code AS INT = 0
	,@output_message AS VARCHAR(500) = ''

SELECT
	@idcomprobante = ccr.idcomprobante
	,@rfc = ccr.Emisor_rfc
	,@fecha = ccr.fecha
	,@total = ccr.total
FROM
	ew_cfd_comprobantes_recepcion AS ccr
WHERE
	ccr.Timbre_UUID = @uuid

IF @idcomprobante IS NULL
BEGIN
	SELECT @output_code = 1
	SELECT @output_message = 'Error: No se ha encontrado comprobante a vincular.'

	GOTO no_vinculado
END

SELECT TOP 1
	@idproveedor = p.idproveedor
FROM
	ew_proveedores AS p
WHERE
	p.rfc = @rfc

IF @idproveedor IS NULL
BEGIN
	SELECT @output_code = 2
	SELECT @output_message = 'Error: El proveedor del comprobante, no existe en el sistema.'

	GOTO no_vinculado
END

SELECT TOP 1
	@idtran = ct.idtran
	,@folio = ct.folio
FROM
	ew_cxp_transacciones AS ct
WHERE
	ct.cancelado = 0
	AND ct.tipo = 1
	AND ct.idproveedor = @idproveedor
	AND CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ct.fecha, 3) + ' 00:00') = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), @fecha, 3))
	AND ABS(ct.total - @total) < 0.01

IF @idtran IS NULL
BEGIN
	SELECT @output_code = 3
	SELECT @output_message = 'Error: No existe transaccion que coincida en sistema con comprobante indicado.'

	GOTO no_vinculado
END

IF (SELECT COUNT(*) FROM ew_cxp_transacciones AS ct WHERE ct.idcomprobante > 0 AND ct.idtran = @idtran) > 0
BEGIN
	SELECT @output_code = 3
	SELECT @output_message = 'El documento ya tiene otro comprobante vinculado.'

	GOTO no_vinculado
END

UPDATE ew_cxp_transacciones SET
	idcomprobante = @idcomprobante
WHERE
	idtran = @idtran

SELECT @output_code = 0
SELECT @output_message = 'Comprobante vinculado con transaccion: ' + LTRIM(RTRIM(STR(@idtran))) + ', folio: ' + @folio

RETURN

no_vinculado:
SELECT [code] = @output_code, [mensaje] = @output_message
GO
