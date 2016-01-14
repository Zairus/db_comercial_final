USE db_comercial_final

IF OBJECT_ID('ew_cat_unidadesMedida_factores') IS NOT NULL
BEGIN
	DROP TABLE ew_cat_unidadesMedida_factores
END

CREATE TABLE ew_cat_unidadesMedida_factores (
	idr INT IDENTITY
	,idum INT NOT NULL
	,idum2 INT NOT NULL
	,factor DECIMAL(18,6) NOT NULL DEFAULT 0
	,CONSTRAINT PK_ew_cat_unidadesMedida_factores PRIMARY KEY CLUSTERED (
		idum ASC
		,idum2 ASC
	)
) ON [PRIMARY]

SELECT * FROM ew_cat_unidadesMedida_factores
