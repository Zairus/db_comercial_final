USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180731
-- Description:	Procesar factura de relacion
-- =============================================
ALTER PROCEDURE _ven_prc_facturaRelacionProcesar
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@credito AS BIT
	,@idforma AS INT

SELECT
	@credito = credito
	,@idforma  = idforma
FROM
	ew_cxc_transacciones 
WHERE 
	idtran = @idtran

IF @credito = 1
BEGIN
	UPDATE ct SET
		ct.idforma = (
			SELECT TOP 1 bf.idforma 
			FROM ew_ban_formas_aplica AS bf
			WHERE codigo = '99'
		)
		,ct.idmetodo = 2
	FROM
		ew_cxc_transacciones AS ct
	WHERE
		ct.idtran = @idtran
END
	ELSE
BEGIN
	UPDATE ct SET
		ct.idmetodo = 1
	FROM
		ew_cxc_transacciones AS ct
	WHERE
		ct.idtran = @idtran

	IF NOT EXISTS (
		SELECT *
		FROM
			ew_ban_formas_aplica
		WHERE
			idforma = @idforma
	)
	BEGIN
		RAISERROR('Error: No ha seleccionado forma de pago para la nueva factura.', 16, 1)
		RETURN
	END
END
GO
