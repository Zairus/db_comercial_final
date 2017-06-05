USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_documentos') AND name = 'vigencia')
BEGIN
	ALTER TABLE ew_ven_documentos ADD vigencia DATETIME NOT NULL DEFAULT GETDATE()
END
