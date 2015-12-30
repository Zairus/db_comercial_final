USE db_comercial_final

ALTER TABLE ew_ct_cuentas DISABLE TRIGGER tg_ew_ct_cuentas_u

UPDATE ew_ct_cuentas SET
	cuentasup = '2000000000'
WHERE
	cuenta IN ('2110000000','2120000000','2130000000','2140000000')

ALTER TABLE ew_ct_cuentas ENABLE TRIGGER tg_ew_ct_cuentas_u

EXEC _ct_prc_regenerarArbolContable '_GLOBAL'

DECLARE
	@llave AS VARCHAR(1000)

SELECT @llave = llave + '%' FROM ew_ct_cuentas WHERE cuenta = '2000000000'

SELECT * FROM ew_ct_cuentas AS cc WHERE cc.llave LIKE @llave ORDER BY llave
