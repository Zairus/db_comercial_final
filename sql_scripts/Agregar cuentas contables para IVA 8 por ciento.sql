USE db_comercial_final

-- #### IVA ACREDITABLE 8% PAGADO
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
	[cuenta] = '1150003003'
	, [cuentasup] = '1150003000'
	, [nombre] = 'IVA ACREDITABLE 8% PAGADO'
	, [activo] = 1
	, [tipo] = 1
	, [naturaleza] = 0
	, [ctamayor] = 2
WHERE
	(SELECT COUNT(*) FROM ew_ct_cuentas WHERE cuenta = '1150003003') = 0

-- #### IVA ACREDITABLE 8% NO PAGADO
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
	[cuenta] = '1150004003'
	, [cuentasup] = '1150004000'
	, [nombre] = 'IVA ACREDITABLE 8% NO PAGADO'
	, [activo] = 1
	, [tipo] = 1
	, [naturaleza] = 0
	, [ctamayor] = 2
WHERE
	(SELECT COUNT(*) FROM ew_ct_cuentas WHERE cuenta = '1150004003') = 0

-- #### IVA TRASLADADO 8% COBRADO
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
	[cuenta] = '2130001003'
	, [cuentasup] = '2130001000'
	, [nombre] = 'IVA TRASLADADO 8% COBRADO'
	, [activo] = 1
	, [tipo] = 2
	, [naturaleza] = 1
	, [ctamayor] = 2
WHERE
	(SELECT COUNT(*) FROM ew_ct_cuentas WHERE cuenta = '2130001003') = 0

-- #### IVA TRASLADADO 8% POR COBRAR
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
	[cuenta] = '2130001004'
	, [cuentasup] = '2130001000'
	, [nombre] = 'IVA TRASLADADO 8% POR COBRAR'
	, [activo] = 1
	, [tipo] = 2
	, [naturaleza] = 1
	, [ctamayor] = 2
WHERE
	(SELECT COUNT(*) FROM ew_ct_cuentas WHERE cuenta = '2130001004') = 0

-- #### ACTUALIZAR NOMBRES EXISTENTES
UPDATE ew_ct_cuentas SET nombre = 'IVA ACREDITABLE 16% PAGADO' WHERE cuenta = '1150003001'
UPDATE ew_ct_cuentas SET nombre = 'IVA ACREDITABLE 16% NO PAGADO' WHERE cuenta = '1150004001'
UPDATE ew_ct_cuentas SET nombre = 'IVA TRASLADADO 16% COBRADO' WHERE cuenta = '2130001001'
UPDATE ew_ct_cuentas SET nombre = 'IVA TRASLADADO 16% POR COBRAR' WHERE cuenta = '2130001002'

SELECT * 
FROM 
	ew_ct_cuentas 
WHERE 
	cuenta IN (
		'1150003001' --	1150003000	IVA ACREDITABLE PAGADO
		, '1150003003'
		, '1150004001' --	1150004000	IVA ACREDITABLE NO PAGADO
		, '1150004003'
		, '2130001001' --	2130001000	IVA TRASLADADO COBRADO
		, '2130001002' --	2130001000	IVA TRASLADADO POR COBRAR
		, '2130001003'
		, '2130001004'
	)
ORDER BY
	llave

DECLARE
	@ejercicio AS INT = YEAR(GETDATE())

EXEC _ct_prc_ejercicioInicializar @ejercicio
