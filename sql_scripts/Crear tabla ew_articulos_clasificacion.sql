USE db_comercial_final

IF OBJECT_ID('ew_articulos_clasificacion') IS NOT NULL
BEGIN
	DROP TABLE ew_articulos_clasificacion
END

CREATE TABLE ew_articulos_clasificacion (
	idr INT IDENTITY
	,idarticulo INT NOT NULL
	,idclasificacion_superior INT NOT NULL
	,idclasificacion INT NOT NULL
	, CONSTRAINT [PK_ew_articulos_clasificacion] PRIMARY KEY CLUSTERED (
		[idarticulo] ASC
		,[idclasificacion] ASC
	)
) ON [PRIMARY]

SELECT * FROM ew_articulos_clasificacion
