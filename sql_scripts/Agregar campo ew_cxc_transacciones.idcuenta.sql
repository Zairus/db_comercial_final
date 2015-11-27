USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxc_transacciones') AND name = 'idcuenta')
BEGIN
	ALTER TABLE ew_cxc_transacciones ADD idcuenta INT NOT NULL DEFAULT 0
END
