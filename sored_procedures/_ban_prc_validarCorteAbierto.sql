USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20151127
-- Description:	Validar corte de caja abierto
-- =============================================
ALTER PROCEDURE _ban_prc_validarCorteAbierto
	@idcuenta AS INT
AS

SET NOCOUNT ON

DECLARE
	@corte_idtran AS INT
	,@corte_folio AS VARCHAR(15)
	,@error_mensaje AS VARCHAR(500)

SELECT
	@corte_idtran = bd.idtran
	,@corte_folio = bd.folio
FROM
	ew_ban_documentos AS bd
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = bd.idtran
WHERE
	st.idestado = 0
	AND bd.cancelado = 0
	AND bd.transaccion = 'BPR2'
	AND bd.idcuenta1 = @idcuenta

IF @corte_idtran IS NOT NULL
BEGIN
	SELECT @error_mensaje = 'Error: Existe el corte folio ' + @corte_folio + ', elaborado para esta caja. Favor de autorizar o cerrar el corte abierto.'

	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END
GO
