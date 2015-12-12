USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20151203
-- Description:	Importar articulo
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_articuloImportar]
	@codigo AS VARCHAR(30)
	,@nombre AS VARCHAR(500)
	,@nombre_corto AS VARCHAR(100)
	,@idsucursal AS INT
	,@costo_base AS DECIMAL(18,6)
	,@precio1 AS DECIMAL(18,6)
	,@precio2 AS DECIMAL(18,6)
	,@precio3 AS DECIMAL(18,6)
	,@precio4 AS DECIMAL(18,6)
	,@precio5 AS DECIMAL(18,6)
AS

SET NOCOUNT ON

DECLARE
	@idarticulo AS INT

SELECT
	@idarticulo = a.idarticulo
FROM
	ew_articulos AS a
WHERE
	a.codigo = @codigo

IF @idarticulo IS NOT NULL
BEGIN
	UPDATE ew_articulos SET
		nombre = @nombre
		,nombre_corto = @nombre_corto
	WHERE
		idarticulo = @idarticulo
END
	ELSE
BEGIN
	SELECT
		@idarticulo = MAX(idarticulo)
	FROM
		ew_articulos

	SELECT @idarticulo = ISNULL(@idarticulo, 0) + 1

	INSERT INTO ew_articulos (
		idarticulo
		,codigo
		,nombre
		,nombre_corto
		,idtipo
		,inventariable
		,idimpuesto1
	)
	VALUES (
		@idarticulo
		,@codigo
		,@nombre
		,@nombre_corto
		,0
		,1
		,1
	)
END

UPDATE vlm SET
	vlm.costo_base = @costo_base
FROM
	ew_articulos AS a
	LEFT JOIN ew_ven_listaprecios_mov AS vlm
		ON vlm.idarticulo = a.idarticulo
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idlista = vlm.idlista
WHERE
	s.idsucursal = @idsucursal
	AND a.codigo = @codigo

UPDATE vlm SET
	vlm.precio_neto = @precio1
	,vlm.precio_neto2 = @precio2
	,vlm.precio_neto3 = @precio3
	,vlm.precio_neto4 = @precio4
	,vlm.precio_neto5 = @precio5
FROM
	ew_articulos AS a
	LEFT JOIN ew_ven_listaprecios_mov AS vlm
		ON vlm.idarticulo = a.idarticulo
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idlista = vlm.idlista
WHERE
	s.idsucursal = @idsucursal
	AND a.codigo = @codigo

SELECT
	a.codigo
	,a.idarticulo
	,[importado] = 'Si'
	,a.nombre
	,a.nombre_corto

	,[costo_base] = vlm.costo_base
	,[precio_neto1] = vlm.precio_neto
	,[precio_neto2] = vlm.precio_neto2
	,[precio_neto3] = vlm.precio_neto3
	,[precio_neto4] = vlm.precio_neto4
	,[precio_neto5] = vlm.precio_neto5
FROM
	ew_articulos AS a
	LEFT JOIN ew_ven_listaprecios_mov AS vlm
		ON vlm.idarticulo = a.idarticulo
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idlista = vlm.idlista
WHERE
	a.codigo = @codigo
	AND s.idsucursal = @idsucursal

DELETE FROM ew_ven_listaprecios_carga WHERE codigo = @codigo AND idsucursal = @idsucursal
GO