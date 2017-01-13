USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_clientes') AND [name] = 'mayoreo')
BEGIN
	ALTER TABLE ew_clientes ADD mayoreo BIT NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_clientes') AND [name] = 'inventario_partes')
BEGIN
	ALTER TABLE ew_clientes ADD inventario_partes BIT NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_clientes') AND [name] = 'inventario_partes_actualizar')
BEGIN
	ALTER TABLE ew_clientes ADD inventario_partes_actualizar BIT NOT NULL DEFAULT 0
END