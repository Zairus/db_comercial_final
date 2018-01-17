USE db_comercial_final
GO
-- =============================================
-- Author:		Arvin Valenzuela
-- Create date: 2010 JUL
-- Description:	Actualizar registros de ew_articulos_unidades
-- =============================================
ALTER TRIGGER [dbo].[tg_articulos_u]
	ON [dbo].[ew_articulos]
	FOR UPDATE
AS 

SET NOCOUNT ON

-- Insertamos las unidades de medida selecionadas si es que no existen.
INSERT INTO ew_articulos_unidades (
	idarticulo
	, idum
)
SELECT DISTINCT 
	idarticulo
	, idum	
FROM (
	SELECT
		idarticulo
		, idum = idum_almacen
	FROM 
		inserted 
	WHERE 
		ISNULL(idum_almacen,-1) > -1

	UNION ALL

	SELECT 
		idarticulo
		, idum = idum_compra
	FROM 
		inserted 
	WHERE 
		ISNULL(idum_compra,-1) > -1

	UNION ALL

	SELECT 
		idarticulo
		, idum = idum_venta
	FROM 
		inserted 
	WHERE 
		ISNULL(idum_venta,-1) > -1
) AS art_uni
WHERE 
	idum NOT IN (
		SELECT idum
		FROM ew_articulos_unidades
		WHERE 
			idarticulo IN (
				SELECT idarticulo 
				FROM inserted
			)
	)

IF UPDATE(series) OR UPDATE(lotes)
BEGIN
	IF EXISTS(
		SELECT *
		FROM
			ew_inv_transacciones_mov AS itm
		WHERE
			itm.idarticulo IN (
				SELECT i.idarticulo 
				FROM inserted AS i
			)
	)
	BEGIN
		RAISERROR('Error: No se pueden actualizar los siguientes parametros para productos con movimientos de inventario: Maneja Series, Maneja Lotes', 16, 1)
		RETURN
	END
END

IF UPDATE(inventariable)
BEGIN
	IF EXISTS(
		SELECT *
		FROM
			ew_ven_transacciones_mov AS vtm
		WHERE
			vtm.idarticulo IN (
				SELECT i.idarticulo 
				FROM inserted AS i
			)
	)
	BEGIN
		RAISERROR('Error: No se puede modificar le parametro Inventariable a productos que hayan tenido movimientos en ventas.', 16, 1)
		RETURN
	END

	IF EXISTS(
		SELECT *
		FROM
			ew_com_transacciones_mov AS ctm
		WHERE
			ctm.idarticulo IN (
				SELECT i.idarticulo 
				FROM inserted AS i
			)
	)
	BEGIN
		RAISERROR('Error: No se puede modificar le parametro Inventariable a productos que hayan tenido movimientos en compras.', 16, 1)
		RETURN
	END

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
		AND NOT EXISTS (
			SELECT idarticulo 
			FROM ew_articulos_almacenes 
			WHERE 
				idarticulo = a.idarticulo 
				AND idalmacen = alm.idalmacen
		)
END
GO
