USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_inv_documentos') AND [name] = 'costo')
BEGIN
	ALTER TABLE ew_inv_documentos ADD costo DECIMAL(18,6) NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_inv_documentos') AND [name] = 'gastos')
BEGIN
	ALTER TABLE ew_inv_documentos ADD gastos DECIMAL(18,6) NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_inv_documentos_mov') AND [name] = 'gastos')
BEGIN
	ALTER TABLE ew_inv_documentos_mov ADD gastos DECIMAL(18,6) NOT NULL DEFAULT 0
END