USE db_comercial_final
GO
IF OBJECT_ID('_cxc_prc_reprocesarSaldos') IS NOT NULL
BEGIN
	DROP PROCEDURE _cxc_prc_reprocesarSaldos
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200415
-- Description:	Reprocesar todos los saldos de CXC
-- =============================================
CREATE PROCEDURE [dbo].[_cxc_prc_reprocesarSaldos]
	@confirmar AS BIT = 0
	, @debug AS BIT = 0
AS

SET NOCOUNT ON
SET DEADLOCK_PRIORITY 10

DECLARE
	@ejercicio AS INT
	,@ejercicio_inicial AS INT
	,@ejercicio_final AS INT
	,@periodo_final AS INT

IF @confirmar = 0
BEGIN
	RAISERROR('Para proceder se debe confirmar movimiento.', 16, 1)
	RETURN
END

TRUNCATE TABLE ew_cxc_saldos

SELECT @ejercicio_inicial = MIN(YEAR(ct.fecha))
FROM
	ew_cxc_transacciones AS ct

IF @ejercicio_inicial IS NULL
BEGIN
	RETURN
END

SELECT @ejercicio_inicial = @ejercicio_inicial - 1
SELECT @ejercicio_final = YEAR(GETDATE())
SELECT @ejercicio = @ejercicio_inicial
SELECT @periodo_final = MONTH(GETDATE())

WHILE @ejercicio <= @ejercicio_final
BEGIN
	EXEC [dbo].[_cxc_prc_ejercicioInicializar] @ejercicio, @debug
	EXEC [dbo].[_cxc_prc_reprocesarSaldosEjercicio] @ejercicio, @debug

	SELECT @ejercicio = @ejercicio + 1
END

SELECT
	[resultado] = (
		'Ejercicio Inicial: ' + LTRIM(RTRIM(STR(@ejercicio_inicial))) 
		+ '; Ejercicio Final: ' + LTRIM(RTRIM(STR(@ejercicio_final)))
	)
GO
