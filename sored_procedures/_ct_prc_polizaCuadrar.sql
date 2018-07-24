USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160531
-- Description:	Cuadrar Poliza
-- =============================================
ALTER PROCEDURE [dbo].[_ct_prc_polizaCuadrar]
	@poliza_idtran AS INT
	, @cuenta AS VARCHAR(20)
	, @concepto AS VARCHAR(50) = NULL
	, @cuenta_abono AS VARCHAR(20) = ''
AS

SET NOCOUNT ON

DECLARE
	@cargos AS DECIMAL(18,6)
	, @abonos AS DECIMAL(18,6)
	, @consecutivo AS INT
	, @idsucursal AS INT
	, @idtran2 AS INT

SELECT
	@cargos = SUM(pm.cargos)
	, @abonos = SUM(pm.abonos)
FROM
	ew_ct_poliza_mov AS pm
WHERE
	pm.idtran = @poliza_idtran

SELECT
	@consecutivo = MAX(pm.consecutivo)
	,@idsucursal = MAX(pm.idsucursal)
	,@idtran2 = MAX(pm.idtran2)
FROM
	ew_ct_poliza_mov As pm
WHERE
	pm.idtran = @poliza_idtran

SELECT @consecutivo = ISNULL(@consecutivo, 0) + 1
SELECT @cuenta_abono = (CASE WHEN @cuenta_abono = '' THEN @cuenta ELSE @cuenta_abono END)

IF ABS(@cargos - @abonos) > 0
BEGIN
	INSERT INTO ew_ct_poliza_mov (
		idtran
		, idtran2
		, consecutivo
		, idsucursal
		, cuenta
		, tipomov
		, referencia
		, cargos
		, abonos
		, importe
		, concepto
	)
	SELECT
		[idtran] = @poliza_idtran
		, [idtran2] = @idtran2
		, [consecutivo] = @consecutivo
		, [idsucursal] = @idsucursal
		, [cuenta] = (
			CASE 
				WHEN (@cargos - @abonos) > 0 THEN @cuenta_abono
				ELSE @cuenta
			END
		)
		, [tipomov] = (
			CASE 
				WHEN (@cargos - @abonos) > 0 THEN 1
				ELSE 0
			END
		)
		, [referencia] = ISNULL(@concepto, 'CUADRE')
		, [cargos] = (CASE WHEN (@abonos - @cargos) > 0 THEN (@abonos - @cargos) ELSE 0 END)
		, [abonos] = (CASE WHEN (@cargos - @abonos) > 0 THEN (@cargos - @abonos) ELSE 0 END)
		, [importe] = (CASE WHEN (@abonos - @cargos) > 0 THEN (@abonos - @cargos) ELSE (@cargos - @abonos) END)
		, [concepto] = ISNULL(@concepto, 'CUADRE')
END
GO
