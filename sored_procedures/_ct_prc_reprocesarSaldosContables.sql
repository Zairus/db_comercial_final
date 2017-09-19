USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170525
-- Description:	Reprocesar todos los saldos de contabilidad
-- =============================================
ALTER PROCEDURE [dbo].[_ct_prc_reprocesarSaldosContables]
	@confirmar AS BIT = 0
AS

SET NOCOUNT ON

IF @confirmar = 0
BEGIN
	RAISERROR('Para proceder se debe confirmar movimiento.', 16, 1)
	RETURN
END

DECLARE
	@ejercicio AS INT
	,@ejercicio_inicial AS INT
	,@ejercicio_final AS INT
	,@periodo_final AS INT

TRUNCATE TABLE ew_ct_saldos

SELECT @ejercicio_inicial = MIN(pol.ejercicio)
FROM
	ew_ct_poliza AS pol

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
	EXEC _ct_prc_ejercicioInicializar @ejercicio
	EXEC _ct_prc_reprocesarSaldosEjercicio @ejercicio

	SELECT @ejercicio = @ejercicio + 1
END

SELECT
	[resultado] = (
		'Ejercicio Inicial: ' + LTRIM(RTRIM(STR(@ejercicio_inicial))) + '; Ejercicio Final: ' + LTRIM(RTRIM(STR(@ejercicio_final)))
	)

UNION ALL

SELECT
	[resultado] = (
		'['
		+ (
			CASE
				WHEN ABS(csg.cargos - csg.abonos) > 0.01 THEN 'ERROR'
				ELSE 'INFORMATIVO'
			END
		)
		+ '] '
		+ 'Diferencia en balanza: ' + CONVERT(VARCHAR(20), (csg.cargos - csg.abonos))
		+ ', Cargos: ' + CONVERT(VARCHAR(20), csg.cargos)
		+ ', Abonos: ' + CONVERT(VARCHAR(20), csg.abonos)
	)
FROM 
	ew_ct_saldosGlobales AS csg 
WHERE 
	csg.idsucursal = 0 
	AND csg.cuenta = '_GLOBAL'
	AND ABS(csg.cargos - csg.abonos) > 0.0
	AND csg.ejercicio = @ejercicio_final
	AND csg.periodo = @periodo_final

UNION ALL

SELECT
	[resultado] = (
		'[ERROR - '
		+ 'Poliza '
		+ pm.folio
		+ ', periodo: '
		+ LTRIM(RTRIM(STR(pm.ejercicio)))
		+ '-'
		+ LTRIM(RTRIM(STR(pm.periodo)))
		+ ', idtran: '
		+ LTRIM(RTRIM(STR(pm.idtran)))
		+'] Cuenta '
		+ pm.cuenta
		+ (
			CASE 
				WHEN cc.nombre IS NULL THEN ' No existe en el catalogo.'
				ELSE ' No es una cuenta afectable.'
			END
		)
	)
FROM 
	ew_ct_polizaDetalle AS pm 
	LEFT JOIN ew_ct_cuentas AS cc
		ON cc.cuenta = pm.cuenta
WHERE 
	cc.nombre IS NULL
	OR (ISNULL(cc.afectable, 0) = 0)
GO
