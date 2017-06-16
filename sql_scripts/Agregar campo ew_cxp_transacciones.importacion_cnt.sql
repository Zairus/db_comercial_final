USE db_refriequipos_datos

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxp_transacciones') AND [name] = 'importacion_cnt')
BEGIN
	ALTER TABLE ew_cxp_transacciones ADD importacion_cnt DECIMAL(18,6) NOT NULL DEFAULT 0
END
