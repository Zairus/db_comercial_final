USE db_comercial_final
GO
ALTER FUNCTION [dbo].[_inv_fnc_lotesSalida] (
	@idalmacen AS INT
	, @idarticulo AS INT
	, @lote AS VARCHAR(20)
	, @cantidad AS DECIMAL(18,6)
)
RETURNS @tb_lotes TABLE (
	idcapa INT
	, cantidad DECIMAL(18,6)
	, costo DECIMAL(18,6)
	, fecha_caducidad DATETIME
)
AS
BEGIN
	DECLARE
		@fecha_caducidad AS DATETIME
		, @idcapa AS INT
		, @existencia AS DECIMAL(18,6)
		, @valor AS DECIMAL(18,6)
		, @cantidad2 AS DECIMAL(18,6)

		, @x AS DECIMAL(18,6)
		, @costo AS DECIMAL(18,6)

	SELECT @cantidad2 = @cantidad
	
	DECLARE cur_fn_lacs CURSOR FOR
		SELECT
			ice.idcapa
			, ice.existencia
			, ice.costo
			, ic.fecha_caducidad
		FROM
			ew_inv_capas_existencia AS ice
			LEFT JOIN ew_inv_capas As ic
				ON ic.idcapa = ice.idcapa
		WHERE
			ice.idalmacen = @idalmacen
			AND ic.idarticulo = @idarticulo
			AND ic.lote = @lote
			AND ice.existencia > 0
		ORDER BY
			ice.existencia DESC

	OPEN cur_fn_lacs
	
	FETCH NEXT FROM cur_fn_lacs INTO
		@idcapa
		, @existencia
		, @valor
		, @fecha_caducidad

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @cantidad2 <= 0
		BEGIN
			BREAK
		END

		IF @existencia <= @cantidad2
		BEGIN
			SELECT @x = @existencia
			SELECT @costo = @valor
		END
			ELSE
		BEGIN
			SELECT @x = @cantidad2
			SELECT @costo = ROUND((@cantidad2 * @valor) / @existencia, 2)
		END

		INSERT INTO @tb_lotes (
			idcapa
			, cantidad
			, costo
			, fecha_caducidad
		)
		VALUES (
			@idcapa
			, @x
			, @costo
			, @fecha_caducidad
		)

		SELECT @cantidad2 = @cantidad2 - @x

		FETCH NEXT FROM cur_fn_lacs INTO
			@idcapa
			, @existencia
			, @valor
			, @fecha_caducidad
	END

	CLOSE cur_fn_lacs
	DEALLOCATE cur_fn_lacs

	IF @cantidad2 > 0
	BEGIN
		DELETE FROM @tb_lotes
	END

	RETURN
END
GO
