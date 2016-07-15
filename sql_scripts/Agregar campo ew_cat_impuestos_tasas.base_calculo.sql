USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cat_impuestos_tasas') AND name = 'base_calculo')
BEGIN
	ALTER TABLE ew_cat_impuestos_tasas ADD base_calculo SMALLINT NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cat_impuestos_tasas') AND name = 'base_idtasa')
BEGIN
	ALTER TABLE ew_cat_impuestos_tasas ADD base_idtasa INT NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cat_impuestos_tasas') AND name = 'ambito')
BEGIN
	ALTER TABLE ew_cat_impuestos_tasas ADD ambito SMALLINT NOT NULL DEFAULT 0
END
