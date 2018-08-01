USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxc_transacciones') AND [name] = 'idrelacion')
BEGIN
	ALTER TABLE ew_cxc_transacciones ADD idrelacion INT NOT NULL DEFAULT 0
END