USE db_comercial_final
GO
IF OBJECT_ID('_inv_prc_capasCrear') IS NOT NULL
BEGIN
	DROP PROCEDURE _inv_prc_capasCrear
END
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: yyyymmdd
-- Description:	Crear capas
-- =============================================
CREATE PROCEDURE [dbo].[_inv_prc_capasCrear]
	@idcapa AS BIGINT OUTPUT
	, @idtran As INT
	, @referencia AS VARCHAR(25)
	, @fecha AS SMALLDATETIME
	, @idarticulo INT
	, @serie AS VARCHAR(25)
	, @cantidad As DECIMAL(15,4)
	, @costo AS DECIMAL(15,4)
	, @costo2 AS DECIMAL(15,4)
	, @lote AS VARCHAR(25) = ''
	, @fecha_caducidad AS SMALLDATETIME
	, @comentario AS VARCHAR(1000) = ''
AS

SET NOCOUNT ON

DECLARE 
	@msg AS VARCHAR(100)
	, @series AS BIT
	, @existencia AS DECIMAL(15,4)
	, @lotes AS BIT
	
DECLARE
	@idequipo AS INT

IF @idtran IS NULL
BEGIN
	RAISERROR('Error: No se pudo encontrar registro de transacción.', 16, 1)
	RETURN
END

SELECT 
	@series = series 
	, @lotes = lotes
FROM 
	ew_articulos 
WHERE 
	idarticulo = @idarticulo

SELECT @idcapa = NULL

IF @series = 1 
BEGIN
	-- Validamos que la cantidad sea solo la unidad
	IF @cantidad != 1
	BEGIN
		SELECT @msg = 'La cantidad permitida para capas con numero de serie, es de 1.'

		RAISERROR(@msg, 16, 1)
		RETURN
	END
	
	-- Buscamos si el numero de serie ya existe para el articulo, y si no se encuentra en el sistema (existencia=0)
	SELECT 
		@idcapa = idcapa
		, @existencia = ISNULL(c.existencia, 0)
	FROM
		ew_inv_capas AS c
	WHERE
		c.idarticulo = @idarticulo
		AND c.serie = @serie

	IF @idcapa > 0 AND @existencia > 0
	BEGIN
		SELECT @msg = 'Error. Numero de Serie Duplicado ' + @serie

		RAISERROR(@msg,16,1)
		RETURN
	END
END

IF @idcapa IS NULL
BEGIN
	IF @lotes = 1 AND RTRIM(ISNULL(@lote, '')) = ''
	BEGIN
		SELECT @msg='Error. Se requiere especificar el No. de Lote para el artículo ' + CONVERT(VARCHAR(8),@idarticulo)

		RAISERROR(@msg,16,1)
		RETURN		
	END

	INSERT INTO ew_inv_capas (
		idtran
		, referencia
		, fecha
		, idarticulo
		, serie
		, cantidad
		, costo
		, costo2
		, lote
		, fecha_caducidad
		, comentario
	)
	SELECT
		[idtran] = @idtran
		, [referencia] = @referencia
		, [fecha] = @fecha
		, [idarticulo] = @idarticulo
		, [serie] = @serie
		, [cantidad] = @cantidad
		, [costo] = @costo
		, [costo2] = @costo2
		, [lote] = @lote
		, [fecha_caducidad] = @fecha_caducidad
		, [comentario] = @comentario

	SELECT @idcapa = SCOPE_IDENTITY()

	IF LEN(@serie) > 0
	BEGIN
		SELECT @idequipo = MAX(idequipo) FROM ew_ser_equipos
		SELECT @idequipo = ISNULL(@idequipo, 0) + 1

		-- Al insertar en ew_ser_equipos verifica que exista capa con la serie
		INSERT INTO ew_ser_equipos (
			idequipo
			, serie
			, idarticulo
			, activo
			, idsucursal1
			, idsucursal2
			, idsucursal3
		)
		SELECT
			@idequipo
			, @serie
			, @idarticulo
			, [activo] = 1
			, [idsucursal1] = 1
			, [idsucursal2] = 1
			, [idsucursal3] = 1
		WHERE
			(
				SELECT COUNT(*) 
				FROM 
					ew_ser_equipos AS se 
				WHERE 
					se.serie = @serie
			) = 0
	END
END
GO
