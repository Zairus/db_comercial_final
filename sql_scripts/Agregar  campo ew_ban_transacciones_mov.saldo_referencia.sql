USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ban_transacciones_mov') AND [name] = 'saldo_referencia')
BEGIN
	ALTER TABLE ew_ban_transacciones_mov ADD saldo_referencia DECIMAL(18,6) NOT NULL DEFAULT 0
END