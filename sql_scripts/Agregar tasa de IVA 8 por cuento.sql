USE db_comercial_final

DECLARE
	@idtasa AS INT

SELECT
	@idtasa = MAX(idtasa)
FROM
	ew_cat_impuestos_tasas

SELECT @idtasa = ISNULL(@idtasa, 0) + 1

INSERT INTO ew_cat_impuestos_tasas (
	idtasa
	, idimpuesto
	, tasa
	, descripcion
	, tipo
	, contabilidad1
	, contabilidad2
	, contabilidad3
	, contabilidad4
	, base_calculo
	, base_idtasa
	, ambito
	, base_proporcion
)

SELECT
	[idtasa] = @idtasa
	, [idimpuesto] = 1
	, [tasa] = 0.080000
	, [descripcion] = 'Tasa 8%'
	, [tipo] = 1
	, [contabilidad1] = '2130001004'
	, [contabilidad2] = '2130001003'
	, [contabilidad3] = '1150004003'
	, [contabilidad4] = '1150003003'
	, [base_calculo] = 0
	, [base_idtasa] = 0
	, [ambito] = 0
	, [base_proporcion] = 0
WHERE
	(
		SELECT
			COUNT(*)
		FROM
			ew_cat_impuestos_tasas AS cit
		WHERE
			cit.idimpuesto = 1
			AND cit.tasa = 0.080000
			AND cit.tipo = 1
	) = 0

SELECT * 
FROM 
	ew_cat_impuestos_tasas AS cit
WHERE 
	cit.idimpuesto = 1
	AND cit.tipo = 1
