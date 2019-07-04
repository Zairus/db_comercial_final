USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_articulos_niveles') AND [name] = 'visible')
BEGIN
	ALTER TABLE ew_articulos_niveles ADD visible BIT NOT NULL DEFAULT 1
END
