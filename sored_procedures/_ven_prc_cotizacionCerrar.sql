USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091218
-- Description:	Cerrar orden de venta.
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_cotizacionCerrar]
	@idtran AS INT
	,@idu AS INT
	,@comentario AS VARCHAR(MAX) = ''
AS

SET NOCOUNT ON

INSERT INTO ew_sys_transacciones2
	(idtran, idestado, idu, comentario)
VALUES
	(@idtran, 251, @idu, @comentario)
GO
