USE db_comercial_final

IF ObJECT_ID('ew_articulos_datos') IS NOT NULL
BEGIN
	DROP TABLE ew_articulos_datos
END

CREATE TABLE ew_articulos_datos (
	idr INT IDENTITY
	,idarticulo INT NOT NULL
	,iddato INT NOT NULL
	,orden INT NOT NULL DEFAULT 0
	,obligatorio BIT NOT NULL DEFAULT 0
	,CONSTRAINT [PK_ew_articulos_datos] PRIMARY KEY CLUSTERED (
		[idarticulo] ASC
		,[iddato] ASC
	) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

SELECT * FROM ew_articulos_datos
