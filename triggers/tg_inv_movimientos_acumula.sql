USE db_comercial_final
GO
IF OBJECT_ID('tg_inv_movimientos_acumula') IS NOT NULL
BEGIN
	DROP TRIGGER tg_inv_movimientos_acumula
END
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[tg_inv_movimientos_acumula]
	ON [dbo].[ew_inv_movimientos]
	FOR INSERT
AS 

SET NOCOUNT ON

DECLARE
	@idarticulo AS INT
	, @idalmacen AS INT
	, @ejercicio AS INT
	, @periodo AS INT
	, @tipo AS SMALLINT
	, @cantidad AS DECIMAL(18,6)
	, @costo AS DECIMAL(18,6)

DECLARE cur_inv_acumular CURSOR FOR
	SELECT
		idarticulo
		, idalmacen
		, [ejercicio] = YEAR(fecha)
		, [periodo] = MONTH(fecha)
		, [tipo] = tipo
		, [cantidad] = cantidad
		, [costo] = costo
	FROM
		inserted AS i

OPEN cur_inv_acumular

FETCH NEXT FROM cur_inv_acumular INTO
	@idarticulo
	, @idalmacen
	, @ejercicio
	, @periodo
	, @tipo
	, @cantidad
	, @costo

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC [dbo].[_inv_prc_acumularSaldos] 
		@idarticulo
		, @idalmacen
		, @ejercicio
		, @periodo
		, @tipo
		, @cantidad
		, @costo

	FETCH NEXT FROM cur_inv_acumular INTO
		@idarticulo
		, @idalmacen
		, @ejercicio
		, @periodo
		, @tipo
		, @cantidad
		, @costo
END

CLOSE cur_inv_acumular
DEALLOCATE cur_inv_acumular
GO
