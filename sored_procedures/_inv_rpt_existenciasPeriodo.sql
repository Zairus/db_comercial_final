USE db_comercial_final
GO
IF OBJECT_ID('_inv_rpt_existenciasPeriodo') IS NOT NULL
BEGIN
	DROP PROCEDURE _inv_rpt_existenciasPeriodo
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190614
-- Description:	Existencias por periodo
-- =============================================
CREATE PROCEDURE [dbo].[_inv_rpt_existenciasPeriodo]
	@idsucursal AS INT = 0
	, @idalmacen AS INT = 0
	, @idarticulo AS INT = 0
	, @ejercicio_inicial AS INT = NULL
	, @periodo_inicial AS INT = NULL
	, @ejercicio_final AS INT = NULL
	, @periodo_final AS INT = NULL
AS

SET NOCOUNT ON

SELECT @ejercicio_inicial = ISNULL(@ejercicio_inicial, YEAR(GETDATE()))
SELECT @ejercicio_final = ISNULL(@ejercicio_final, YEAR(GETDATE()))

SELECT @periodo_inicial = ISNULL(@periodo_inicial, MONTH(GETDATE()))
SELECT @periodo_final = ISNULL(@periodo_final, MONTH(GETDATE()))

SELECT
	[ord1] = ROW_NUMBER() OVER (ORDER BY s.idalmacen, s.ejercicio, s.periodo, a.nombre)
	, [sucursal] = suc.nombre
	, [almacen] = alm.nombre
	, [periodo_grupo] = (
		[dbo].[_sys_fnc_rellenar](s.ejercicio, 4, '0')
		+ '-'
		+ [dbo].[_sys_fnc_rellenar](s.periodo, 2, '0')
	)

	, [ejercicio] = s.ejercicio
	, [periodo] = s.periodo

	, [producto] = a.nombre
	, [producto_codigo] = a.codigo

	, [existencia_inicial] = s.existencia_inicial
	, [entradas] = s.entradas
	, [salidas] = s.salidas
	, [existencia_final] = s.existencia_final
	
	, [costo_inicial] = s.costo_inicial
	, [cargos] = s.cargos
	, [abonos] = s.abonos
	, [costo_final] = s.costo_final
FROM 
	ew_inv_saldos AS s
	LEFT JOIN ew_inv_almacenes AS alm
		ON alm.idalmacen = s.idalmacen
	LEFT JOIN ew_sys_sucursales AS suc
		ON suc.idsucursal = alm.idsucursal
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = s.idarticulo
WHERE
	a.idtipo = 0
	AND a.inventariable = 1

	AND suc.idsucursal = ISNULL(NULLIF(@idsucursal, 0), suc.idsucursal)
	AND alm.idalmacen = ISNULL(NULLIF(@idalmacen, 0), alm.idalmacen)
	AND a.idarticulo = ISNULL(NULLIF(@idarticulo, 0), a.idarticulo)

	AND s.ejercicio BETWEEN @ejercicio_inicial AND @ejercicio_final
	AND (
		(
			s.periodo BETWEEN @periodo_inicial AND @periodo_final
			AND @ejercicio_inicial = @ejercicio_final
		)
		OR (
			s.periodo BETWEEN @periodo_inicial AND 12
			AND s.ejercicio = @ejercicio_inicial
			AND @ejercicio_inicial < @ejercicio_final
		)
		OR (
			s.periodo BETWEEN 1 AND @periodo_final
			AND s.ejercicio = @ejercicio_final
			AND @ejercicio_inicial < @ejercicio_final
		)
		OR (
			s.ejercicio > @ejercicio_inicial
			AND s.ejercicio < @ejercicio_final
		)
	)

	AND (
		s.existencia_inicial > 0
		OR s.entradas > 0
		OR s.salidas > 0
		OR s.existencia_final > 0
		OR s.costo_inicial > 0
		OR s.cargos > 0
		OR s.abonos > 0
		OR s.costo_final > 0
	)

ORDER BY
	s.idalmacen
	, s.ejercicio
	, s.periodo
	, a.nombre
GO
