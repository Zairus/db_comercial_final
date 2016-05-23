USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091102
-- Description:	Insertar registros en ew_articulos_almacenes
-- =============================================
ALTER TRIGGER [dbo].[tg_inv_almacenes_i]
	ON [dbo].[ew_inv_almacenes]
	FOR INSERT
AS 

SET NOCOUNT ON

INSERT INTO ew_articulos_almacenes (
	idarticulo
	,idalmacen
)
SELECT
	a.idarticulo
	,alm.idalmacen
FROM 
	inserted AS alm
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = a.idarticulo
WHERE
	a.idarticulo IS NOT NULL
GO
