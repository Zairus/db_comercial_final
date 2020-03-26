USE db_comercial_final
GO
IF OBJECT_ID('ew_ser_calendario') IS NOT NULL
BEGIN
	DROP TABLE ew_ser_calendario
END
GO
CREATE TABLE ew_ser_calendario (
	idr INT IDENTITY
	, idevento INT NOT NULL
	, referencia VARCHAR(200) NOT NULL DEFAULT ''
	, idcliente INT NOT NULL DEFAULT 0
	, fecha_inicial DATETIME
	, fecha_final DATETIME
	, dia_completo BIT NOT NULL DEFAULT 0

	, idtecnico_ordenante INT NOT NULL DEFAULT 0
	, idtecnico_receptor INT NOT NULL DEFAULT 0

	, familia_codigo VARCHAR(4) NOT NULL DEFAULT ''

	, comentario VARCHAR(4000) NOT NULL DEFAULT ''

	, CONSTRAINT [PK_ew_ser_calendario] PRIMARY KEY CLUSTERED (
		idevento
	) ON [PRIMARY]
) ON [PRIMARY]
GO
SELECT * FROM ew_ser_calendario