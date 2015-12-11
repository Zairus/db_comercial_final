USE db_comercial_final

IF OBJECT_ID('ew_cat_impuestos_tasas') IS NOT NULL
BEGIN
	DROP TABLE ew_cat_impuestos_tasas
END

CREATE TABLE ew_cat_impuestos_tasas (
	idr INT IDENTITY
	,idimpuesto INT NOT NULL
	,tasa DECIMAL(15,6) NOT NULL DEFAULT 0.0
	,descripcion VARCHAR(100) NOT NULL DEFAULT ''
	,CONSTRAINT [PK_ew_cat_impuestos_tasas] PRIMARY KEY CLUSTERED (
		[idimpuesto] ASC
		,[tasa] ASC
	)
) ON [PRIMARY]

SELECT * FROM ew_cat_impuestos_tasas
