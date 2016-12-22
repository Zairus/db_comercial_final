USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_inv_documentos_mov') AND [name] = 'surtido')
BEGIN
	ALTER TABLE ew_inv_documentos_mov ADD surtido DECIMAL(18,6) NOT NULL DEFAULT 0
END
