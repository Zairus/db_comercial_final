USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_inv_documentos') AND [name] = 'idarticulo')
BEGIN
	ALTER TABLE ew_inv_documentos ADD idarticulo INT NOT NULL DEFAULT 0
END
