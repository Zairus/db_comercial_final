USE db_comercial_final
GO
IF OBJECT_ID('_ven_prc_descuentosBuscarArticulo') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_prc_descuentosBuscarArticulo
END
GO
CREATE PROCEDURE [dbo].[_ven_prc_descuentosBuscarArticulo]
	@tipo AS TINYINT = 1
	, @codigo AS VARCHAR(50)
AS

SET NOCOUNT ON

IF @tipo IN (1,2,3)
BEGIN
	SELECT @codigo = '%' + @codigo + '%'
	
	-- Buscando articulos
	IF @tipo = 1
	BEGIN
		SELECT 
			[codigo] = a.codigo
			, [nombre] = a.nombre
		FROM 
			ew_articulos AS a
		WHERE 
			a.codigo LIKE @codigo
			OR a.nombre LIKE @codigo

		RETURN
	END
	
	-- Buscando Lineas
	IF @tipo=2
	BEGIN
		SELECT 
			[codigo] = anl.codigo
			, [nombre] = anf.nombre + '>>' + anl.nombre
		FROM 
			ew_articulos_niveles AS anl
			LEFT JOIN ew_articulos_niveles AS anf
				ON anf.nivel = 1
				AND anf.codigo = anl.codigo_superior
		WHERE 
			anl.nivel = 2
		ORDER BY 
			anf.orden
			, anl.orden
			, anf.nombre
			, anl.nombre
			
		RETURN
	END

	-- Buscando Sublineas
	IF @tipo = 3
	BEGIN
		SELECT 
			[codigo] = ansl.codigo
			, [nombre] = anf.nombre + '>>' + anl.nombre + '>>' + ansl.nombre
		FROM 
			ew_articulos_niveles AS ansl
			LEFT JOIN ew_articulos_niveles AS anl
				ON anl.nivel = 2
				AND anl.codigo = ansl.codigo_superior
			LEFT JOIN ew_articulos_niveles AS anf
				ON anf.nivel = 1
				AND anf.codigo = anl.codigo_superior
		WHERE 
			ansl.nivel = 3
		ORDER BY 
			anf.orden
			, anl.orden
			, ansl.orden
			, anf.nombre
			, anl.nombre
			, ansl.nombre

		RETURN
	 END
END
	ELSE
BEGIN
	-- cuando el tipo no se programa, no regresa ningun valor
	SELECT TOP 0 
		[codigo] = codigo
		, [nombre] = nombre
	FROM 
		ew_articulos
END
GO
