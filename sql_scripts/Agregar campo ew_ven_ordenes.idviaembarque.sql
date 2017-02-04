USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_ordenes') AND [name] = 'idviaembarque')
BEGIN
	ALTER TABLE ew_ven_ordenes ADD idviaembarque INT NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_ordenes') AND [name] = 'no_guia')
BEGIN
	ALTER TABLE ew_ven_ordenes ADD no_guia VARCHAR(200) NOT NULL DEFAULT ''
END