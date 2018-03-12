USE db_refriequipos_datos

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ct_impuestos_transacciones') AND [name] = 'idmov2')
BEGIN
	ALTER TABLE ew_ct_impuestos_transacciones ADD idmov2 MONEY
END
