USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ban_transacciones_mov') AND [name] = 'idtran2')
BEGIN
	ALTER TABLE ew_ban_transacciones_mov ADD idtran2 INT NOT NULL DEFAULT 0
END