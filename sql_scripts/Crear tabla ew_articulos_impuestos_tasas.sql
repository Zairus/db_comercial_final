USE db_comercial_final

IF OBJECT_ID('ew_articulos_impuestos_tasas') IS NOT NULL
BEGIN
	DROP TABLE ew_articulos_impuestos_tasas
END

CREATE TABLE ew_articulos_impuestos_tasas (
	idr INT IDENTITY
	,idarticulo INT NOT NULL
	,idimpuesto INT NOT NULL
	,tasa DECIMAL(15,6) NOT NULL
	,CONSTRAINT [PK_ew_articulos_impuestos_tasas] PRIMARY KEY CLUSTERED (
		[idarticulo] ASC
		,[idimpuesto] ASC
		,[tasa] ASC
	)
) ON [PRIMARY]

SELECT * FROM ew_articulos_impuestos_tasas
