USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cat_impuestos_tasas') AND [name] = 'contabilidad5')
BEGIN
	ALTER TABLE ew_cat_impuestos_tasas ADD contabilidad5 VARCHAR(50) NOT NULL DEFAULT ''
END
