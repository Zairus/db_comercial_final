USE db_comercial_final
GO
IF OBJECT_ID('ew_ser_planes_tipos') IS NOT NULL
BEGIN
	DROP TABLE ew_ser_planes_tipos
END
GO
CREATE TABLE ew_ser_planes_tipos (
	idr INT IDENTITY
	, idtipoplan INT NOT NULL
	, nombre VARCHAR(100) NOT NULL DEFAULT ''
	, facturar BIT NOT NULL DEFAULT 1

	, CONSTRAINT [PK_ew_ser_planes_tipos] PRIMARY KEY CLUSTERED (
		idtipoplan ASC
	) ON [PRIMARY]
	, CONSTRAINT [UK_ew_ser_planes_tipos_nombre] UNIQUE (
		nombre
	)
) ON [PRIMARY]
GO
INSERT INTO ew_ser_planes_tipos (idtipoplan, nombre, facturar) VALUES (1, 'ARRENDAMIENTO', 1)
INSERT INTO ew_ser_planes_tipos (idtipoplan, nombre, facturar) VALUES (2, 'CORTESIA', 0)
INSERT INTO ew_ser_planes_tipos (idtipoplan, nombre, facturar) VALUES (3, 'NOTA', 0)
GO
SELECT * FROM ew_ser_planes_tipos
