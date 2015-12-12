USE db_comercial_final

IF NOT EXISTS (SELECT * FROM ew_ct_cuentas WHERE cuenta = '1150007001')
BEGIN
	INSERT INTO ew_ct_cuentas (
		cuenta
		,cuentasup
		,nombre
		,activo
		,tipo
		,naturaleza
	)
	VALUES (
		'1150007000'
		,'1150000000'
		,'IEPS A FAVOR'
		,1
		,1
		,0
	)
	,(
		'1150007001'
		,'1150007000'
		,'IEPS Pagado'
		,1
		,1
		,0
	)

	SELECT * FROM ew_ct_cuentas WHERE cuenta LIKE '1150%' ORDER BY llave
END

IF NOT EXISTS (SELECT * FROM ew_ct_cuentas WHERE cuenta = '2130001003')
BEGIN
	INSERT INTO ew_ct_cuentas (
		cuenta
		,cuentasup
		,nombre
		,activo
		,tipo
		,naturaleza
	)
	VALUES (
		'2130001003'
		,'2130001000'
		,'IEPS'
		,1
		,2
		,1
	)

	SELECT * FROM ew_ct_cuentas WHERE cuenta LIKE '2130001%' ORDER BY llave
END
