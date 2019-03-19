USE db_comercial_final
GO
IF OBJECT_ID('ew_ser_labor_costo') IS NOT NULL
BEGIN
	DROP TABLE ew_ser_labor_costo
END
GO
CREATE TABLE ew_ser_labor_costo (
	idr INT IDENTITY
	, idlabor INT NOT NULL
	, codigo VARCHAR(10) NOT NULL
	, nombre VARCHAR(200) NOT NULL DEFAULT ''
	, costo DECIMAL(18,6) NOT NULL DEFAULT 0
	, comentario VARCHAR(1000) NOT NULL DEFAULT ''

	, CONSTRAINT [PK_ew_ser_labor_costo] PRIMARY KEY CLUSTERED (
		idlabor
	) ON [PRIMARY]
	, CONSTRAINT [UK_ew_ser_labor_costo_codigo] UNIQUE (
		codigo
	)
) ON [PRIMARY]
GO
