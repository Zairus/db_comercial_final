USE db_comercial_final
GO
IF OBJECT_ID('_cxc_prc_web_graficoCXC') IS NOT NULL
BEGIN
	DROP PROCEDURE _cxc_prc_web_graficoCXC
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200323
-- Description:	Informacion para grafico de CXC
-- =============================================
CREATE PROCEDURE [dbo].[_cxc_prc_web_graficoCXC]
	@fecha AS DATETIME = NULL
AS

SET NOCOUNT ON

SELECT @fecha = ISNULL(@fecha, GETDATE())

SELECT
	[idr] = s.idr
	, [fecha_inicial] = DATEADD(
		DAY
		, -DATEPART(WEEKDAY, DATEADD(WEEK, (s.idr - 1) * -1, @fecha))
		, DATEADD(WEEK, (s.idr - 1) * -1, @fecha)
	)
	, [fecha_final] = GETDATE()
	, [titulo] = CONVERT(VARCHAR(200), '')
	, [cxc_saldo] = CONVERT(DECIMAL(18, 6), 0.00)
	, [cxc_promedio] = CONVERT(DECIMAL(18, 6), 0.00)
INTO
	#_tmp_graficoCXC
FROM
	[dbo].[_sys_fnc_separarMultilinea]('0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17', ',') AS s

UPDATE #_tmp_graficoCXC SET
	fecha_inicial = CONVERT(VARCHAR(10), fecha_inicial, 103)

UPDATE #_tmp_graficoCXC SET
	fecha_final = DATEADD(DAY, 6, fecha_inicial)

UPDATE tgc SET
	titulo = (
		[dbo].[_sys_fnc_rellenar](DATEPART(DAY, fecha_inicial), 2, '0')
		+ ' - '
		+ [dbo].[_sys_fnc_rellenar](DATEPART(DAY, fecha_final), 2, '0')
		+ ' '
		+ UPPER(LEFT(spd.descripcion, 3))
	)
FROM
	#_tmp_graficoCXC AS tgc
	LEFT JOIN ew_sys_periodos_datos AS spd
		ON spd.grupo = 'meses'
		AND spd.id = MONTH(fecha_final)

UPDATE tgc SET
	cxc_saldo = ISNULL((
		SELECT
			SUM((
				(
					CASE
						WHEN ct.transaccion = 'EFA4' THEN ct.saldo
						ELSE
							[dbo].[_cxc_fnc_documentoSaldoR2] (ct.idtran, @fecha)
					END
				) * (
					CASE 
						WHEN ct.tipo = 1 THEN 1 
						ELSE -1 
					END
				)
			))
		FROM
			ew_cxc_transacciones AS ct
		WHERE
			ct.cancelado = 0
			AND ct.aplicado = 1
			AND ct.tipo IN (1,2)
			AND ABS((
				(
					CASE
						WHEN ct.transaccion = 'EFA4' THEN ct.saldo
						ELSE
							[dbo].[_cxc_fnc_documentoSaldoR2] (ct.idtran, tgc.fecha_final)
					END
				) * (
					CASE 
						WHEN ct.tipo = 1 THEN 1 
						ELSE -1 
					END
				)
			)) > 0.01
	), 0)
FROM
	#_tmp_graficoCXC AS tgc

UPDATE tgc SET
	tgc.cxc_promedio = (
		SELECT 
			((MAX(tgc1.cxc_saldo) - MIN (tgc1.cxc_saldo)) / 18.00) * (19 - tgc.idr)
		FROM 
			#_tmp_graficoCXC AS tgc1
	)
FROM
	#_tmp_graficoCXC AS tgc

SELECT * FROM #_tmp_graficoCXC ORDER BY idr DESC

DROP TABLE #_tmp_graficoCXC
GO
