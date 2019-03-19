USE db_comercial_final
GO
IF OBJECT_ID('ew_cat_usuarios_correo') IS NOT NULL
BEGIN
	DROP TABLE ew_cat_usuarios_correo
END
GO
CREATE TABLE ew_cat_usuarios_correo (
	idr INT IDENTITY
	, idu INT NOT NULL
	, idserver INT NOT NULL
	, objeto INT NOT NULL

	, CONSTRAINT [PK_ew_cat_usuarios_correo] PRIMARY KEY CLUSTERED (
		idu ASC
		, idserver ASC
		, objeto ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO
SELECT * FROM ew_cat_usuarios_correo
GO
