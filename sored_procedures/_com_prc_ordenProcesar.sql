USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091029
-- Description:	Procesar Orden de Compra
-- =============================================
ALTER PROCEDURE [dbo].[_com_prc_ordenProcesar]
	@idtran AS BIGINT
AS

SET NOCOUNT ON

DECLARE 
	@idu AS INT

SELECT
	@idu = idu
FROM
	ew_com_ordenes
WHERE
	idtran = @idtran

IF NOT EXISTS(SELECT * FROM ew_sys_transacciones2 LEFT JOIN ew_com_ordenes ON ew_com_ordenes.idtran2= ew_sys_transacciones2.idtran WHERE idtran2= @idtran AND idestado=35)
BEGIN
	INSERT INTO ew_sys_transacciones2 (
		idtran
		, idestado
		, idu
	)
	SELECT
		[idtran] = idtran2
		,[idestado] = 34
		,[idu] = idu
	FROM 
		ew_com_ordenes
	WHERE
		idtran2 <> 0
		AND idtran = @idtran
END

EXEC _com_prc_ordenValidar @idtran, @idu
GO
