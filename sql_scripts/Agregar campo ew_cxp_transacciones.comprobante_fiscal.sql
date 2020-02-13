USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxp_transacciones') AND [name] = 'comprobante_fiscal')
BEGIN
	ALTER TABLE ew_cxp_transacciones ADD comprobante_fiscal BIT NOT NULL DEFAULT 1
END
