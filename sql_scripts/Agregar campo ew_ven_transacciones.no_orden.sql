USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_transacciones') AND name = 'no_orden')
BEGIN
	ALTER TABLE ew_ven_transacciones ADD no_orden VARCHAR(50) NOT NULL DEFAULT ''
END
