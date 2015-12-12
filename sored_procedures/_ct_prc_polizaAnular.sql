USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20100621
-- Description:	Anular póliza contable.
-- =============================================
ALTER PROCEDURE [dbo].[_ct_prc_polizaAnular]
	@idtran AS INT
	,@limpiar AS BIT = 0
AS

SET NOCOUNT ON

INSERT INTO ew_ct_poliza_mov (
	 idtran
	,idtran2
	,consecutivo
	,cuenta
	,concepto
	,referencia
	,cargos
	,abonos
	,tipomov
	,moneda
	,tipocambio
	,importe
	,idsucursal
)
SELECT
	 idtran
	,idtran2
	,consecutivo
	,cuenta
	,concepto
	,referencia
	,[cargos] = (cargos * -1)
	,[abonos] = (abonos * -1)
	,tipomov
	,moneda
	,tipocambio
	,[importe] = (importe * -1)
	,idsucursal
FROM
	ew_ct_poliza_mov
WHERE
	idtran = @idtran

IF (@limpiar = 1)
BEGIN
	DELETE FROM ew_ct_poliza_mov WHERE idtran = @idtran
END
GO
