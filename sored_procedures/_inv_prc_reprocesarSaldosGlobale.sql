USE db_comercial_final
GO
IF OBJECT_ID('_inv_prc_reprocesarSaldosGlobale') IS NOT NULL
BEGIN
	DROP PROCEDURE _inv_prc_reprocesarSaldosGlobale
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190612
-- Description:	Regenerar acumulacion de saldos de inventario
-- =============================================
GO
CREATE PROCEDURE [dbo].[_inv_prc_reprocesarSaldosGlobale]
AS

SET NOCOUNT ON

DECLARE
	@cmd AS NVARCHAR(4000)
	, @idr AS INT = 0

SET DEADLOCK_PRIORITY 10

TRUNCATE TABLE ew_inv_saldos

INSERT INTO ew_inv_saldos (
	idarticulo
	, idalmacen
	, ejercicio
	, periodo
	, existencia_inicial
	, entradas
	, salidas
	, existencia_final
	, costo_inicial
	, cargos
	, abonos
	, costo_final
)

SELECT
	[idarticulo] = im.idarticulo
	, [idalmacen] = im.idalmacen
	, [ejercicio] = YEAR(im.fecha)
	, [periodo] = MONTH(im.fecha)
	, [existencia_inicial] = 0
	, [entradas] = SUM(IIF(im.tipo = 1, im.cantidad, 0))
	, [salidas] = SUM(IIF(im.tipo = 2, im.cantidad, 0))
	, [existencia_final] = 0
	, [costo_inicial] = 0
	, [cargos] = SUM(IIF(im.tipo = 1, im.costo, 0))
	, [abonos] = SUM(IIF(im.tipo = 2, im.costo, 0))
	, [costo_final] = 0
FROM 
	ew_inv_movimientos AS im
GROUP BY
	im.idarticulo
	, YEAR(im.fecha)
	, MONTH(im.fecha)
	, im.idalmacen

SELECT
	[idr] = ROW_NUMBER() OVER (ORDER BY idarticulo, idalmacen, ejercicio, periodo)
	, [cmd] = CONVERT(NVARCHAR(MAX), (
		'EXEC [dbo].[_inv_prc_acumularSaldos] '
		+ LTRIM(RTRIM(STR(idarticulo)))
		+ ', ' + LTRIM(RTRIM(STR(idalmacen)))
		+ ', ' + LTRIM(RTRIM(STR(ejercicio)))
		+ ', ' + LTRIM(RTRIM(STR(periodo)))
		+ ', ' + LTRIM(RTRIM(STR(IIF(entradas > 0, 1, 2))))
		+ ', ' + CONVERT(VARCHAR(20), IIF(entradas > 0, entradas, salidas))
		+ ', ' + CONVERT(VARCHAR(20), IIF(cargos > 0, cargos, abonos))
		+ ''
	))
INTO
	#_tmp_inv_cmd
FROM
	ew_inv_saldos
ORDER BY
	idarticulo
	, idalmacen
	, ejercicio
	, periodo

TRUNCATE TABLE ew_inv_saldos

WHILE (SELECT COUNT(*) FROM #_tmp_inv_cmd WHERE idr > @idr) > 0
BEGIN
	SELECT @idr = MIN(idr)
	FROM
		#_tmp_inv_cmd
	WHERE
		idr > @idr

	SELECT @cmd = cmd FROM #_tmp_inv_cmd WHERE idr = @idr

	PRINT @idr
	PRINT @cmd
	EXEC sp_executesql @cmd
END

DROP TABLE #_tmp_inv_cmd
GO
