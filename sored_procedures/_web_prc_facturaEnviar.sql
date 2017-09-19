USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170723
-- Description:	Enviar por correo
-- =============================================
ALTER PROCEDURE [dbo].[_web_prc_facturaEnviar]
	@factura_idtran AS INT
	,@correo_electronico AS VARCHAR(1000)
	,@mensaje AS VARCHAR(1000)
AS

SET NOCOUNT ON

DECLARE
	@resultado_codigo AS INT = 0
	,@resultado_mensaje AS VARCHAR(MAX) = ''

BEGIN TRY
	EXEC _cfd_prc_enviarEmail @factura_idtran, @correo_electronico, @mensaje, 1
END TRY
BEGIN CATCH
	SELECT @resultado_codigo = 8
	SELECT @resultado_mensaje = ERROR_MESSAGE()
	GOTO PRESENTAR_RESULTADO
END CATCH

PRESENTAR_RESULTADO:
GO

