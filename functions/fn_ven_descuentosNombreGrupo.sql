USE db_comercial_final
GO
IF OBJECT_ID('fn_ven_descuentosNombreGrupo') IS NOT NULL
BEGIN
	DROP FUNCTION fn_ven_descuentosNombreGrupo
END
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 20080101
-- Description:	Regresar el nombre del elemento segun el grupo, para utilizarse en los descuentos
-- =============================================
CREATE FUNCTION [dbo].[fn_ven_descuentosNombreGrupo] (
	@grupo AS SMALLINT
	, @codigo AS VARCHAR(20)
)
RETURNS VARCHAR(150) AS  
BEGIN 
	DECLARE 
		@nombre AS VARCHAR(150)

	-- Grupo = 1 Significa que es un artículo
	IF @grupo = 1
	BEGIN
		SELECT 
			@nombre = nombre 
		FROM 
			ew_articulos 
		WHERE 
			codigo = @codigo
	END

	-- Grupo = 1 a 4 Significa cada nivel de clasificacion de los artículos
	IF @grupo IN (2,3,4)
	BEGIN
		SELECT 
			@nombre = (
				ISNULL(anss.nombre + '>>', '')
				+ ISNULL(ans.nombre + '>>', '')
				+ an.nombre
			)
		FROM 
			ew_articulos_niveles AS an
			LEFT JOIN ew_articulos_niveles AS ans
				ON ans.nivel = an.nivel - 1
				AND ans.codigo = an.codigo_superior
			LEFT JOIN ew_articulos_niveles AS anss
				ON anss.nivel = an.nivel - 2
				AND anss.codigo = ISNULL(an.codigo_superior, '')
		WHERE 
			an.nivel = @grupo
			AND an.codigo = @codigo
	END

	-- Cualquier otro valor dado al grupo
	SELECT @nombre = ISNULL(@nombre, 'Todos...')

	RETURN (@nombre)
END
GO
