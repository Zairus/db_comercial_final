USE db_comercial_final

IF OBJECT_ID('ew_cxc_transacciones_impuestos') IS NOT NULL
BEGIN
	DROP TABLE ew_cxc_transacciones_impuestos
END

CREATE TABLE ew_cxc_transacciones_impuestos (
	idr INT IDENTITY
	,idtran INT
	,idimpuesto INT
	,idtasa INT
	,idmov MONEY
	,consecutivo INT NOT NULL DEFAULT 0
	,tasa DECIMAL(18,6) NOT NULL DEFAULT 0
	,importe DECIMAL(18,6) NOT NULL DEFAULT 0
	,CONSTRAINT [PK_] PRIMARY KEY CLUSTERED (
		idtran ASC
		,idimpuesto ASC
		,idtasa ASC
	)
) ON [PRIMARY]

SELECT * FROM ew_cxc_transacciones_impuestos