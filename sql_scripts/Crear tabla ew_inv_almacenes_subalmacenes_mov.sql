USE db_comercial_final
GO
IF OBJECT_ID('ew_inv_almacenes_subalmacenes_mov') IS NOT NULL
BEGIN
	DROP TABLE ew_inv_almacenes_subalmacenes_mov
END
GO
CREATE TABLE ew_inv_almacenes_subalmacenes_mov (
	idr INT IDENTITY
	, idsubalmacen INT NOT NULL
	, idarticulo INT NOT NULL
	, cantidad DECIMAL(18,6) NOT NULL DEFAULT 0

	, CONSTRAINT [PK_ew_inv_almacenes_subalmacenes_mov] PRIMARY KEY CLUSTERED (
		idsubalmacen
		, idarticulo
	) ON [PRIMARY]
) ON [PRIMARY]
GO
