USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxc_transacciones') AND [name] = 'acumula')
BEGIN
	ALTER TABLE ew_cxc_transacciones ADD acumula BIT NOT NULL DEFAULT 1
END
