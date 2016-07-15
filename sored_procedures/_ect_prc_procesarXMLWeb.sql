USE db_comercial_final
GO
ALTER PROCEDURE [dbo].[_ect_prc_procesarXMLWeb]
	@ruta AS VARCHAR(200)
AS

SET NOCOUNT ON

BEGIN TRAN

BEGIN TRY
	EXEC [dbo].[_cfdi_prc_procesarXMLRecepcion] @ruta
	COMMIT TRAN
END TRY
BEGIN CATCH
	DECLARE @ErrorMessage NVARCHAR(4000)
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	SELECT @ErrorMessage = ERROR_MESSAGE()
	SELECT @ErrorSeverity = ERROR_SEVERITY()
	SELECT @ErrorState = ERROR_STATE()
	SELECT
		[Error] = 1
		, [ErrorMessage] = @ErrorMessage
		, [ErrorSeverity] = @ErrorSeverity
		, [ErrorState] = @ErrorState
	ROLLBACK TRAN
END CATCH
GO
