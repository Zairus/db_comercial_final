USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190130
-- Description:	Regresa la relevancia entre el termino aguja y termino pajar
-- =============================================
ALTER FUNCTION [dbo].[_sys_fnc_busquedaPorRelevancia]
(
	@termino_pajar AS VARCHAR(MAX)
	, @termino_aguja AS VARCHAR(MAX)
)
RETURNS INT
AS
BEGIN
	DECLARE
		@relevancia AS INT
	
	DECLARE @tb_pajar AS TABLE (
		idr INT
		, palabra VARCHAR(MAX)
	)

	DECLARE @tb_aguja AS TABLE (
		idr INT
		, palabra VARCHAR(MAX)
	)

	INSERT INTO @tb_pajar (idr, palabra)
	SELECT idr, valor FROM [dbo].[_sys_fnc_separarMultilinea] (@termino_pajar, ' ')

	INSERT INTO @tb_aguja (idr, palabra)
	SELECT idr, valor FROM [dbo].[_sys_fnc_separarMultilinea] (@termino_aguja, ' ')

	SELECT
		@relevancia = SUM(rel.r)
	FROM (
		SELECT
			[r] = (SELECT COUNT(*) FROM @tb_pajar AS tp WHERE tp.palabra = ta.palabra)
		FROM
			@tb_aguja AS ta
	) AS rel

	SELECT @relevancia = ISNULL(@relevancia, 0)

	RETURN @relevancia
END
GO
