USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_com_ordenes_mov') AND [name] = 'consignacion')
BEGIN
	ALTER TABLE ew_com_ordenes_mov ADD consignacion BIT NOT NULL DEFAULT 0
END
