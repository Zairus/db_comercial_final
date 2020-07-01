USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_inv_almacenes') AND [name] = 'permitir_devolucion')
BEGIN
	ALTER TABLE ew_inv_almacenes ADD permitir_devolucion BIT NOT NULL DEFAULT 1
END
