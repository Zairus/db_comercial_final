USE db_comercial_final

IF OBJECT_ID('ew_ven_comisiones_limites') IS NOT NULL
BEGIN
	DROP TABLE ew_ven_comisiones_limites
END

CREATE TABLE ew_ven_comisiones_limites (
	idr INT IDENTITY
	,nivel SMALLINT NOT NULL DEFAULT 0
	,limite_inferior SMALLINT NOT NULL DEFAULT 0
	,limite_superior SMALLINT NOT NULL DEFAULT 0
	,porcentaje DECIMAL(18,6) NOT NULL DEFAULT 0
	,CONSTRAINT [PK_ew_ven_comisiones_limites] PRIMARY KEY CLUSTERED (
		nivel ASC
		,limite_inferior ASC
	)
) ON [PRIMARY]

SELECT
	nivel
	,limite_inferior
	,limite_superior
	,porcentaje
FROM 
	ew_ven_comisiones_limites
