USE db_comercial_final

IF OBJECT_ID('ew_ven_listaprecios_carga') IS NOT NULL
BEGIN
	DROP TABLE ew_ven_listaprecios_carga
END

CREATE TABLE ew_ven_listaprecios_carga (
	idr INT IDENTITY
	,idsucursal INT NOT NULL
	,codigo VARCHAR(30) NOT NULL
	,nombre VARCHAR(200) NOT NULL
	,nombre_corto VARCHAR(50) NOT NULL DEFAULT ''
	,precio_neto DECIMAL(18,6) NOT NULL
	,costo_base DECIMAL(18,6) NOT NULL
)

SELECT * FROM ew_ven_listaprecios_carga
