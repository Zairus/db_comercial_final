USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_inv_almacenes_tipos') AND name = 'propio')
BEGIN
	ALTER TABLE ew_inv_almacenes_tipos ADD propio BIT NOT NULL DEFAULT 1
END
