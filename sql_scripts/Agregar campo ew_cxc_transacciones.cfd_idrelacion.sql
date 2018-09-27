USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxc_transacciones') AND [name] = 'cfd_idrelacion')
BEGIN
	ALTER TABLE ew_cxc_transacciones ADD cfd_idrelacion INT NOT NULL DEFAULT 0
END
