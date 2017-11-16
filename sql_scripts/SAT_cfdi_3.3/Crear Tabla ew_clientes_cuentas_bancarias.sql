USE db_comercial_final
GO
IF OBJECT_ID('ew_clientes_cuentas_bancarias') IS NOT NULL
BEGIN
	DROP TABLE ew_clientes_cuentas_bancarias
END
GO
CREATE TABLE ew_clientes_cuentas_bancarias (
	idr INT IDENTITY
	,idcliente INT
	,clabe VARCHAR(18)
	,idbanco INT NOT NULL
	,extranjero BIT NOT NULL DEFAULT 0
	,cuenta VARCHAR(50) NOT NULL DEFAULT ''
	,sucursal VARCHAR(10) NOT NULL DEFAULT ''

	,CONSTRAINT [PK_ew_clientes_cuentas_bancarias] PRIMARY KEY CLUSTERED (
		idcliente
		,clabe
	) ON [PRIMARY]
) ON [PRIMARY]
GO
GO
SELECT * FROM ew_clientes_cuentas_bancarias
GO
