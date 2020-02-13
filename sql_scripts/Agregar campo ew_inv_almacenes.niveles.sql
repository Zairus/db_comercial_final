USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_inv_almacenes') AND [name] = 'niveles')
BEGIN
	ALTER TABLE ew_inv_almacenes ADD niveles BIT NOT NULL DEFAULT 1
END
