USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_ordenes_mov') AND [name] = 'actualizar')
BEGIN
	ALTER TABLE ew_ven_ordenes_mov ADD actualizar BIT NOT NULL DEFAULT 0
END