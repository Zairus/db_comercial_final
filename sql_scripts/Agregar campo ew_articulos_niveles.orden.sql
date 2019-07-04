USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_articulos_niveles') AND [name] = 'orden')
BEGIN
	ALTER TABLE ew_articulos_niveles ADD orden INT NOT NULL DEFAULT 0
END
