USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxc_transacciones') AND [name] = 'uuid')
BEGIN
	ALTER TABLE ew_cxc_transacciones ADD uuid VARCHAR(36) NOT NULL DEFAULT ''
END
