USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_inv_documentos') AND [name] = 'parametro')
BEGIN
	ALTER TABLE ew_inv_documentos ADD parametro VARCHAR(20) NOT NULL DEFAULT ''
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_inv_documentos') AND [name] = 'codigo1')
BEGIN
	ALTER TABLE ew_inv_documentos ADD codigo1 VARCHAR(30) NOT NULL DEFAULT ''
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_inv_documentos') AND [name] = 'codigo2')
BEGIN
	ALTER TABLE ew_inv_documentos ADD codigo2 VARCHAR(30) NOT NULL DEFAULT ''
END
