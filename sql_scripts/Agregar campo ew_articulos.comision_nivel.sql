USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_articulos') AND name = 'comision_nivel')
BEGIN
	ALTER TABLE ew_articulos ADD comision_nivel TINYINT NOT NULL DEFAULT 0
END
