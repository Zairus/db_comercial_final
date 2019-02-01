USE db_comercial_final

-- #### VENTAS AL 8%
INSERT INTO ew_ct_cuentas (
	cuenta
	, cuentasup
	, nombre
	, activo
	, tipo
	, naturaleza
	, ctamayor
)

SELECT
	[cuenta] = '4100005000'
	, [cuentasup] = '4100000000'
	, [nombre] = 'VENTAS AL 8%'
	, [activo] = 1
	, [tipo] = 4
	, [naturaleza] = 1
	, [ctamayor] = 2
WHERE
	(SELECT COUNT(*) FROM ew_ct_cuentas WHERE cuenta = '4100005000') = 0

-- #### DESCUENTOS Y DEVOLUCIONES I.V.A. AL 8%
INSERT INTO ew_ct_cuentas (
	cuenta
	, cuentasup
	, nombre
	, activo
	, tipo
	, naturaleza
	, ctamayor
)

SELECT
	[cuenta] = '4200005000'
	, [cuentasup] = '4200000000'
	, [nombre] = 'DESCUENTOS Y DEVOLUCIONES I.V.A. AL 8%'
	, [activo] = 1
	, [tipo] = 4
	, [naturaleza] = 1
	, [ctamayor] = 2
WHERE
	(SELECT COUNT(*) FROM ew_ct_cuentas WHERE cuenta = '4200005000') = 0

SELECT * FROM ew_ct_cuentas WHERE cuenta LIKE '4%' ORDER BY llave

DECLARE
	@ejercicio AS INT = YEAR(GETDATE())

EXEC _ct_prc_ejercicioInicializar @ejercicio
