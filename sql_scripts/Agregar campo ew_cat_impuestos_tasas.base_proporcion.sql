USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cat_impuestos_tasas') AND [name] = 'base_proporcion')
BEGIN
	ALTER TABLE ew_cat_impuestos_tasas ADD base_proporcion DECIMAL(18,6) NOT NULL DEFAULT 1
END
