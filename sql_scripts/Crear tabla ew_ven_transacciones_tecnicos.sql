USE db_comercial_final
GO
IF OBJECT_ID('ew_ven_transacciones_tecnicos') IS NOT NULL
BEGIN
	DROP TABLE ew_ven_transacciones_tecnicos
END
GO
CREATE TABLE ew_ven_transacciones_tecnicos (
	idr INT IDENTITY
	, idtran INT NOT NULL
	, tipo INT NOT NULL
	, idtecnico INT NOT NULL
	, idmov MONEY

	, CONSTRAINT [PK_ew_ven_transacciones_tecnicos] PRIMARY KEY CLUSTERED (
		idtran ASC
		, tipo ASC
		, idtecnico ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO
