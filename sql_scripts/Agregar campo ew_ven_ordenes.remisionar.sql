USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_ordenes') AND [name] = 'remisionar')
BEGIN
	ALTER TABLE ew_ven_ordenes ADD remisionar BIT NOT NULL DEFAULT 0
END