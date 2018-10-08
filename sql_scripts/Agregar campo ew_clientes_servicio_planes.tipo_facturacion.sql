USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_clientes_servicio_planes') AND [name] = 'tipo_facturacion')
BEGIN
	ALTER TABLE ew_clientes_servicio_planes ADD tipo_facturacion INT NOT NULL DEFAULT 1
END
