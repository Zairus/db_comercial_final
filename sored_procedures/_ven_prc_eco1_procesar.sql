USE db_comercial_final
GO
IF OBJECT_ID('_ven_prc_eco1_procesar') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_prc_eco1_procesar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190605
-- Description:	Procesar cotizacion de venta
-- =============================================
CREATE PROCEDURE [dbo].[_ven_prc_eco1_procesar]
	@idtran AS INT
	, @idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@importe_documento AS DECIMAL(18,6)
	, @importe_conceptos AS DECIMAL(18,6)
	, @error_mensaje AS VARCHAR(500)

SELECT
	@importe_documento = eco.subtotal
FROM
	ew_ven_documentos AS eco
WHERE
	eco.idtran = @idtran

SELECT
	@importe_conceptos = SUM(ecod.importe)
FROM
	ew_ven_documentos_mov AS ecod
WHERE
	ecod.idtran = @idtran

SELECT @importe_conceptos = ISNULL(@importe_conceptos, 0)

SELECT
	@error_mensaje = (
		'Error: '
		+ 'La suma de conceptos [' + CONVERT(VARCHAR(20), @importe_conceptos) + '], '
		+ 'no coincide con el total del documento [' + CONVERT(VARCHAR(20), @importe_documento) + ']'
	)
WHERE
	ABS(@importe_documento - @importe_conceptos) > 0.01

IF @error_mensaje IS NOT NULL
BEGIN
	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

EXEC [dbo].[_sys_prc_genera_consecutivo] @idtran, ''
GO
