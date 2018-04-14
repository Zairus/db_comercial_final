USE db_comercial_final
GO
-- #### EQUIPOS
IF OBJECT_ID('ew_ser_equipos') IS NOT NULL
BEGIN
	DROP TABLE ew_ser_equipos
END
GO
CREATE TABLE ew_ser_equipos (
	idr INT IDENTITY
	, idequipo INT NOT NULL
	, serie VARCHAR(50) NOT NULL
	, idarticulo INT NOT NULL DEFAULT 0
	, activo BIT NOT NULL DEFAULT 1
	, idestado INT NOT NULL DEFAULT 0
	, idsucursal1 INT NOT NULL
	, idsucursal2 INT NOT NULL
	, idsucursal3 INT NOT NULL
	, comentario TEXT NOT NULL DEFAULT ''

	, CONSTRAINT [PK_ew_ser_equipos] PRIMARY KEY CLUSTERED (
		[idequipo] ASC
	) ON [PRIMARY]
	, CONSTRAINT [UK_ew_ser_equipos_serie] UNIQUE (
		[serie] ASC
	)
) ON [PRIMARY]
GO
SELECT * FROM ew_ser_equipos
GO
-- #### ESTADOS DE EQUIPO
IF OBJECT_ID('ew_ser_estados') IS NOT NULL
BEGIN
	DROP TABLE ew_ser_estados
END
GO
CREATE TABLE ew_ser_estados (
	idr INT IDENTITY
	, idestado INT NOT NULL
	, codigo VARCHAR(10) NOT NULL
	, nombre VARCHAR(250) NOT NULL DEFAULT ''
	, comentario TEXT NOT NULL DEFAULT ''

	, CONSTRAINT [PK_ew_ser_estados] PRIMARY KEY CLUSTERED (
		[idestado] ASC
	) ON [PRIMARY]
	, CONSTRAINT [UK_ew_ser_estados_codigo] UNIQUE (
		[codigo] ASC
	)
) ON [PRIMARY]
GO
INSERT INTO ew_ser_estados (idestado, codigo, nombre) VALUES (0, 'DISP', 'Disponible')
INSERT INTO ew_ser_estados (idestado, codigo, nombre) VALUES (1, 'RENT', 'Rentado')
INSERT INTO ew_ser_estados (idestado, codigo, nombre) VALUES (2, 'ROC', 'Renta Opcion Compra')
INSERT INTO ew_ser_estados (idestado, codigo, nombre) VALUES (3, 'POL', 'Poliza')
INSERT INTO ew_ser_estados (idestado, codigo, nombre) VALUES (4, 'VEN', 'Vendida')
INSERT INTO ew_ser_estados (idestado, codigo, nombre) VALUES (5, 'BAJ', 'Baja')
GO
SELECT * FROM ew_ser_estados
GO
-- #### RENDIMIENTOS
IF OBJECT_ID('ew_ser_rendimientos') IS NOT NULL
BEGIN
	DROP TABLE ew_ser_rendimientos
END
GO
CREATE TABLE ew_ser_rendimientos (
	idr INT IDENTITY
	, idrendimiento INT NOT NULL
	, codigo VARCHAR(10) NOT NULL
	, nombre VARCHAR(250) NOT NULL DEFAULT ''

	, CONSTRAINT [PK_ew_ser_rendimientos] PRIMARY KEY CLUSTERED (
		[idrendimiento] ASC
	) ON [PRIMARY]
	, CONSTRAINT [UK_ew_ser_rendimientos] UNIQUE (
		[codigo] ASC
	)
) ON [PRIMARY]
GO
INSERT INTO ew_ser_rendimientos (idrendimiento, codigo, nombre) VALUES (1, 'HR', 'Horas de uso')
INSERT INTO ew_ser_rendimientos (idrendimiento, codigo, nombre) VALUES (2, 'KM', 'Kilometros recorridos')
INSERT INTO ew_ser_rendimientos (idrendimiento, codigo, nombre) VALUES (3, 'IMP', 'Impresiones')
INSERT INTO ew_ser_rendimientos (idrendimiento, codigo, nombre) VALUES (4, 'CAP', 'Capturas')
INSERT INTO ew_ser_rendimientos (idrendimiento, codigo, nombre) VALUES (5, 'PZA', 'Unidades producidas')
INSERT INTO ew_ser_rendimientos (idrendimiento, codigo, nombre) VALUES (6, 'BYTE', 'Bytes transferidos')
GO
SELECT * FROM ew_ser_rendimientos
GO
-- #### RENDIMIENTOS DE EQUIPOS
IF OBJECT_ID('ew_ser_equipos_rendimientos') IS NOT NULL
BEGIN
	DROP TABLE ew_ser_equipos_rendimientos
END
GO
CREATE TABLE ew_ser_equipos_rendimientos (
	idr INT
	, idequipo INT NOT NULL
	, idrendimiento INT NOT NULL
	, lectura_inicial NUMERIC(18,6) NOT NULL DEFAULT 0
	, lectura_actual NUMERIC(18,6) NOT NULL DEFAULT 0

	, CONSTRAINT [PK_ew_ser_equipos_rendimientos] PRIMARY KEY CLUSTERED (
		[idequipo] ASC
		,[idrendimiento] ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO
SELECT * FROM ew_ser_equipos_rendimientos
GO
-- #### MEDICION DE RENDIMIENTOS DE EQUIPOS
IF OBJECT_ID('ew_ser_equipos_rendimientos_medicion') IS NOT NULL
BEGIN
	DROP TABLE ew_ser_equipos_rendimientos_medicion
END
GO
CREATE TABLE ew_ser_equipos_rendimientos_medicion (
	idr INT IDENTITY
	, idequipo INT NOT NULL
	, idrendimiento INT NOT NULL
	, rendimiento_esperado NUMERIC(18,6) NOT NULL DEFAULT 0
	, rendimiento_tolerancia NUMERIC(18,6) NOT NULL DEFAULT 0

	, CONSTRAINT [PK_ew_ser_equipos_rendimientos_medicion] PRIMARY KEY CLUSTERED (
		[idequipo] ASC
		,[idrendimiento] ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO
SELECT * FROM ew_ser_equipos_rendimientos_medicion
