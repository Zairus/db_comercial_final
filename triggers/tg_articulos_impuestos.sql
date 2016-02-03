USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160202
-- Description:	Agregar informacion de impuestos
-- =============================================
ALTER TRIGGER tg_articulos_impuestos
	ON ew_articulos
	FOR INSERT, UPDATE
AS 

SET NOCOUNT ON

DECLARE
	@idarticulo AS INT

DECLARE cur_art_impuestos CURSOR FOR
	SELECT
		idarticulo
	FROM
		inserted

OPEN cur_art_impuestos

FETCH NEXT FROM cur_art_impuestos INTO
	@idarticulo

WHILE @@FETCH_STATUS = 0
BEGIN
	IF NOT EXISTS(
		SELECT *
		FROM
			ew_articulos_impuestos_tasas AS ait
		WHERE
			ait.idarticulo = @idarticulo
	)
	BEGIN
		INSERT INTO ew_articulos_impuestos_tasas (
			idarticulo
			,idtasa
		)
		VALUES (
			@idarticulo
			,6
		)
	END

	FETCH NEXT FROM cur_art_impuestos INTO
		@idarticulo
END

CLOSE cur_art_impuestos
DEALLOCATE cur_art_impuestos
GO
