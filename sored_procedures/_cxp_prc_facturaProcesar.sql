USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091107
-- modificado: ARVIN 2011
-- Description:	Procesar factura de compra.
-- =============================================
ALTER PROCEDURE [dbo].[_cxp_prc_facturaProcesar]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE 
	@idtran_oc BIGINT
	,@idu AS INT

SELECT
	@idu = idu
FROM
	ew_com_transacciones
WHERE
	idtran = @idtran

INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	,idmov2
	,campo
	,valor
)
SELECT 
	[idmov1] = idmov
	,[idmov2] = idmov2
	,[campo] = 'cantidad_facturada'
	,[valor] = cantidad_facturada 
FROM
	ew_com_transacciones_mov
WHERE
	idtran = @idtran

DECLARE cur_oc CURSOR FOR
	SELECT DISTINCT idtran2 
	FROM
		ew_com_transacciones_mov
	WHERE
		idtran = @idtran

OPEN cur_oc

FETCH NEXT FROM cur_oc INTO
	@idtran_oc

WHILE @@fetch_status = 0
BEGIN
	EXEC _com_prc_ordenEstado @idtran_oc, @idu

	FETCH NEXT FROM cur_oc INTO
		@idtran_oc
END

CLOSE cur_oc
DEALLOCATE cur_oc
GO
