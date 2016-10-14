USE db_comercial_final
GO
-- =============================================
-- Author:		Fernanda Corona
-- Create date: 2009 Diciembre
-- Description:	Autorizar Cotización.
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_cotizacionAutorizar]
	@idtran AS INT
	,@idu AS INT
AS

SET NOCOUNT ON

INSERT INTO ew_sys_transacciones2
	(idtran, idestado, idu)
VALUES
	(@idtran, 3, @idu)
GO
