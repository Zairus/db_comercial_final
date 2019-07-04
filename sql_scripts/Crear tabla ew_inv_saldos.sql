USE db_comercial_final
GO
IF OBJECT_ID('ew_inv_saldos') IS NOT NULL
BEGIN
	DROP TABLE ew_inv_saldos
END
GO
CREATE TABLE ew_inv_saldos (
	idr INT IDENTITY
	, idarticulo INT NOT NULL
	, idalmacen INT NOT NULL
	, ejercicio INT NOT NULL
	, periodo INT NOT NULL
	, [existencia_inicial] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [entradas] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [salidas] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [existencia_final] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [costo_inicial] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [cargos] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [abonos] DECIMAL(18,6) NOT NULL DEFAULT 0
	, [costo_final] DECIMAL(18,6) NOT NULL DEFAULT 0

	, CONSTRAINT [PK_ew_inv_saldos] PRIMARY KEY CLUSTERED (
		idarticulo ASC
		, idalmacen ASC
		, ejercicio ASC
		, periodo ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO
SELECT * 
FROM 
	ew_inv_saldos 
ORDER BY 
	idarticulo
	, idalmacen
	, ejercicio
	, periodo
