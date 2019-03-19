USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_clientes_servicio_planes') AND [name] = 'costo_especial')
BEGIN
	ALTER TABLE ew_clientes_servicio_planes ADD costo_especial DECIMAL(18,6) NOT NULL DEFAULT 0
END
