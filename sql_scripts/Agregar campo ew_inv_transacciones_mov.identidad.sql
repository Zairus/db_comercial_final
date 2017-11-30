USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_inv_transacciones_mov') AND [name] = 'identidad')
BEGIN
	ALTER TABLE ew_inv_transacciones_mov ADD identidad INT NOT NULL DEFAULT 0
END
