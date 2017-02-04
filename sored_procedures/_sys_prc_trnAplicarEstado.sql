USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170127
-- Description:	Cambiar de estado a transacccion
-- =============================================
ALTER PROCEDURE _sys_prc_trnAplicarEstado
	@idtran AS INT
	,@estado_codigo AS VARCHAR(10)
	,@idu AS INT
	,@no_duplicar AS BIT = 0
AS

SET NOCOUNT ON

IF 
	NOT EXISTS(
		SELECT * 
		FROM 
			ew_sys_transacciones2 
		WHERE 
			idtran = @idtran 
			AND idestado = dbo.fn_sys_estadoID(@estado_codigo)
	)
	OR @no_duplicar = 0
BEGIN
	INSERT INTO ew_sys_transacciones2
		(idtran, idestado, idu)
	VALUES 
		(@idtran, dbo.fn_sys_estadoID(@estado_codigo), @idu)
END
GO
