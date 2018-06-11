USe db_comercial_final

UPDATE ew_ct_cuentas SET ctamayor = 0
UPDATE ew_ct_cuentas SET ctamayor = 3 WHERE nivel = 1
UPDATE ew_ct_cuentas SET ctamayor = 4 WHERE nivel = 2
UPDATE ew_ct_cuentas SET ctamayor = 1 WHERE nivel = 3
UPDATE ew_ct_cuentas SET ctamayor = 2 WHERE nivel >= 4
