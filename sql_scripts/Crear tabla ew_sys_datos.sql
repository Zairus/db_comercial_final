USE db_comercial_final

IF OBJECT_ID('ew_sys_datos') IS NOT NULL
BEGIN
	DROP TABLE ew_sys_datos
END

CREATE TABLE ew_sys_datos (
	idr INT IDENTITY
	,iddato INT NOT NULL
	,codigo VARCHAR(20) NOT NULL DEFAULT ''
	,[nombre] VARCHAR(100) NOT NULL DEFAULT ''
	, CONSTRAINT [PK_ew_sys_datos] PRIMARY KEY CLUSTERED (
		[iddato] ASC
	) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	, CONSTRAINT [UK_ew_sys_datos_codigo] UNIQUE NONCLUSTERED (
		[codigo] ASC
	) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

INSERT INTO ew_sys_datos (iddato, codigo, nombre) VALUES (1, 'MCEP', 'Médico: Cédula Profesional')
INSERT INTO ew_sys_datos (iddato, codigo, nombre) VALUES (2, 'MNOM', 'Médico: Nombre')
INSERT INTO ew_sys_datos (iddato, codigo, nombre) VALUES (3, 'MDIR', 'Médico: Dirección consultorio')
INSERT INTO ew_sys_datos (iddato, codigo, nombre) VALUES (4, 'MSSP', 'Médico: Reg. SSP')
INSERT INTO ew_sys_datos (iddato, codigo, nombre) VALUES (5, 'MPAC', 'Médico: Nombre Paciente')
INSERT INTO ew_sys_datos (iddato, codigo, nombre) VALUES (6, 'MFOL', 'Médico: Folio Receta')

SELECT * FROM ew_sys_datos
