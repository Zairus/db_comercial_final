USE db_comercial_final
GO
IF OBJECT_ID('ew_ven_transacciones_mov_servicio') IS NOT NULL
BEGIN
	DROP TABLE ew_ven_transacciones_mov_servicio
END
GO
CREATE TABLE ew_ven_transacciones_mov_servicio (
	id INT IDENTITY
	, idtran INT
	, idmov MONEY
	, plan_codigo VARCHAR(10) NOT NULL DEFAULT ''
	, ejercicio INT NOT NULL DEFAULT 0
	, periodo INT NOT NULL DEFAULT 0
	, CONSTRAINT [PK_ew_ven_transacciones_mov_servicio] PRIMARY KEY CLUSTERED (
		idtran ASC
		, idmov ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO
SELECT * FROM ew_ven_transacciones_mov_servicio