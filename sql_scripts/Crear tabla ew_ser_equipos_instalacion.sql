USE db_comercial_final
GO
IF OBJECT_ID('ew_ser_equipos_instalacion') IS NOT NULL
BEGIN
	DROP TABLE ew_ser_equipos_instalacion
END
GO
CREATE TABLE ew_ser_equipos_instalacion (
	idr INT IDENTITY
	, idequipo INT NOT NULL
	, observacion VARCHAR(200) NOT NULL DEFAULT ''

	, CONSTRAINT [PK_ew_ser_equipos_instalacion] PRIMARY KEY CLUSTERED (
		idr ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO
