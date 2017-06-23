USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ban_transacciones') AND [name] = 'compuesto')
BEGIN
	ALTER TABLE ew_ban_transacciones ADD compuesto BIT NOT NULL DEFAULT 0
END
