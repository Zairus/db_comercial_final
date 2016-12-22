USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_com_transacciones_mov') AND [name] = 'calcular_precios')
BEGIN
	ALTER TABLE ew_com_transacciones_mov ADD calcular_precios BIT NOT NULL DEFAULT 0
END
