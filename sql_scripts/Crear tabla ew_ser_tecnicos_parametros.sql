USE db_comercial_final
GO
IF OBJECT_ID('ew_ser_tecnicos_parametros') IS NOT NULL
BEGIN
	DROP TABLE ew_ser_tecnicos_parametros
END
GO
CREATE TABLE ew_ser_tecnicos_parametros (
	idr INT IDENTITY
	, codigo VARCHAR(20) NOT NULL
	, descripcion VARCHAR(200) NOT NULL DEFAULT ''
	, activo BIT NOT NULL DEFAULT 1
	, tipo INT NOT NULL DEFAULT 0
	, valor DECIMAL(18,6) NOT NULL DEFAULT 0

	, CONSTRAINT [PK_ew_ser_tecnicos_parametros] PRIMARY KEY CLUSTERED (
		codigo ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO
SELECT * FROM ew_ser_tecnicos_parametros
