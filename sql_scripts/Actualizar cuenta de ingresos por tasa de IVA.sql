USE db_comercial_final

UPDATE ew_cat_impuestos_tasas SET
	contabilidad5 = (
		CASE
			WHEN idimpuesto = 1 AND tasa = 0.160000 THEN '4100001000'
			WHEN idimpuesto = 1 AND tasa = 0.080000 THEN '4100005000'
			WHEN idimpuesto = 1 AND tasa = 0.000000 THEN '4100002000'
			ELSE ''
		END
	)

SELECT * FROM ew_cat_impuestos_tasas ORDER BY idimpuesto, tipo, tasa
