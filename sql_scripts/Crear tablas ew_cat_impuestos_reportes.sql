USE db_comercial_final
GO
IF OBJECT_ID('ew_cat_impuestos_reportes') IS NOT NULL
BEGIN
	DROP TABLE ew_cat_impuestos_reportes
END
GO
CREATE TABLE ew_cat_impuestos_reportes (
	idr INT IDENTITY
	, idreporte INT NOT NULL
	, codigo VARCHAR(10) NOT NULL
	, nombre VARCHAR(200) NOT NULL DEFAULT ''
	, idimpuesto INT NOT NULL
	, comentario TEXT NOT NULL DEFAULT ''

	, CONSTRAINT [PK_ew_cat_impuestos_reportes] PRIMARY KEY CLUSTERED (
		idreporte ASC
	) ON [PRIMARY]
	, CONSTRAINT [UK_ew_cat_impuestos_reportes_codigo] UNIQUE (
		codigo ASC
	)
) ON [PRIMARY]
GO
IF OBJECT_ID('ew_cat_impuestos_reportes_cuentas') IS NOT NULL
BEGIN
	DROP TABLE ew_cat_impuestos_reportes_cuentas
END
GO
CREATE TABLE ew_cat_impuestos_reportes_cuentas (
	idr INT IDENTITY
	, idreporte INT NOT NULL
	, cuenta VARCHAR(20) NOT NULL
	, orden INT NOT NULL DEFAULT 0
	, restar BIT NOT NULL DEFAULT 0

	, CONSTRAINT [PK_ew_cat_impuestos_reportes_cuentas] PRIMARY KEY CLUSTERED (
		idreporte ASC
		, cuenta ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO
