USE db_comercial_final

IF OBJECT_ID('ew_sys_clasificacion') IS NOT NULL
BEGIN
	DROP TABLE ew_sys_clasificacion
END

CREATE TABLE ew_sys_clasificacion (
	idr INT IDENTITY
	,idclasificacion INT NOT NULL DEFAULT 0
	,idclasificacion_superior INT NOT NULL DEFAULT 0
	,codigo VARCHAR(20) NOT NULL DEFAULT ''
	,nombre VARCHAR(200) NOT NULL DEFAULT ''
	,CONSTRAINT [PK_ew_sys_clasificacion] PRIMARY KEY CLUSTERED (
		[idclasificacion] ASC
	) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	,CONSTRAINT [UK_ew_sys_clasificacion_codigo] UNIQUE NONCLUSTERED (
		[idclasificacion_superior] ASC
		,[codigo] ASC
	) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

INSERT INTO ew_sys_clasificacion (idclasificacion, codigo, nombre) VALUES (1, 'MED01', 'TIPO MEDICAMENTO')

INSERT INTO ew_sys_clasificacion (idclasificacion, idclasificacion_superior, codigo, nombre) VALUES (2, 1, 'MGEN', 'Generales')
INSERT INTO ew_sys_clasificacion (idclasificacion, idclasificacion_superior, codigo, nombre) VALUES (3, 1, 'MANT', 'Antibióticos')
INSERT INTO ew_sys_clasificacion (idclasificacion, idclasificacion_superior, codigo, nombre) VALUES (4, 1, 'MSCT', 'Semi-Controlados')
INSERT INTO ew_sys_clasificacion (idclasificacion, idclasificacion_superior, codigo, nombre) VALUES (5, 1, 'MCTR', 'Controlados')

SELECT * FROM ew_sys_clasificacion
