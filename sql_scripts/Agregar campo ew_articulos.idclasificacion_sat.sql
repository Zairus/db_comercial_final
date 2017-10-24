USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_articulos') AND [name] = 'idclasificacion_sat')
BEGIN
	ALTER TABLE ew_articulos ADD idclasificacion_sat INT NOT NULL DEFAULT 0
END
