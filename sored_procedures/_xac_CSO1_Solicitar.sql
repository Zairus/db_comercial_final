USE db_comercial_final
GO
IF OBJECT_ID('_xac_CSO1_Solicitar') IS NOT NULL
BEGIN
	DROP PROCEDURE _xac_CSO1_Solicitar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200414
-- Description:	Solicitar requisición de compra
-- =============================================
CREATE PROCEDURE [dbo].[_xac_CSO1_Solicitar]
	@idtran AS INT
	, @idu AS INT
	, @comentario AS VARCHAR(4000) = ''
AS

SET NOCOUNT ON

DECLARE
	@msg AS VARCHAR(1000)

-- Registrando el cambio de estado en la transaccion de Elaborado a Solicitado
INSERT INTO ew_sys_transacciones2 (
	idtran
	, idestado
	, idu
	, comentario
)
SELECT
	[idtran] = @idtran
	, [idestado] = 31
	, [idu] =  @idu
	, [comentario] = @comentario

IF @@ERROR != 0 OR @@ROWCOUNT = 0
BEGIN
	SELECT @msg='Error: No se logró cambiar el estado de la transaccion.'

	RAISERROR(@msg, 16, 1)
	RETURN
END
GO
