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
	,@transaccion VARCHAR(5) = ''

SELECT
	@idu = idu
	,@transaccion = transaccion
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

IF EXISTS(
	SELECT * 
	FROM ew_com_ordenes_mov 
	WHERE 
		idalmacen = 0 
		AND idtran = @idtran
)
BEGIN
	RAISERROR('Error: Existen registros sin almacen asignado.', 16, 1)
	RETURN
END

IF EXISTS(
	SELECT * 
	FROM ew_com_ordenes_mov 
	WHERE 
		idobra = 0 
		AND idtran = @idtran
		AND @transaccion = 'COR2'
)
BEGIN
	RAISERROR('Error: Falta especificar la obra a alguno de los artículos.', 16, 1)
	RETURN
END

EXEC _com_prc_ordenValidar @idtran, @idu
GO
