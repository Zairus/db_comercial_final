USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_com_transacciones_mov') AND [name] = 'costo_devolucion')
BEGIN
	ALTER TABLE ew_com_transacciones_mov ADD costo_devolucion DECIMAL(18,6) NOT NULL DEFAULT 0
END
