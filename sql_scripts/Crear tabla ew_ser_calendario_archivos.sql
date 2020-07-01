USE db_comercial_final
GO
IF OBJECT_ID('ew_ser_calendario_archivos') IS NOT NULL
BEGIN
	DROP TABLE ew_ser_calendario_archivos
END
GO
CREATE TABLE ew_ser_calendario_archivos (
	idr INT IDENTITY
	, idevento INT NOT NULL
	, archivo_uid VARCHAR(36) NOT NULL
	, nombre VARCHAR(1000) NOT NULL
	, tamano INT NOT NULL DEFAULT 0
	, extension VARCHAR(10) NOT NULL DEFAULT ''
	, ruta VARCHAR(1000) NOT NULL DEFAULT ''
	, icono VARCHAR(100) NOT NULL DEFAULT ''
	, fecha_hora DATETIME NOT NULL DEFAULT GETDATE()

	, CONSTRAINT [PK_ew_ser_calendario_archivos] PRIMARY KEY CLUSTERED (
		idevento ASC
		, archivo_uid ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO
