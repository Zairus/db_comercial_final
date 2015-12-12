USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20100520
-- Description:	Anular contabilidad de transacción.
-- =============================================
ALTER PROCEDURE [dbo].[_ct_prc_transaccionAnularCT]
	@idtran AS INT
	,@limpiar AS BIT = 0
AS

SET NOCOUNT ON

INSERT INTO ew_ct_poliza_mov (
	 idtran
	,idtran2
	,consecutivo
	,idsucursal
	,cuenta
	,tipomov
	,referencia
	,cargos
	,abonos
	,importe
	,concepto
)

SELECT
	 idtran
	,idtran2
	,consecutivo
	,idsucursal
	,cuenta
	,tipomov
	,referencia
	,[cargos] = (cargos * -1)
	,[abonos] = (abonos * -1)
	,[importe] = (importe * -1)
	,concepto
FROM
	ew_ct_poliza_mov
WHERE
	idtran2 = @idtran

IF (@limpiar = 1 AND @idtran > 0)
BEGIN
	DELETE FROM ew_ct_poliza_mov WHERE idtran2 = @idtran
END
GO
