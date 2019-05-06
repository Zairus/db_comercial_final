USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ban_documentos') AND [name] = 'fecha2')
BEGIN
	ALTER TABLE ew_ban_documentos ADD fecha2 DATETIME
END
