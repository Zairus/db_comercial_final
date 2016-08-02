USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160630
-- Description:	Validar ultimo costo
-- =============================================
ALTER PROCEDURE [dbo].[_inv_prc_ultimoCostoValidar]
	@idarticulo AS INT
	,@idalmacen AS INT
	,@costo AS DECIMAL(18,6)
AS

SET NOCOUNT ON

DECLARE
	@costo_ultimo AS DECIMAL(18,6)
	,@diferencia AS DECIMAL(18,6)
	,@variacion AS DECIMAL(18,6)
	,@error_mensaje AS VARCHAR(500)

SELECT
	@costo_ultimo = costo_ultimo
FROM
	ew_articulos_almacenes AS aa
WHERE
	aa.idarticulo = @idarticulo
	AND aa.idalmacen = @idalmacen

SELECT @costo_ultimo = ISNULL(@costo_ultimo, 0)

SELECT @diferencia = ABS(@costo_ultimo - @costo)

SELECT 
	@variacion = CONVERT(DECIMAL(18,6), valor) / 100
FROM 
	objetos_datos 
WHERE 
	grupo = 'GLOBAL' 
	AND codigo = 'PORC_VARIACION_COSTO'

IF (@costo_ultimo > 0)
BEGIN
	IF (@diferencia / @costo_ultimo) > @variacion
	BEGIN
		SELECT @error_mensaje = (
			'Error: La diferencia en costos es mayor a '
			+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(12,2), @variacion * 100)) + ' porc.'
			+' Ultimo costo: ' + CONVERT(VARCHAR(20), @costo_ultimo) + '.'
			+' Costo ingresado: ' + CONVERT(VARCHAR(20), @costo) + '.'
			+' Variacion: ' + CONVERT(VARCHAR(20), CONVERT(DECIMAL(12,2), (@diferencia / @costo_ultimo) * 100)) + ' porc.'
		)

		RAISERROR(@error_mensaje, 16, 1)
		RETURN
	END
END
GO
