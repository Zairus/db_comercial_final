USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091124
-- Description:	Procesar traspaso de bancos
-- =============================================
ALTER PROCEDURE [dbo].[_ban_prc_TraspasoCancelar]
	@idtran AS INT
	,@cancelado_fecha AS SMALLDATETIME
	,@idu AS SMALLINT
AS

DECLARE
	@pass VARCHAR(100)

UPDATE ew_ban_documentos SET
	cancelado = 1
	,cancelado_fecha = @cancelado_fecha
WHERE
	idtran = @idtran

SELECT
	@pass = u.[password]
FROM
	ew_usuarios AS u 
WHERE 
	u.idu = @idu
	
EXEC _ct_prc_cancelarPoliza2  @idtran, @idu, @pass, @cancelado_fecha
GO
