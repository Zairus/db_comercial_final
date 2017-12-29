USE db_comercial_final
GO
IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxc_transacciones') AND [name] = 'idmetodo')
BEGIN
	ALTER TABLE ew_cxc_transacciones ADD idmetodo INT NOT NULL DEFAULT 0
END
GO
IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxp_transacciones') AND [name] = 'idmetodo')
BEGIN
	ALTER TABLE ew_cxp_transacciones ADD idmetodo INT NOT NULL DEFAULT 0
END
GO
