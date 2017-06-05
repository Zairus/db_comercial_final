USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_com_ordenes') AND name = 'referencia')
BEGIN
	ALTER TABLE ew_com_ordenes ADD referencia VARCHAR(50) NOT NULL DEFAULT ''
END
