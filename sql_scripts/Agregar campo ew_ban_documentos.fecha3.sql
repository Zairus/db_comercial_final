USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ban_documentos') AND [name] = 'fecha3')
BEGIN
	ALTER TABLE ew_ban_documentos ADD fecha3 DATETIME
END
