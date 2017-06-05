USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxc_transacciones_mov') AND name = 'idmov')
BEGIN
	ALTER TABLE ew_cxc_transacciones_mov ADD idmov MONEY
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxp_transacciones_mov') AND name = 'idmov')
BEGIN
	ALTER TABLE ew_cxp_transacciones_mov ADD idmov MONEY
END
