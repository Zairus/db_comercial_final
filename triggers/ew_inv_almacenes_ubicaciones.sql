USE db_aguate_datos
GO
IF OBJECT_ID('ew_inv_almacenes_ubicaciones') IS NOT NULL
BEGIN
	DROP TABLE ew_inv_almacenes_ubicaciones
END
GO
CREATE TABLE ew_inv_almacenes_ubicaciones (
	idr INT IDENTITY
	, idalmacen INT NOT NULL
	, codigo VARCHAR(20) NOT NULL
	, area VARCHAR(200) NOT NULL DEFAULT ''
	, seccion VARCHAR(200) NOT NULL DEFAULT ''
	, comentario VARCHAR(1000) NOT NULL DEFAULT ''

	, CONSTRAINT [PK_ew_inv_almacenes_ubicaciones] PRIMARY KEY CLUSTERED (
		idalmacen ASC
		, codigo ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO
