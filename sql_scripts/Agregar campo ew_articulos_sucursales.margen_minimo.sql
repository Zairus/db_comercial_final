USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_articulos_sucursales') AND name = 'margen_minimo')
BEGIN
	ALTER TABLE ew_articulos_sucursales ADD margen_minimo DECIMAL(18,6) NOT NULL DEFAULT 0
END
