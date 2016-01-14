USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_inv_documentos_mov') AND name = 'factor')
BEGIN
	ALTER TABLE ew_inv_documentos_mov ADD factor DECIMAL(18, 6) NOT NULL DEFAULT 1.000000
END
