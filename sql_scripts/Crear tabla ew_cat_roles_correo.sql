USE db_comercial_final
GO
IF OBJECT_ID('ew_cat_roles_correo') IS NOT NULL
BEGIN
	DROP TABLE ew_cat_roles_correo
END
GO
CREATE TABLE ew_cat_roles_correo (
	idr INT IDENTITY
	, idrol INT NOT NULL
	, idserver INT NOT NULL
	, objeto INT NOT NULL DEFAULT 0

	, CONSTRAINT [PK_ew_cat_roles_correo] PRIMARY KEY CLUSTERED (
		idrol ASC
		, idserver ASC
		, objeto ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO
