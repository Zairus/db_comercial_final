USE db_comercial_final
GO
ALTER PROCEDURE [dbo].[_ven_prc_descuentosBuscarArticulo]
	@tipo AS TINYINT = 1
	,@codigo AS VARCHAR(50)
AS

SET NOCOUNT ON

IF @tipo IN (1,2,3)
BEGIN
	SELECT @codigo='%' + @codigo + '%'
	
	-- Buscando articulos
	IF @tipo=1
	BEGIN
		SELECT codigo = a.codigo, nombre = a.nombre
		FROM ew_articulos a
		WHERE 
			a.codigo LIKE @codigo
			OR a.nombre LIKE @codigo
		RETURN
	END
	
	-- Buscando Lineas
	IF @tipo=2
	BEGIN
		SELECT 
			codigo, nombre
		FROM 
			ew_articulos_niveles 
		WHERE 
			nivel=2
		ORDER BY nombre
		RETURN
	END

	-- Buscando Sublineas
	IF @tipo=3
	BEGIN
		SELECT 
			codigo, nombre
		FROM 
			ew_articulos_niveles 
		WHERE 
			nivel=3
		ORDER BY nombre
		RETURN
	 END

END
ELSE
BEGIN
	-- cuando el tipo no se programa, no regresa ningun valor
	SELECT TOP 0 codigo=codigo, nombre FROM ew_articulos
END
GO
