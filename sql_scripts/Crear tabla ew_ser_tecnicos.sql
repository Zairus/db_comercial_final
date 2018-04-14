USE db_comercial_final
GO
IF OBJECT_ID('ew_ser_tecnicos') IS NOT NULL
BEGIN
	DROP TABLE ew_ser_tecnicos
END
GO
CREATE TABLE ew_ser_tecnicos (
	idr INT IDENTITY
	, idtecnico INT
	, codigo VARCHAR(30) NOT NULL
	, nombre VARCHAR(512) NOT NULL DEFAULT ''
	, evaluacion BIT NOT NULL DEFAULT 1
	, telefono1 VARCHAR(50) NOT NULL DEFAULT ''
	, telefono2 VARCHAR(50) NOT NULL DEFAULT ''
	, correo_electronico VARCHAR(150) NOT NULL DEFAULT ''
	, porcentaje1 DECIMAL(18,6) NOT NULL DEFAULT 0
	, porcentaje2 DECIMAL(18,6) NOT NULL DEFAULT 0
	, porcentaje3 DECIMAL(18,6) NOT NULL DEFAULT 0
	, idzona INT NOT NULL DEFAULT 0
	, idsubalmacen INT NOT NULL DEFAULT 0
	, idu INT NOT NULL DEFAULT 0
	, comentario TEXT NOT NULL DEFAULT ''

	,CONSTRAINT [PK_ew_ser_tecnicos] PRIMARY KEY CLUSTERED (
		[idtecnico] ASC
	) ON [PRIMARY]
	,CONSTRAINT [UK_ew_ser_tecnicos_codigo] UNIQUE (
		[codigo] ASC
	)
) ON [PRIMARY]
GO
