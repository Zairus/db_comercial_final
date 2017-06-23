USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ban_transacciones_mov') AND [name] = 'conciliado_id')
BEGIN
	ALTER TABLE ew_ban_transacciones_mov ADD conciliado_id INT NOT NULL DEFAULT 0
END
