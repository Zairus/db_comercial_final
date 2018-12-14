USE db_comercial_final
GO
IF OBJECT_ID('ew_ser_equipos_bitacora') IS NOT NULL
BEGIN
	DROP TABLE ew_ser_equipos_bitacora
END
GO
CREATE TABLE ew_ser_equipos_bitacora (
	idr INT IDENTITY
	, idequipo INT NOT NULL
	, idestado INT NOT NULL
	, idaccion INT NOT NULL
	, fecha_hora DATETIME NOT NULL DEFAULT GETDATE()

	, idcliente INT NOT NULL DEFAULT 0
	, plan_codigo VARCHAR(10) NOT NULL DEFAULT ''

	, CONSTRAINT [PK_ew_ser_equipos_bitacora] PRIMARY KEY CLUSTERED (
		idequipo ASC
		, idestado ASC
		, idaccion ASC
		, fecha_hora ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO
