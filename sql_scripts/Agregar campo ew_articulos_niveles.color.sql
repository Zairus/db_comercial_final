USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_articulos_niveles') AND [name] = 'color')
BEGIN
	ALTER TABLE ew_articulos_niveles ADD color INT NOT NULL DEFAULT 16777215
END
