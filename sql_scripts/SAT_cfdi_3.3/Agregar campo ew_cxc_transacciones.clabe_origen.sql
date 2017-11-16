USE db_comercial_final
GO
IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxc_transacciones') AND [name] = 'clabe_origen')
BEGIN
	ALTER TABLE ew_cxc_transacciones ADD clabe_origen VARCHAR(18) NOT NULL DEFAULT ''
END
GO
