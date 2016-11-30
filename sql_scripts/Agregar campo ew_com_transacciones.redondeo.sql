USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_com_transacciones') AND name = 'redondeo')
BEGIN
	ALTER TABLE ew_com_transacciones ADD redondeo DECIMAL(18, 6) NOT NULL DEFAULT 0.000000
END
