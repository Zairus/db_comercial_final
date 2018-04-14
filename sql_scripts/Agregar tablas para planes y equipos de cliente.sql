USE db_comercial_final
GO
-- ####### PLANES DE SERVICIO
IF OBJECT_ID('ew_clientes_servicio_planes') IS NOT NULL
BEGIN
	DROP TABLE ew_clientes_servicio_planes
END
GO
CREATE TABLE ew_clientes_servicio_planes (
	idr INT IDENTITY
	, idcliente INT NOT NULL
	, plan_codigo VARCHAR(10) NOT NULL
	, plan_descripcion VARCHAR(500) NOT NULL DEFAULT ''
	, tipo INT NOT NULL DEFAULT 0
	, fecha_inicial DATETIME
	, fecha_final DATETIME
	, costo DECIMAL(18,6) NOT NULL DEFAULT 0
	, periodo INT NOT NULL DEFAULT 1
	, incluido NUMERIC(18,6) NOT NULL DEFAULT 0
	, adicional DECIMAL(18,6) NOT NULL DEFAULT 0
	, comentario TEXT NOT NULL DEFAULT ''

	, CONSTRAINT [PK_ew_clientes_servicio_planes] PRIMARY KEY CLUSTERED (
		[idcliente] ASC
		, [plan_codigo] ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO
SELECT * FROM ew_clientes_servicio_planes
GO
-- ####### EQUIPOS EN PLANES DE SERVICIO
IF OBJECT_ID('ew_clientes_servicio_equipos') IS NOT NULL
BEGIN
	DROP TABLE ew_clientes_servicio_equipos
END
GO
CREATE TABLE ew_clientes_servicio_equipos (
	idr INT IDENTITY
	, idequipo INT NOT NULL
	, idcliente INT NOT NULL
	, plan_codigo VARCHAR(10) NOT NULL

	, idubicacion INT NOT NULL DEFAULT 0
	, idtecnico INT NOT NULL DEFAULT 0
	, idcontacto INT NOT NULL DEFAULT 0

	, referencia VARCHAR(250) NOT NULL DEFAULT ''
	, dia_lectura INT NOT NULL DEFAULT 1
	, dia_servicio INT NOT NULL DEFAULT 1
	, comentario TEXT NOT NULL DEFAULT ''

	, CONSTRAINT [PK_ew_clientes_servicio_equipos] PRIMARY KEY CLUSTERED (
		[idequipo] ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO
SELECT * FROM ew_clientes_servicio_equipos
GO
