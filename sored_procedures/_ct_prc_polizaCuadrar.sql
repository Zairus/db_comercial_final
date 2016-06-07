USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160531
-- Description:	Cuadrar Poliza
-- =============================================
ALTER PROCEDURE _ct_prc_polizaCuadrar
	@poliza_idtran AS INT
	,@cuenta AS VARCHAR(20)
	,@concepto AS VARCHAR(50) = NULL
AS

SET NOCOUNT ON

DECLARE
	@cargos AS DECIMAL(18,6)
	,@abonos AS DECIMAL(18,6)
	,@consecutivo AS INT
	,@idsucursal AS INT

SELECT
	@cargos = SUM(pm.cargos)
	,@abonos = SUM(pm.abonos)
FROM
	ew_ct_poliza_mov AS pm
WHERE
	pm.idtran = @poliza_idtran

SELECT
	@consecutivo = MAX(consecutivo)
	,@idsucursal = MAX(idsucursal)
FROM
	ew_ct_poliza_mov As pm
WHERE
	pm.idtran = @poliza_idtran

SELECT @consecutivo = ISNULL(@consecutivo, 0) + 1

IF (@cargos - @abonos) <> 0
BEGIN
INSERT INTO ew_ct_poliza_mov (
	idtran
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
	[idtran] = @poliza_idtran
	,[consecutivo] = @consecutivo
	,[idsucursal] = @idsucursal
	,[cuenta] = @cuenta
	,[tipomov] = (
		CASE 
			WHEN (@cargos - @abonos) > 0 THEN 1
			ELSE 0
		END
	)
	,[referencia] = ISNULL(@concepto, 'CUADRE')
	,[cargos] = (CASE WHEN (@abonos - @cargos) > 0 THEN (@abonos - @cargos) ELSE 0 END)
	,[abonos] = (CASE WHEN (@cargos - @abonos) > 0 THEN (@cargos - @abonos) ELSE 0 END)
	,[importe] = (CASE WHEN (@abonos - @cargos) > 0 THEN (@abonos - @cargos) ELSE (@cargos - @abonos) END)
	,[concepto] = ISNULL(@concepto, 'CUADRE')
END
GO
