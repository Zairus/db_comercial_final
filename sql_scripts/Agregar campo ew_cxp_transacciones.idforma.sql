USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxp_transacciones') AND [name] = 'idforma')
BEGIN
	ALTER TABLE ew_cxp_transacciones ADD idforma INT NOT NULL DEFAULT 0
END