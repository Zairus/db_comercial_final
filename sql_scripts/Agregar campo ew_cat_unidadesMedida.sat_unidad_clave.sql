USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cat_unidadesMedida') AND [name] = 'sat_unidad_clave')
BEGIN
	ALTER TABLE ew_cat_unidadesMedida ADD sat_unidad_clave VARCHAR(10) NOT NULL DEFAULT ''
END
