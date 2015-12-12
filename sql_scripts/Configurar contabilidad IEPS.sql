USE db_comercial_final

UPDATE ew_cat_impuestos SET
	contabilidad = '2130001003'
	,contabilidad2 = '2130001003'
	,contabilidad3 = '1150007001'
	,contabilidad4 = '1150007001'
WHERE
	idimpuesto = 11

SELECT * FROM ew_cat_impuestos
