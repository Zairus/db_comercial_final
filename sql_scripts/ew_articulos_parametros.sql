USE db_comercial_final
GO
IF OBJECT_ID('ew_articulos_parametros') IS NOT NULL
BEGIN
	DROP TABLE ew_articulos_parametros
END
GO
CREATE TABLE ew_articulos_parametros (
	idr INT IDENTITY
	, idarticulo INT NOT NULL
	, tipo_dato INT NOT NULL
	, valor VARCHAR(20) NOT NULL

	, CONSTRAINT [PK_ew_articulos_parametros] PRIMARY KEY CLUSTERED (
		idarticulo
		, tipo_dato
	) ON [PRIMARY]
) ON [PRIMARY]
GO
