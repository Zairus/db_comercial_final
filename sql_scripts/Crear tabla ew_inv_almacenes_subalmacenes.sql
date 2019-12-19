USE db_comercial_final
GO
IF OBJECT_ID('ew_inv_almacenes_subalmacenes') IS NOT NULL
BEGIN
	DROP TABLE ew_inv_almacenes_subalmacenes
END
GO
CREATE TABLE ew_inv_almacenes_subalmacenes (
	idr INT IDENTITY
	, idsubalmacen INT NOT NULL
	, idalmacen INT NOT NULL
	, nombre VARCHAR(50) NOT NULL DEFAULT ''
	, idu INT NOT NULL DEFAULT 0

	, CONSTRAINT [PK_ew_inv_almacenes_subalmacenes] PRIMARY KEY CLUSTERED (
		idsubalmacen ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO
SELECT * FROM ew_inv_almacenes_subalmacenes