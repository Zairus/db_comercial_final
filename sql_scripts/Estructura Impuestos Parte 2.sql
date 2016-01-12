USE db_comercial_final

BEGIN TRAN

/*
#############################
## IMPORTANTE:
#############################

Correr una vez con BEGIN Y ROLLBACK TRAN
Despues correr definitivo

*/

SELECT * 
INTO
	_tmp_cat_impuestos_tasas
FROM 
	ew_cat_impuestos_tasas

DROP TABLE ew_cat_impuestos_tasas

CREATE TABLE ew_cat_impuestos_tasas (
	idr INT IDENTITY
	,idtasa INT DEFAULT -1
	,idimpuesto INT NOT NULL
	,tasa DECIMAL(18,6) NOT NULL DEFAULT 0
	,descripcion VARCHAR(50) NOT NULL DEFAULT ''
	,tipo SMALLINT NOT NULL DEFAULT 1
	,contabilidad1 VARCHAR(50) NOT NULL DEFAULT ''
	,contabilidad2 VARCHAR(50) NOT NULL DEFAULT ''
	,contabilidad3 VARCHAR(50) NOT NULL DEFAULT ''
	,contabilidad4 VARCHAR(50) NOT NULL DEFAULT ''
	,CONSTRAINT PK_ew_cat_impuestos_tasas PRIMARY KEY CLUSTERED (
		idtasa ASC
	)
) ON [PRIMARY]

INSERT INTO ew_cat_impuestos_tasas (
	idtasa
	,idimpuesto
	,tasa
	,descripcion
	,tipo
	,contabilidad1
	,contabilidad2
	,contabilidad3
	,contabilidad4
)
SELECT
	[idtasa] = ROW_NUMBER() OVER (ORDER BY idimpuesto, tasa)
	,idimpuesto
	,tasa
	,descripcion
	,tipo
	,contabilidad1
	,contabilidad2
	,contabilidad3
	,contabilidad4
FROM
	_tmp_cat_impuestos_tasas

SELECT * 
INTO
	_tmp_articulos_impuestos_tasas
FROM 
	ew_articulos_impuestos_tasas

DROP TABLE ew_articulos_impuestos_tasas

CREATE TABLE ew_articulos_impuestos_tasas (
	idr INT IDENTITY
	,idarticulo INT
	,idtasa INT
	,CONSTRAINT PK_ew_articulos_impuestos_tasas PRIMARY KEY CLUSTERED (
		idarticulo ASC
		,idtasa ASC
	)
) ON [PRIMARY]

INSERT INTO ew_articulos_impuestos_tasas (
	idarticulo
	,idtasa
)
SELECT
	tait.idarticulo
	,[idtasa] = (
		SELECT TOP 1
			cit.idtasa
		FROM
			ew_cat_impuestos_tasas AS cit
		WHERE
			cit.idimpuesto = tait.idimpuesto
			AND cit.tasa = tait.tasa
	)
FROM
	_tmp_articulos_impuestos_tasas AS tait
WHERE
	(
		SELECT TOP 1
			cit.idtasa
		FROM
			ew_cat_impuestos_tasas AS cit
		WHERE
			cit.idimpuesto = tait.idimpuesto
			AND cit.tasa = tait.tasa
	) IS NOT NULL

DROP TABLE _tmp_articulos_impuestos_tasas

SELECT * FROM ew_cat_impuestos_tasas
SELECT * FROM ew_articulos_impuestos_tasas

ROLLBACK TRAN