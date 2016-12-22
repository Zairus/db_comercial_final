USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_inv_documentos') AND [name] = 'entrega_dias')
BEGIN
	ALTER TABLE ew_inv_documentos ADD entrega_dias INT NOT NULL DEFAULT 0
END
