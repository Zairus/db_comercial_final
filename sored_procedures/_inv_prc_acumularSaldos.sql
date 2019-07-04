USE db_comercial_final
GO
IF OBJECT_ID('_inv_prc_acumularSaldos') IS NOT NULL
BEGIN
	DROP PROCEDURE _inv_prc_acumularSaldos
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190612
-- Description:	Axumular existencias y costos por periodo en inventario
-- =============================================
CREATE PROCEDURE [dbo].[_inv_prc_acumularSaldos]
	@idarticulo AS INT
	, @idalmacen AS INT
	, @ejercicio AS INT
	, @periodo AS INT
	, @tipo AS SMALLINT
	, @cantidad AS DECIMAL(18,6)
	, @costo AS DECIMAL(18,6)
AS

SET NOCOUNT ON

DECLARE
	@ejercicio_inicial AS INT
	, @ejercicio_final AS INT
	, @periodo_inicial AS INT
	, @periodo_final AS INT
	, @existencia_actual AS DECIMAL(18,6)
	, @costo_actual AS DECIMAL(18,6)

SELECT 
	@ejercicio_inicial = MIN(ejercicio)
	, @ejercicio_final = MAX(ejercicio) 
FROM 
	ew_inv_saldos
WHERE
	idarticulo = @idarticulo
	AND idalmacen = @idalmacen

SELECT
	@periodo_inicial = MIN(periodo)
FROM
	ew_inv_saldos
WHERE
	idarticulo = @idarticulo
	AND idalmacen = @idalmacen
	AND ejercicio = @ejercicio_inicial

IF @ejercicio < ISNULL(@ejercicio_inicial, 0)
BEGIN
	SELECT @ejercicio_inicial = @ejercicio
	SELECT @periodo_inicial = @periodo
END

SELECT
	@periodo_final = MAX(periodo)
FROM
	ew_inv_saldos
WHERE
	idarticulo = @idarticulo
	AND idalmacen = @idalmacen
	AND ejercicio = @ejercicio_final

SELECT @ejercicio_inicial = ISNULL(@ejercicio_inicial, @ejercicio)
SELECT @periodo_inicial = ISNULL(@periodo_inicial, @periodo)

SELECT @ejercicio_final = ISNULL(@ejercicio_final, YEAR(GETDATE()))
SELECT @periodo_final = ISNULL(@periodo_final, MONTH(GETDATE()))

WHILE @ejercicio_inicial <= @ejercicio_final
BEGIN
	WHILE @periodo_inicial <= IIF(@ejercicio_inicial = @ejercicio_final, @periodo_final, 12)
	BEGIN
		INSERT INTO ew_inv_saldos (
			idarticulo
			, idalmacen
			, ejercicio
			, periodo
		)
		SELECT
			[idarticulo] = @idarticulo
			, [idalmacen] = @idalmacen
			, [ejercicio] = @ejercicio_inicial
			, [periodo] = @periodo_inicial
		WHERE
			(
				SELECT COUNT(*) 
				FROM 
					ew_inv_saldos AS s
				WHERE
					s.idarticulo = @idarticulo
					AND s.idalmacen = @idalmacen
					AND s.ejercicio = @ejercicio_inicial
					AND s.periodo = @periodo_inicial
			) = 0

		UPDATE ew_inv_saldos SET
			entradas = entradas + IIF(@tipo = 1, @cantidad, 0)
			, salidas = salidas + IIF(@tipo = 2, @cantidad, 0)
			, cargos = cargos + IIF(@tipo = 1, @costo, 0)
			, abonos = abonos + IIF(@tipo = 2, @costo, 0)
		WHERE
			idarticulo = @idarticulo
			AND idalmacen = @idalmacen
			AND ejercicio = @ejercicio_inicial
			AND periodo = @periodo_inicial
			AND @ejercicio_inicial = @ejercicio
			AND @periodo_inicial = @periodo

		UPDATE ew_inv_saldos SET
			existencia_inicial = ISNULL(@existencia_actual, existencia_inicial)
			, costo_inicial = ISNULL(@costo_actual, costo_inicial)
		WHERE
			idarticulo = @idarticulo
			AND idalmacen = @idalmacen
			AND ejercicio = @ejercicio_inicial
			AND periodo = @periodo_inicial

		SELECT 
			@existencia_actual = existencia_inicial
			, @costo_actual = costo_inicial
		FROM
			ew_inv_saldos
		WHERE
			idarticulo = @idarticulo
			AND idalmacen = @idalmacen
			AND ejercicio = @ejercicio_inicial
			AND periodo = @periodo_inicial
			AND @existencia_actual IS NULL

		SELECT 
			@existencia_actual = @existencia_actual + entradas - salidas
			, @costo_actual = @costo_actual + cargos - abonos
		FROM
			ew_inv_saldos
		WHERE
			idarticulo = @idarticulo
			AND idalmacen = @idalmacen
			AND ejercicio = @ejercicio_inicial
			AND periodo = @periodo_inicial
			AND @existencia_actual IS NOT NULL

		UPDATE ew_inv_saldos SET
			existencia_final = @existencia_actual
			, costo_final = @costo_actual
		WHERE
			idarticulo = @idarticulo
			AND idalmacen = @idalmacen
			AND ejercicio = @ejercicio_inicial
			AND periodo = @periodo_inicial

		SELECT @periodo_inicial = @periodo_inicial + 1
	END

	SELECT @periodo_inicial = 1
	SELECT @ejercicio_inicial = @ejercicio_inicial + 1
END
GO
