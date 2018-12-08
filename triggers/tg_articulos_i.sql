USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091014
-- Description:	Agregar artículos
-- =============================================
ALTER TRIGGER [dbo].[tg_articulos_i]
	ON [dbo].[ew_articulos]
	FOR INSERT
AS 

SET NOCOUNT ON

DECLARE
	@mensaje VARCHAR(3000)
	, @codigo VARCHAR(30)
	, @nombre VARCHAR(50)
	, @idub SMALLINT
	, @idum_almacen SMALLINT
	, @idum_compra SMALLINT
	, @idum_venta SMALLINT
	, @idclasificacion_sat INT
	, @idtipo AS INT

SELECT 
	@codigo = RTRIM(LTRIM(codigo))
	, @nombre = RTRIM(LTRIM(nombre))
	, @idub = idub
	, @idum_almacen = idum_almacen
	, @idum_compra = idum_compra
	, @idum_venta = idum_venta
	, @idclasificacion_sat = idclasificacion_sat 
	, @idtipo = idtipo
FROM 
	inserted

IF LEN(@codigo) = 0
BEGIN
	SELECT @mensaje = 'Capture el Código de Artículo. Corrija e intente guardar de nuevo.'
	RAISERROR(@mensaje, 16, 1)
END

IF LEN(@nombre) = 0
BEGIN
	SELECT @mensaje = 'Capture el Nombre del Artículo. Corrija e intente guardar de nuevo.'
	RAISERROR(@mensaje, 16, 1)
END

IF @idclasificacion_sat = 0 AND @idtipo < 2
BEGIN
	SELECT @mensaje='Seleccione la ID Clasif. SAT. Corrija e intente guardar de nuevo.'
	RAISERROR(@mensaje, 16, 1)
END

-- Insertamos el articulo en las sucursales
INSERT INTO ew_articulos_sucursales (
	idarticulo
	, idsucursal
)
SELECT
	a.idarticulo
	, s.idsucursal
FROM 
	inserted AS a
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = s.idsucursal

-- Insertamos el articulo en los almacenes.
INSERT INTO ew_articulos_almacenes (
	idarticulo
	, idalmacen
	)
SELECT
	a.idarticulo
	, alm.idalmacen
FROM 
	inserted AS a
	LEFT JOIN ew_inv_almacenes AS alm 
		ON alm.idalmacen = alm.idalmacen
WHERE
	a.inventariable = 1
	
-- Insertamos las unidades de medida selecionadas si es que no existen.
INSERT INTO ew_articulos_unidades (
	idarticulo
	, idum
)
SELECT DISTINCT 
	idarticulo
	, idum	
FROM (
	SELECT 	idarticulo, idum = idum_almacen
	FROM inserted 
	WHERE ISNULL(idum_almacen,-1) > -1

	UNION ALL

	SELECT idarticulo, idum = idum_compra
	FROM inserted 
	WHERE ISNULL(idum_compra,-1) > -1

	UNION ALL

	SELECT idarticulo, idum = idum_venta
	FROM inserted 
	WHERE ISNULL(idum_venta,-1) > -1
) AS art_uni
WHERE 
	idum NOT IN (
		SELECT idum 
		FROM ew_articulos_Unidades 
		WHERE idarticulo IN (SELECT idarticulo FROM inserted )
	)

-- =============================================
-- Actualizar listas de precios automáticas
INSERT INTO ew_ven_listaprecios_mov (
	idlista
	, idarticulo
)
SELECT
	vlp.idlista
	, i.idarticulo
FROM 
	inserted AS i
	LEFT JOIN ew_ven_listaprecios AS vlp
		ON vlp.idlista = vlp.idlista
WHERE 
	vlp.automatica = 1
GO
