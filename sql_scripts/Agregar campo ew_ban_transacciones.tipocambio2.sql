USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ban_transacciones') AND name = 'tipocambio2')
BEGIN
	ALTER TABLE ew_ban_transacciones ADD tipocambio2 DECIMAL(18,6) NOT NULL DEFAULT 0
END