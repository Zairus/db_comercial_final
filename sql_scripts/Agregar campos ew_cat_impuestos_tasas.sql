USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cat_impuestos_tasas') AND name = 'tipo')
BEGIN
	ALTER TABLE ew_cat_impuestos_tasas ADD tipo TINYINT NOT NULL DEFAULT 1
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cat_impuestos_tasas') AND name = 'contabilidad1')
BEGIN
	ALTER TABLE ew_cat_impuestos_tasas ADD contabilidad1 VARCHAR(20) NOT NULL DEFAULT ''
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cat_impuestos_tasas') AND name = 'contabilidad2')
BEGIN
	ALTER TABLE ew_cat_impuestos_tasas ADD contabilidad2 VARCHAR(20) NOT NULL DEFAULT ''
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cat_impuestos_tasas') AND name = 'contabilidad3')
BEGIN
	ALTER TABLE ew_cat_impuestos_tasas ADD contabilidad3 VARCHAR(20) NOT NULL DEFAULT ''
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cat_impuestos_tasas') AND name = 'contabilidad4')
BEGIN
	ALTER TABLE ew_cat_impuestos_tasas ADD contabilidad4 VARCHAR(20) NOT NULL DEFAULT ''
END
